import 'package:atrio/core/services/pricing_engine_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [PricingEngineService] — the math that determines what a
/// guest pays and what a host earns. Errors here cost money.
///
/// Server-side Postgres RPC is the source of truth in production; these
/// tests cover the client-side preview that the UI shows during checkout
/// before the server call lands.
void main() {
  group('getEffectiveFeeRate', () {
    test('uses promo rate for hosts with fewer than 5 completed bookings',
        () {
      expect(PricingEngineService.getEffectiveFeeRate(0), 0.01);
      expect(PricingEngineService.getEffectiveFeeRate(1), 0.01);
      expect(PricingEngineService.getEffectiveFeeRate(4), 0.01);
    });

    test('uses standard rate from the 5th booking onward', () {
      expect(PricingEngineService.getEffectiveFeeRate(5), 0.07);
      expect(PricingEngineService.getEffectiveFeeRate(50), 0.07);
    });
  });

  group('calculateServiceFee', () {
    test('returns simple percentage when below the cap', () {
      // 50.000 * 7% = 3.500
      expect(PricingEngineService.calculateServiceFee(50000), closeTo(3500, 0.01));
      // 100.000 * 7% = 7.000
      expect(PricingEngineService.calculateServiceFee(100000), closeTo(7000, 0.01));
    });

    test('caps the fee at 90.000 CLP when 7% would exceed it', () {
      // 2.000.000 * 7% = 140.000 → capped to 90.000
      expect(PricingEngineService.calculateServiceFee(2000000), 90000);
      // Just over the cap: 1.300.000 * 7% = 91.000 → capped
      expect(PricingEngineService.calculateServiceFee(1300000), 90000);
    });

    test('respects a custom rate', () {
      expect(
        PricingEngineService.calculateServiceFee(100000, rate: 0.01),
        closeTo(1000, 0.01),
      );
    });
  });

  group('previewPricing — promo host (1% commission)', () {
    test('1 night, no cleaning', () {
      final r = PricingEngineService.previewPricing(
        basePrice: 50000,
        cleaningFee: 0,
        nights: 1,
        hostCommissionRate: 0.01,
      );
      expect(r.baseTotal, 50000);
      expect(r.hostCommissionAmount, 500);
      // service fee: 50.000 * 7% = 3.500
      expect(r.guestServiceFeeAmount, closeTo(3500, 0.01));
      // total guest pays
      expect(r.total, 53500);
      // host net: 50.000 - 500 = 49.500
      expect(r.hostPayoutAmount, 49500);
      // platform: 500 + 3.500
      expect(r.platformRevenue, closeTo(4000, 0.01));
    });

    test('3 nights with cleaning fee, fee under cap', () {
      final r = PricingEngineService.previewPricing(
        basePrice: 80000,
        cleaningFee: 20000,
        nights: 3,
        hostCommissionRate: 0.01,
      );
      // 3 nights * 80k = 240k
      expect(r.baseTotal, 240000);
      // 1% of 240k = 2.400
      expect(r.hostCommissionAmount, closeTo(2400, 0.01));
      // service fee over (base + cleaning) = (240k + 20k) * 7% = 18.200
      expect(r.guestServiceFeeAmount, closeTo(18200, 0.01));
      // total = 240k + 20k + 18.2k = 278.200
      expect(r.total, closeTo(278200, 0.01));
      // host payout: base + cleaning - commission = 240k + 20k - 2.4k
      expect(r.hostPayoutAmount, closeTo(257600, 0.01));
    });
  });

  group('previewPricing — standard host (7% commission)', () {
    test('hits commission cap on expensive bookings', () {
      final r = PricingEngineService.previewPricing(
        basePrice: 1500000,
        cleaningFee: 0,
        nights: 1,
        hostCommissionRate: 0.07,
      );
      // 7% of 1.5M = 105k → capped at 90k
      expect(r.hostCommissionAmount, 90000);
      // guest fee: 7% of 1.5M = 105k → capped at 90k
      expect(r.guestServiceFeeAmount, 90000);
      // total = 1.5M + 90k
      expect(r.total, 1590000);
      // host payout = 1.5M - 90k
      expect(r.hostPayoutAmount, 1410000);
    });

    test('does NOT cap when total is below threshold', () {
      final r = PricingEngineService.previewPricing(
        basePrice: 1000000,
        cleaningFee: 0,
        nights: 1,
        hostCommissionRate: 0.07,
      );
      // 7% of 1M = 70k (under 90k cap)
      expect(r.hostCommissionAmount, 70000);
      expect(r.guestServiceFeeAmount, 70000);
    });
  });

  group('previewPricing — guest fee includes cleaning in calculation', () {
    test('cleaning fee is included in the service-fee base', () {
      final r = PricingEngineService.previewPricing(
        basePrice: 100000,
        cleaningFee: 50000,
        nights: 1,
        hostCommissionRate: 0.01,
      );
      // service fee over (100k + 50k) * 7% = 10.500
      expect(r.guestServiceFeeAmount, closeTo(10500, 0.01));
    });
  });

  group('previewPricing — edge cases', () {
    test('zero nights still produces a valid result', () {
      final r = PricingEngineService.previewPricing(
        basePrice: 50000,
        cleaningFee: 0,
        nights: 0,
        hostCommissionRate: 0.01,
      );
      expect(r.baseTotal, 0);
      expect(r.total, 0);
      expect(r.hostPayoutAmount, 0);
    });

    test('a guest never pays more than (base + cleaning + cap)', () {
      // Worst case: huge base, no cleaning, both fees capped
      final r = PricingEngineService.previewPricing(
        basePrice: 10000000,
        cleaningFee: 0,
        nights: 1,
        hostCommissionRate: 0.07,
      );
      // Total = 10M + 90k cap
      expect(r.total, 10090000);
    });
  });
}
