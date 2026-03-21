import '../../config/supabase/supabase_config.dart';
import '../models/pricing_result_model.dart';

/// Centralized pricing calculation engine.
/// Server-side via Postgres RPC is the source of truth.
/// Client-side preview is for UI display only.
class PricingEngineService {
  PricingEngineService._();

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
    String pricingModel = 'HOOK_1_PERCENT',
    String? pricingPhase,
  }) {
    final baseTotal = basePrice * nights;
    var hostCommission = baseTotal * hostCommissionRate;

    // Apply $99 cap for flat-fee model
    if (pricingModel == 'FLAT_FEE_CAP' && hostCommission > 99) {
      hostCommission = 99;
    }

    final guestFee = (baseTotal + cleaningFee) * guestFeeRate;
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
}
