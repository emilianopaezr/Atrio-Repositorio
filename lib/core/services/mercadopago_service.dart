import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Mercado Pago Checkout Pro integration.
///
/// Flow:
/// 1. [createPreference] → returns checkout URL
/// 2. Open URL in WebView → user pays
/// 3. WebView intercepts redirect → returns [PaymentResult]
/// 4. [getPaymentStatus] → verify payment server-side
///
/// Security note: For production, move Access Token to server-side
/// (Supabase Edge Function or RPC with pg_net).
class MercadoPagoService {
  static const _baseUrl = 'https://api.mercadopago.com';

  static String get _accessToken =>
      dotenv.env['MP_ACCESS_TOKEN'] ?? '';

  /// Public key (used for client-side tokenization if needed later).
  static String get publicKey =>
      dotenv.env['MP_PUBLIC_KEY'] ?? '';

  static bool get _isSandbox =>
      (dotenv.env['MP_SANDBOX'] ?? 'true').toLowerCase() == 'true';

  static bool get isConfigured => _accessToken.isNotEmpty;

  static bool get isSandbox => _isSandbox;

  // ─── Success/Failure/Pending back URLs ───
  // These are intercepted by the WebView before loading.
  static const _backSuccess = 'https://atrio.app/payment/success';
  static const _backFailure = 'https://atrio.app/payment/failure';
  static const _backPending = 'https://atrio.app/payment/pending';

  /// Back URL patterns for WebView interception.
  static const backUrlPatterns = [
    'atrio.app/payment/success',
    'atrio.app/payment/failure',
    'atrio.app/payment/pending',
  ];

  /// Creates a Checkout Pro preference.
  ///
  /// Returns the checkout URL to open in WebView.
  /// [externalReference] should be the booking ID for webhook matching.
  static Future<MpPreference> createPreference({
    required String title,
    required String description,
    required double amount,
    required String payerEmail,
    required String externalReference,
    String currencyId = 'CLP',
    String? payerName,
  }) async {
    if (!isConfigured) {
      throw MpException('Mercado Pago no está configurado');
    }

    // CLP doesn't support decimals
    final unitPrice = currencyId == 'CLP' ? amount.round() : amount;

    final body = {
      'items': [
        {
          'title': title,
          'description': description,
          'quantity': 1,
          'unit_price': unitPrice,
          'currency_id': currencyId,
        }
      ],
      'payer': {
        'email': payerEmail,
        'name': ?payerName,
      },
      'back_urls': {
        'success': _backSuccess,
        'failure': _backFailure,
        'pending': _backPending,
      },
      'auto_return': 'approved',
      'external_reference': externalReference,
      'statement_descriptor': 'ATRIO',
      'expires': true,
      'expiration_date_to': DateTime.now()
          .add(const Duration(hours: 2))
          .toUtc()
          .toIso8601String(),
    };

    debugPrint('[MP] Creating preference for $externalReference ...');

    final response = await http.post(
      Uri.parse('$_baseUrl/checkout/preferences'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final initPoint = _isSandbox
          ? (data['sandbox_init_point'] as String? ?? data['init_point'] as String)
          : data['init_point'] as String;

      debugPrint('[MP] Preference created: ${data['id']}');
      debugPrint('[MP] Checkout URL: $initPoint');

      return MpPreference(
        id: data['id'] as String,
        initPoint: initPoint,
        sandboxInitPoint: data['sandbox_init_point'] as String?,
      );
    } else {
      debugPrint('[MP] Error ${response.statusCode}: ${response.body}');
      throw MpException(
        'Error al crear el pago: ${response.statusCode}',
        details: response.body,
      );
    }
  }

  /// Checks the status of a payment by its ID.
  ///
  /// Used after WebView redirect to verify payment server-side.
  static Future<MpPaymentStatus> getPaymentStatus(String paymentId) async {
    if (!isConfigured) {
      throw MpException('Mercado Pago no está configurado');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/v1/payments/$paymentId'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MpPaymentStatus.fromJson(data);
    } else {
      throw MpException(
        'Error al verificar el pago',
        details: response.body,
      );
    }
  }

  /// Searches for payments by external reference (booking ID).
  ///
  /// Useful when the user returns to the app without redirect params.
  static Future<MpPaymentStatus?> findPaymentByReference(
      String externalReference) async {
    if (!isConfigured) return null;

    final response = await http.get(
      Uri.parse(
          '$_baseUrl/v1/payments/search?external_reference=$externalReference&sort=date_created&criteria=desc'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results != null && results.isNotEmpty) {
        return MpPaymentStatus.fromJson(
            results.first as Map<String, dynamic>);
      }
    }
    return null;
  }
}

// ─── Models ───

class MpPreference {
  final String id;
  final String initPoint;
  final String? sandboxInitPoint;

