import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase/supabase_config.dart';
import '../models/pricing_result_model.dart';
import '../services/pricing_engine_service.dart';

/// Request object for pricing calculation (used as family key)
class PricingRequest {
  final String listingId;
  final String guestId;
  final String hostId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestsCount;

  const PricingRequest({
    required this.listingId,
    required this.guestId,
    required this.hostId,
    required this.checkIn,
    required this.checkOut,
    this.guestsCount = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricingRequest &&
          listingId == other.listingId &&
          guestId == other.guestId &&
          hostId == other.hostId &&
          checkIn == other.checkIn &&
          checkOut == other.checkOut &&
          guestsCount == other.guestsCount;

  @override
  int get hashCode => Object.hash(listingId, guestId, hostId, checkIn, checkOut, guestsCount);
}

/// Server-side pricing calculation provider
final pricingPreviewProvider = FutureProvider.family<PricingResult, PricingRequest>(
  (ref, request) async {
    return PricingEngineService.calculatePricing(
      listingId: request.listingId,
      guestId: request.guestId,
      hostId: request.hostId,
      checkIn: request.checkIn,
      checkOut: request.checkOut,
      guestsCount: request.guestsCount,
    );
  },
);

/// Pricing config provider (reads all config from DB)
final pricingConfigProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async {
    final response = await SupabaseConfig.client
        .from('pricing_config')
        .select('key, value')
        .eq('is_active', true);

    final config = <String, dynamic>{};
    for (final row in response) {
      config[row['key'] as String] = row['value'];
    }
    return config;
  },
);
