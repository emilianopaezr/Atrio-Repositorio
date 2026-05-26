import '../../config/supabase/supabase_config.dart';
import '../models/atrio_pricing_result.dart';
import '../models/pricing_result_model.dart';

/// Centralized pricing calculation engine.
/// Server-side via Postgres RPC is the source of truth.
/// Client-side preview is for UI display only.
///
/// Commission model:
///   - Standard guest service fee: 7% of subtotal
///   - Cap: if 7% exceeds $90.000 CLP, charge max $90.000 CLP
///   - Host commission: 1% (early adopter) or progressive
class PricingEngineService {
  PricingEngineService._();

  // ────────────────────────────────────────────────────────────
  // Servicio Atrio (new pricing model — single source of truth)
  // 5% initial (first 5 paid+confirmed+non-refunded for verified
  // hosts) or 9% normal, floored at $1.490 CLP. Customer pays
  // base + servicio_atrio. Host always receives full base.
  // ────────────────────────────────────────────────────────────

  /// Calls the `calculate_atrio_pricing` RPC to obtain the canonical
  /// pricing breakdown for a listing. All amounts come from the
  /// server — the client never decides them.
  ///
  /// Throws if the RPC call fails or returns an unexpected shape.
  static Future<AtrioPricingResult> calculateAtrioPricing({
    required String hostId,
    required int basePrice,
    int units = 1,
  }) async {
    final response = await SupabaseConfig.client.rpc(
      'calculate_atrio_pricing',
      params: {
        'p_host_id': hostId,
        'p_precio_base': basePrice,
        'p_units': units,
      },
    );

    if (response is Map<String, dynamic>) {
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }
      return AtrioPricingResult.fromJson(response);
    }
    throw Exception('calculate_atrio_pricing: invalid response shape');
  }

  /// Standard commission rate
  static const double standardFeeRate = 0.07;

  /// Promotional commission rate (first 5 bookings per host)
  static const double promoFeeRate = 0.01;

  /// Number of bookings that qualify for promotional rate
  static const int promoBookingThreshold = 5;

  /// Maximum commission cap in CLP
  static const double maxFeeCap = 90000.0;

  /// Get the effective fee rate based on host's booking count
  static double getEffectiveFeeRate(int hostBookingsCount) {
    return hostBookingsCount < promoBookingThreshold
        ? promoFeeRate
        : standardFeeRate;
  }

  /// Calculate the capped service fee
  static double calculateServiceFee(double subtotal, {double rate = 0.07}) {
    final fee = subtotal * rate;
    return fee > maxFeeCap ? maxFeeCap : fee;
  }

  /// Calculate pricing via server-side Postgres function (source of truth)
  static Future<PricingResult> calculatePricing({
    required String listingId,
    required String guestId,
    required String hostId,
    required DateTime checkIn,
    required DateTime checkOut,
    int guestsCount = 1,
  }) async {
    final response = await SupabaseConfig.client.rpc(
      'calculate_booking_pricing',
      params: {
        'p_listing_id': listingId,
        'p_guest_id': guestId,
        'p_host_id': hostId,
        'p_check_in': checkIn.toIso8601String().split('T')[0],
        'p_check_out': checkOut.toIso8601String().split('T')[0],
        'p_guests_count': guestsCount,
      },
    );

    if (response is Map<String, dynamic>) {
      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }
      return PricingResult.fromJson(response);
    }

    throw Exception('Invalid pricing response');
  }

  /// Client-side preview for quick UI display (not for persistence)
  static PricingResult previewPricing({
    required double basePrice,
    required double cleaningFee,
    required int nights,
    double hostCommissionRate = 0.01,
    double guestFeeRate = 0.07,
    String pricingModel = 'STANDARD_7_CAP99',
    String? pricingPhase,
  }) {
    final baseTotal = basePrice * nights;
    var hostCommission = baseTotal * hostCommissionRate;

    // Apply cap for flat-fee model
    if (hostCommission > maxFeeCap) {
      hostCommission = maxFeeCap;
    }

    // Guest service fee: 7% capped at $90.000 CLP
    final subtotalForFee = baseTotal + cleaningFee;
    final rawGuestFee = subtotalForFee * guestFeeRate;
    final guestFee = rawGuestFee > maxFeeCap ? maxFeeCap : rawGuestFee;

    final hostPayout = baseTotal + cleaningFee - hostCommission;
    final platformRevenue = hostCommission + guestFee;
    final total = baseTotal + cleaningFee + guestFee;

    return PricingResult(
      pricingModel: pricingModel,
      pricingPhase: pricingPhase,
      nights: nights,
      baseTotal: baseTotal,
      cleaningFee: cleaningFee,
      hostCommissionRate: hostCommissionRate,
      guestServiceFeeRate: guestFeeRate,
      hostCommissionAmount: hostCommission,
      guestServiceFeeAmount: guestFee,
      platformRevenue: platformRevenue,
      hostPayoutAmount: hostPayout,
      total: total,
      basePrice: basePrice,
    );
  }

  /// Validates that client-side pricing matches expected calculations.
  /// Prevents tampered pricing from being submitted.
  ///
  /// Service fee is computed over `subtotal + cleaningFee` to stay
  /// consistent with [previewPricing] and [calculateServiceFee] callers
  /// that pre-add cleaning. Without this, any listing with a non-zero
  /// `cleaning_fee` (e.g. Loft Industrial) failed validation with
  /// "Error en el cálculo".
  static bool validatePricing({
    required double basePrice,
    required double submittedSubtotal,
    required double submittedFee,
    required int units,
    required int guests,
    required bool isPerPerson,
    required double feeRate,
    double cleaningFee = 0,
  }) {
    final expectedSub = isPerPerson
        ? basePrice * units * guests
        : basePrice * units;
    final rawFee = (expectedSub + cleaningFee) * feeRate;
    final expectedFee = rawFee > maxFeeCap ? maxFeeCap : rawFee;

    // Allow 1 cent tolerance for floating point.
    final subOk = (submittedSubtotal - expectedSub).abs() < 0.02;
    final feeOk = (submittedFee - expectedFee).abs() < 0.02;
    return subOk && feeOk;
  }
}