  const MpPreference({
    required this.id,
    required this.initPoint,
    this.sandboxInitPoint,
  });
}

class MpPaymentStatus {
  final String id;
  final String status;
  final String? statusDetail;
  final String? externalReference;
  final double transactionAmount;
  final String? currencyId;
  final String? payerEmail;
  final String? dateApproved;
  final String? paymentMethodId;
  final String? paymentTypeId;

  const MpPaymentStatus({
    required this.id,
    required this.status,
    this.statusDetail,
    this.externalReference,
    required this.transactionAmount,
    this.currencyId,
    this.payerEmail,
    this.dateApproved,
    this.paymentMethodId,
    this.paymentTypeId,
  });

  factory MpPaymentStatus.fromJson(Map<String, dynamic> json) {
    return MpPaymentStatus(
      id: json['id'].toString(),
      status: json['status'] as String? ?? 'unknown',
      statusDetail: json['status_detail'] as String?,
      externalReference: json['external_reference'] as String?,
      transactionAmount:
          (json['transaction_amount'] as num?)?.toDouble() ?? 0,
      currencyId: json['currency_id'] as String?,
      payerEmail: (json['payer'] as Map<String, dynamic>?)?['email'] as String?,
      dateApproved: json['date_approved'] as String?,
      paymentMethodId: json['payment_method_id'] as String?,
      paymentTypeId: json['payment_type_id'] as String?,
    );
  }

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'in_process' || status == 'pending';

  /// User-friendly status label in Spanish.
  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazado';
      case 'in_process':
        return 'En proceso';
      case 'pending':
        return 'Pendiente';
      case 'cancelled':
        return 'Cancelado';
      case 'refunded':
        return 'Reembolsado';
      default:
        return 'Desconocido';
    }
  }

  /// User-friendly rejection reason.
  String? get rejectionReason {
    switch (statusDetail) {
      case 'cc_rejected_insufficient_amount':
        return 'Fondos insuficientes';
      case 'cc_rejected_bad_filled_card_number':
        return 'Numero de tarjeta incorrecto';
      case 'cc_rejected_bad_filled_date':
        return 'Fecha de vencimiento incorrecta';
      case 'cc_rejected_bad_filled_security_code':
        return 'Codigo de seguridad incorrecto';
      case 'cc_rejected_bad_filled_other':
        return 'Datos de tarjeta incorrectos';
      case 'cc_rejected_call_for_authorize':
        return 'Debes autorizar el pago con tu banco';
      case 'cc_rejected_card_disabled':
        return 'Tarjeta deshabilitada';
      case 'cc_rejected_max_attempts':
        return 'Demasiados intentos, intenta mas tarde';
      case 'cc_rejected_duplicated_payment':
        return 'Pago duplicado';
      case 'cc_rejected_high_risk':
        return 'Pago rechazado por seguridad';
      default:
        return statusDetail;
    }
  }
}

class MpException implements Exception {
  final String message;
  final String? details;

  const MpException(this.message, {this.details});

  @override
  String toString() => message;
}

/// Result returned from the payment WebView.
class PaymentResult {
  final String status; // approved, rejected, pending
  final String? paymentId;
  final String? externalReference;
  final String? merchantOrderId;

  const PaymentResult({
    required this.status,
    this.paymentId,
    this.externalReference,
    this.merchantOrderId,
  });

  bool get isApproved => status == 'approved';
  bool get isRejected =>
      status == 'rejected' || status == 'failure';
  bool get isPending => status == 'pending' || status == 'in_process';
  bool get isCancelled => status == 'cancelled';

  /// Parse from Mercado Pago redirect URL query parameters.
  factory PaymentResult.fromUrl(String url) {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    String status;
    if (url.contains('/success')) {
      status = 'approved';
    } else if (url.contains('/failure')) {
      status = 'rejected';
    } else if (url.contains('/pending')) {
      status = 'pending';
    } else {
      status = params['status'] ?? params['collection_status'] ?? 'unknown';
    }

    return PaymentResult(
      status: status,
      paymentId: params['payment_id'] ?? params['collection_id'],
      externalReference: params['external_reference'],
      merchantOrderId: params['merchant_order_id'],
    );
  }
}
