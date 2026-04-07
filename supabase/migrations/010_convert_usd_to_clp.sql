-- ============================================
-- ATRIO - Convert all prices from USD to CLP
-- Run this in the Supabase SQL Editor
-- ============================================

-- 1. Update all listings: convert USD prices to CLP
UPDATE listings
SET
  base_price = CASE
    WHEN base_price = 150.00 THEN 120000
    WHEN base_price = 450.00 THEN 350000
    WHEN base_price = 85.00 THEN CASE WHEN price_unit = 'night' THEN 75000 ELSE 65000 END
    WHEN base_price = 200.00 THEN 150000
    WHEN base_price = 800.00 THEN 650000
    WHEN base_price = 65.00 THEN 55000
    WHEN base_price = 35.00 THEN CASE WHEN price_unit = 'hour' THEN 30000 ELSE 35000 END
    WHEN base_price = 120.00 THEN 95000
    WHEN base_price = 45.00 THEN 35000
    WHEN base_price = 40.00 THEN 35000
    ELSE base_price * 850  -- fallback conversion for any other USD prices
  END,
  cleaning_fee = CASE
    WHEN cleaning_fee = 25.00 THEN 20000
    WHEN cleaning_fee = 80.00 THEN 60000
    WHEN cleaning_fee = 50.00 THEN 40000
    WHEN cleaning_fee = 150.00 THEN 120000
    WHEN cleaning_fee = 10.00 THEN 8000
    ELSE cleaning_fee * 850
  END,
  currency = 'CLP'
WHERE currency = 'USD';

-- 2. Update schema default for new listings
ALTER TABLE listings ALTER COLUMN currency SET DEFAULT 'CLP';

-- 3. Update transactions table default
ALTER TABLE transactions ALTER COLUMN currency SET DEFAULT 'CLP';

-- 4. Update existing bookings with USD amounts
UPDATE bookings
SET
  base_total = base_total * 850,
  cleaning_fee = cleaning_fee * 850,
  service_fee = service_fee * 850,
  total = total * 850
WHERE total < 10000;  -- Only convert if values look like USD (< $10,000)

-- 5. Update pricing config
UPDATE pricing_config SET value = '90000', description = 'Flat-fee model: max commission CLP'
WHERE key = 'flat_fee_cap_amount';

UPDATE pricing_config SET value = '400000', description = 'Flat-fee model: min booking total CLP to trigger'
WHERE key = 'flat_fee_min_booking_amount';

-- 6. Update the calculate_booking_pricing function cap
CREATE OR REPLACE FUNCTION calculate_booking_pricing(
  p_listing_id UUID,
  p_guest_id UUID,
  p_host_id UUID,
  p_check_in TIMESTAMPTZ,
  p_check_out TIMESTAMPTZ,
  p_guests_count INTEGER DEFAULT 1
)
RETURNS JSONB AS $$
DECLARE
  v_listing RECORD;
  v_host_stats RECORD;
  v_pricing_config RECORD;
  v_nights INTEGER;
  v_base_total DECIMAL(12,2);
  v_cleaning_fee DECIMAL(12,2);
  v_pricing_model TEXT;
  v_pricing_phase TEXT;
  v_host_commission_rate DECIMAL(5,4);
  v_guest_fee_rate DECIMAL(5,4);
  v_host_commission DECIMAL(12,2);
  v_guest_fee DECIMAL(12,2);
  v_host_payout DECIMAL(12,2);
  v_platform_revenue DECIMAL(12,2);
  v_total DECIMAL(12,2);
  v_hook_eligible BOOLEAN := FALSE;
  v_platform_age_months INTEGER;
BEGIN
  SELECT * INTO v_listing FROM listings WHERE id = p_listing_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Listing not found';
  END IF;

  SELECT * INTO v_host_stats FROM host_stats WHERE host_id = p_host_id;

  v_nights := GREATEST(1, EXTRACT(DAY FROM p_check_out - p_check_in)::INTEGER);

  IF v_listing.price_unit = 'night' THEN
    v_base_total := v_listing.base_price * v_nights;
  ELSIF v_listing.price_unit = 'person' THEN
    v_base_total := v_listing.base_price * p_guests_count;
  ELSE
    v_base_total := v_listing.base_price;
  END IF;

  v_cleaning_fee := COALESCE(v_listing.cleaning_fee, 0);

  SELECT EXTRACT(MONTH FROM AGE(NOW(),
    (SELECT value::TIMESTAMPTZ FROM pricing_config WHERE key = 'platform_launch_date')
  ))::INTEGER INTO v_platform_age_months;

  IF v_platform_age_months < 6 THEN
    v_hook_eligible := TRUE;
  ELSIF COALESCE(v_host_stats.completed_bookings_count, 0) <= 5 THEN
    v_hook_eligible := TRUE;
  END IF;

  IF v_hook_eligible THEN
    v_pricing_model := 'HOOK_1_PERCENT';
    v_pricing_phase := NULL;
    v_host_commission_rate := 0.01;
    v_guest_fee_rate := 0.07;
  ELSIF v_base_total > 400000 OR v_nights > 7 THEN
    v_pricing_model := 'FLAT_FEE_CAP';
    v_pricing_phase := NULL;
    v_host_commission_rate := 0.09;
    v_guest_fee_rate := 0.07;
  ELSE
    v_pricing_model := 'EARLY_ADOPTER';
    IF COALESCE(v_host_stats.completed_bookings_count, 0) < 3 THEN
      v_pricing_phase := 'WELCOME';
      v_host_commission_rate := 0;
      v_guest_fee_rate := 0.07;
    ELSIF COALESCE(v_host_stats.completed_bookings_count, 0) >= 10
          AND COALESCE(v_host_stats.average_rating, 0) >= 4.5 THEN
      v_pricing_phase := 'ELITE';
      v_host_commission_rate := 0.07;
      v_guest_fee_rate := 0.07;
    ELSE
      v_pricing_phase := 'STANDARD';
      v_host_commission_rate := 0.09;
      v_guest_fee_rate := 0.07;
    END IF;
  END IF;

  v_host_commission := v_base_total * v_host_commission_rate;

  -- Apply $90.000 CLP cap for FLAT_FEE_CAP model
  IF v_pricing_model = 'FLAT_FEE_CAP' AND v_host_commission > 90000 THEN
    v_host_commission := 90000;
  END IF;

  v_guest_fee := (v_base_total + v_cleaning_fee) * v_guest_fee_rate;
  v_host_payout := v_base_total + v_cleaning_fee - v_host_commission;
  v_platform_revenue := v_host_commission + v_guest_fee;
  v_total := v_base_total + v_cleaning_fee + v_guest_fee;

  RETURN jsonb_build_object(
    'pricing_model', v_pricing_model,
    'pricing_phase', v_pricing_phase,
    'nights', v_nights,
    'base_total', v_base_total,
    'cleaning_fee', v_cleaning_fee,
    'host_commission_rate', v_host_commission_rate,
    'guest_service_fee_rate', v_guest_fee_rate,
    'host_commission_amount', v_host_commission,
    'guest_service_fee_amount', v_guest_fee,
    'platform_revenue', v_platform_revenue,
    'host_payout_amount', v_host_payout,
    'total', v_total,
    'base_price', v_listing.base_price,
    'price_unit', v_listing.price_unit,
    'guests_count', p_guests_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
