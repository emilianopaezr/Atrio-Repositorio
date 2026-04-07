import '../../config/supabase/supabase_config.dart';
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

  /// Validates that client-side pricing matches expected calculations
  /// Prevents tampered pricing from being submitted
  static bool validatePricing({
    required double basePrice,
    required double submittedSubtotal,
    required double submittedFee,
    required int units,
    required int guests,
    required bool isPerPerson,
    required double feeRate,
  }) {
    final expectedSub = isPerPerson
        ? basePrice * units * guests
        : basePrice * units;
    final rawFee = expectedSub * feeRate;
    final expectedFee = rawFee > maxFeeCap ? maxFeeCap : rawFee;

    // Allow 1 cent tolerance for floating point
    final subOk = (submittedSubtotal - expectedSub).abs() < 0.02;
    final feeOk = (submittedFee - expectedFee).abs() < 0.02;
    return subOk && feeOk;
  }
}
