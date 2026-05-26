import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../config/supabase/supabase_config.dart';
import '../utils/app_logger.dart';

/// Mercado Pago integration — uses **Checkout API** (custom card form), NOT
/// Checkout Pro WebView.
///
/// Why Checkout API instead of Checkout Pro:
///   The MP sandbox issued by their developer panel only exposes a LIVE
///   public key. Checkout Pro WebView tokenizes the card client-side using
///   that public key — generating `live_mode: true` tokens — but the access
///   token is `TEST-` (sandbox), which produces a `live_mode` mismatch and
///   silently rejects every test payment with "Algo salió mal... usa otro
///   medio de pago".
///
///   Checkout API fixes this by tokenizing **server-side** using the access
///   token's auth context. Same token used for tokenization and payment →
///   no mismatch, sandbox payments approve, production payments approve.
///
/// Flow:
///   ┌──────────────┐   POST /functions/v1/mp-create-payment
///   │  Atrio app   │  { bookingId, card, identification, installments }
///   └──────┬───────┘
///          │  HTTPS + JWT
///          ▼
///   ┌──────────────────────────────────────┐
///   │  Edge Function mp-create-payment     │
///   │   1. Verifies guest's JWT            │
///   │   2. Loads booking (service role)    │
///   │   3. Tokenizes card with TEST-/      │
///   │      APP_USR- access token           │
///   │   4. Creates payment via /v1/payments│
///   │   5. Updates bookings.payment_status │
///   └──────┬───────────────────────────────┘
///          │
///          ▼
///   { status: "approved" | "rejected" | "pending", payment_id, ... }
class MercadoPagoService {
  static String get _createPaymentUrl =>
      dotenv.env['MP_CREATE_PAYMENT_URL'] ?? '';

  static bool get _isSandbox =>
      (dotenv.env['MP_SANDBOX'] ?? 'true').toLowerCase() == 'true';

  /// True when the create-payment endpoint is configured.
  static bool get isConfigured => _createPaymentUrl.isNotEmpty;

  static bool get isSandbox => _isSandbox;

  /// Submits a card payment for [bookingId] via the Edge Function.
  ///
  /// The card data flows to our backend over HTTPS, gets immediately
  /// tokenized at MP, and the raw data is discarded. Nothing is stored.
  /// This keeps the merchant in PCI-DSS SAQ-A scope (lowest tier).
  static Future<PaymentResult> payWithCard({
    required String bookingId,
    required String cardNumber,
    required String cardHolderName,
    required int expirationMonth,
    required int expirationYear,
    required String cvv,
    required String identificationType, // "RUT" in CL
    required String identificationNumber,
    int installments = 1,
  }) async {
    if (!isConfigured) {
      throw const MpException('Mercado Pago no está configurado');
    }
    final session = SupabaseConfig.auth.currentSession;
    if (session == null) {
      throw const MpException('Sesión expirada, inicia sesión de nuevo');
    }

    final body = jsonEncode({
      'bookingId': bookingId,
      'card': {
        'number': cardNumber.replaceAll(' ', ''),
        'holder': cardHolderName,
        'expMonth': expirationMonth,
        'expYear': expirationYear,
        'cvv': cvv,
      },
      'identification': {
        'type': identificationType,
        'number': identificationNumber,
      },
      'installments': installments,
    });

    AppLogger.i('submitting payment',
        tag: 'mp', data: {'booking_id': bookingId});

    final response = await http.post(
      Uri.parse(_createPaymentUrl),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
        'apikey': dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'unknown';
      AppLogger.i('payment $status',
          tag: 'mp',
          data: {'payment_id': data['payment_id'], 'status': status});
      return PaymentResult(
        status: status,
        paymentId: (data['payment_id'] as String?) ?? '',
        statusDetail: data['status_detail'] as String?,
        externalReference: bookingId,
      );
    }

    // Body may contain card error_detail — keep it in a breadcrumb (debug
    // log + Sentry breadcrumb), NOT a captured event, so users see context
    // but we don't fire a Sentry alert for declined cards.
    AppLogger.w('payment error ${response.statusCode}: ${response.body}',
        tag: 'mp');
    String message;
    try {
      final j = jsonDecode(response.body) as Map<String, dynamic>;
      message = (j['error'] as String?) ?? 'Error al procesar el pago';
    } catch (_) {
      message = 'Error al procesar el pago (${response.statusCode})';
    }
    throw MpException(message, details: response.body);
  }

  /// Reads the latest payment status from the bookings table.
  /// Webhook keeps it fresh, so this is the canonical source of truth.
  static Future<MpPaymentStatus?> getBookingPaymentStatus(
      String bookingId) async {
    final row = await SupabaseConfig.client
        .from('bookings')
        .select('id, payment_status, mp_payment_id, total')
        .eq('id', bookingId)
        .maybeSingle();
    if (row == null) return null;
    final status = (row['payment_status'] as String?) ?? 'pending';
    return MpPaymentStatus(
      id: (row['mp_payment_id'] as String?) ?? '',
      status: switch (status) {
        'paid' => 'approved',
        'failed' => 'rejected',
        'refunded' => 'refunded',
        _ => 'pending',
      },
      externalReference: row['id'] as String?,
      transactionAmount: (row['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Models ───

/// Result of a payment attempt via Checkout API.
class PaymentResult {
  final String status; // approved, rejected, in_process, pending, cancelled
  final String? paymentId;
  final String? statusDetail;
  final String? externalReference;

  const PaymentResult({
    required this.status,
    this.paymentId,
    this.statusDetail,
    this.externalReference,
  });

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected' || status == 'cancelled';
  bool get isPending => status == 'in_process' || status == 'pending';
  bool get isCancelled => status == 'cancelled';

  /// User-friendly Spanish reason when the payment was rejected.
  String get userMessage {
    switch (statusDetail) {
      case 'cc_rejected_insufficient_amount':
        return 'Fondos insuficientes en la tarjeta';
      case 'cc_rejected_bad_filled_card_number':
        return 'Número de tarjeta incorrecto';
      case 'cc_rejected_bad_filled_date':
        return 'Fecha de vencimiento incorrecta';
      case 'cc_rejected_bad_filled_security_code':
        return 'Código de seguridad incorrecto';
      case 'cc_rejected_bad_filled_other':
        return 'Datos de tarjeta incorrectos';
      case 'cc_rejected_call_for_authorize':
        return 'Tu banco requiere que autorices el pago';
      case 'cc_rejected_card_disabled':
        return 'Tarjeta deshabilitada';
      case 'cc_rejected_max_attempts':
        return 'Demasiados intentos, intenta más tarde';
      case 'cc_rejected_duplicated_payment':
        return 'Pago duplicado';
      case 'cc_rejected_high_risk':
        return 'Pago rechazado por seguridad';
      case 'accredited':
        return 'Pago aprobado';
      default:
        return statusDetail ?? 'Error procesando el pago';
    }
  }
}

class MpPaymentStatus {
  final String id;
  final String status;
  final String? externalReference;
  final double transactionAmount;

  const MpPaymentStatus({
    required this.id,
    required this.status,
    this.externalReference,
    required this.transactionAmount,
  });

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'in_process' || status == 'pending';
}

class MpException implements Exception {
  final String message;
  final String? details;

  const MpException(this.message, {this.details});

  @override
  String toString() => message;
}
