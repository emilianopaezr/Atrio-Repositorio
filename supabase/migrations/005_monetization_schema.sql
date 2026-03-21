-- =============================================
-- 005: Monetization, Gamification & Pricing System
-- =============================================

-- 1. PRICING CONFIGURATION TABLE
CREATE TABLE IF NOT EXISTS pricing_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value JSONB NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. HOST STATS TABLE
CREATE TABLE IF NOT EXISTS host_stats (
  host_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  completed_bookings_count INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2) DEFAULT 0,
  current_level TEXT DEFAULT 'NEW_HOST' CHECK (current_level IN ('NEW_HOST', 'RISING_HOST', 'PRO_HOST', 'ELITE_HOST')),
  current_commission_rate DECIMAL(5,4) DEFAULT 0.0900,
  total_earnings DECIMAL(12,2) DEFAULT 0,
  response_rate DECIMAL(5,2) DEFAULT 0,
  elite_eligible BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. GUEST STATS TABLE
CREATE TABLE IF NOT EXISTS guest_stats (
  guest_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  completed_bookings_count INTEGER DEFAULT 0,
  cancellation_rate DECIMAL(5,4) DEFAULT 0,
  total_spent DECIMAL(12,2) DEFAULT 0,
  current_level TEXT DEFAULT 'EXPLORER' CHECK (current_level IN ('EXPLORER', 'REGULAR', 'VIP', 'ELITE_GUEST')),
  benefits JSONB DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. EXTEND BOOKINGS TABLE
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS pricing_model TEXT,
  ADD COLUMN IF NOT EXISTS pricing_phase TEXT,
  ADD COLUMN IF NOT EXISTS host_commission_rate DECIMAL(5,4),
  ADD COLUMN IF NOT EXISTS guest_service_fee_rate DECIMAL(5,4),
  ADD COLUMN IF NOT EXISTS host_commission_amount DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS guest_service_fee_amount DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS platform_revenue DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS host_payout_amount DECIMAL(10,2),
  ADD COLUMN IF NOT EXISTS pricing_snapshot JSONB DEFAULT '{}';

-- 5. EXTEND PROFILES TABLE
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS host_level TEXT DEFAULT 'NEW_HOST',
  ADD COLUMN IF NOT EXISTS guest_level TEXT DEFAULT 'EXPLORER';

-- 6. INDEXES
CREATE INDEX IF NOT EXISTS idx_host_stats_level ON host_stats(current_level);
CREATE INDEX IF NOT EXISTS idx_guest_stats_level ON guest_stats(current_level);
CREATE INDEX IF NOT EXISTS idx_pricing_config_key ON pricing_config(key);
CREATE INDEX IF NOT EXISTS idx_bookings_pricing_model ON bookings(pricing_model);

-- 7. RLS POLICIES

-- pricing_config: readable by all authenticated
ALTER TABLE pricing_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read pricing config" ON pricing_config
  FOR SELECT USING (true);

-- host_stats
ALTER TABLE host_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Host can read own stats" ON host_stats
  FOR SELECT USING (auth.uid() = host_id);
CREATE POLICY "Service can manage host stats" ON host_stats
  FOR ALL USING (true);

-- guest_stats
ALTER TABLE guest_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Guest can read own stats" ON guest_stats
  FOR SELECT USING (auth.uid() = guest_id);
CREATE POLICY "Service can manage guest stats" ON guest_stats
  FOR ALL USING (true);

-- 8. AUTO-UPDATE TIMESTAMPS
CREATE OR REPLACE TRIGGER set_pricing_config_updated_at
  BEFORE UPDATE ON pricing_config
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER set_host_stats_updated_at
  BEFORE UPDATE ON host_stats
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER set_guest_stats_updated_at
  BEFORE UPDATE ON guest_stats
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 9. PRICING CALCULATION RPC FUNCTION
CREATE OR REPLACE FUNCTION calculate_booking_pricing(
  p_listing_id UUID,
  p_guest_id UUID,
  p_host_id UUID,
  p_check_in DATE,
  p_check_out DATE,
  p_guests_count INTEGER DEFAULT 1
) RETURNS JSONB AS $$
DECLARE
  v_listing RECORD;
  v_host_stats RECORD;
  v_config RECORD;
  v_platform_launch_date TIMESTAMPTZ;
  v_platform_age_months INTEGER;
  v_host_count INTEGER;
  v_nights INTEGER;
  v_base_total DECIMAL(10,2);
  v_cleaning_fee DECIMAL(10,2);
  v_host_commission_rate DECIMAL(5,4);
  v_guest_fee_rate DECIMAL(5,4);
  v_pricing_model TEXT;
  v_pricing_phase TEXT;
  v_host_commission DECIMAL(10,2);
  v_guest_fee DECIMAL(10,2);
  v_platform_revenue DECIMAL(10,2);
  v_host_payout DECIMAL(10,2);
  v_total DECIMAL(10,2);
  v_hook_eligible BOOLEAN := FALSE;
BEGIN
  -- Fetch listing
  SELECT * INTO v_listing FROM listings WHERE id = p_listing_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Listing not found');
  END IF;

  -- Fetch host stats (may not exist)
  SELECT * INTO v_host_stats FROM host_stats WHERE host_id = p_host_id;

  -- Calculate nights
  v_nights := GREATEST(p_check_out - p_check_in, 1);

  -- Calculate base amounts based on price_unit
  IF v_listing.price_unit = 'person' THEN
    v_base_total := COALESCE(v_listing.base_price, 0) * p_guests_count;
  ELSIF v_listing.price_unit IN ('hour', 'session') THEN
    v_base_total := COALESCE(v_listing.base_price, 0) * v_nights;
  ELSE
    v_base_total := COALESCE(v_listing.base_price, 0) * v_nights;
  END IF;

  v_cleaning_fee := COALESCE(v_listing.cleaning_fee, 0);

  -- Get platform launch date from config
  SELECT (value #>> '{}')::TIMESTAMPTZ INTO v_platform_launch_date
    FROM pricing_config WHERE key = 'platform_launch_date' AND is_active = TRUE;
  IF v_platform_launch_date IS NULL THEN
    v_platform_launch_date := NOW() - INTERVAL '1 month';
  END IF;

  v_platform_age_months := EXTRACT(MONTH FROM AGE(NOW(), v_platform_launch_date))
    + EXTRACT(YEAR FROM AGE(NOW(), v_platform_launch_date)) * 12;

  -- Count total hosts for early adopter check
  SELECT COUNT(*) INTO v_host_count FROM profiles WHERE is_host = TRUE;

  -- ========================================
  -- PRICING MODEL SELECTION (Priority Order)
  -- ========================================

  -- MODEL 1: HOOK 1% (platform < 6 months OR host in first 100)
  IF v_platform_age_months < 6 OR v_host_count <= 100 THEN
    v_hook_eligible := TRUE;
  END IF;

  IF v_hook_eligible THEN
    v_pricing_model := 'HOOK_1_PERCENT';
    v_pricing_phase := NULL;
    v_host_commission_rate := 0.01;
    v_guest_fee_rate := 0.07;

  -- MODEL 2: FLAT-FEE CAP (booking > $500 OR > 7 days)
  ELSIF v_base_total > 500 OR v_nights > 7 THEN
    v_pricing_model := 'FLAT_FEE_CAP';
    v_pricing_phase := NULL;
    v_host_commission_rate := 0.09;
    v_guest_fee_rate := 0.07;

  -- MODEL 3: EARLY ADOPTER (progressive)
  ELSE
    v_pricing_model := 'EARLY_ADOPTER';

    IF COALESCE(v_host_stats.completed_bookings_count, 0) < 3 THEN
      -- Phase A: Welcome (0% for first 3 bookings)
      v_pricing_phase := 'WELCOME';
      v_host_commission_rate := 0;
      v_guest_fee_rate := 0.07;
    ELSIF COALESCE(v_host_stats.completed_bookings_count, 0) >= 10
          AND COALESCE(v_host_stats.average_rating, 0) >= 4.5 THEN
      -- Phase C: Elite
      v_pricing_phase := 'ELITE';
      v_host_commission_rate := 0.07;
      v_guest_fee_rate := 0.07;
    ELSE
      -- Phase B: Standard
      v_pricing_phase := 'STANDARD';
      v_host_commission_rate := 0.09;
      v_guest_fee_rate := 0.07;
    END IF;
  END IF;

  -- ========================================
  -- CALCULATE AMOUNTS
  -- ========================================
  v_host_commission := v_base_total * v_host_commission_rate;

  -- Apply $99 cap for FLAT_FEE_CAP model
  IF v_pricing_model = 'FLAT_FEE_CAP' AND v_host_commission > 99 THEN
    v_host_commission := 99;
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

-- 10. HOST STATS UPDATE TRIGGER
CREATE OR REPLACE FUNCTION update_host_stats_on_booking()
RETURNS TRIGGER AS $$
DECLARE
  v_avg_rating DECIMAL(3,2);
  v_completed INTEGER;
  v_new_level TEXT;
  v_new_rate DECIMAL(5,4);
BEGIN
  -- Only act when booking transitions to completed
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN

    -- Count completed bookings
    SELECT COUNT(*) INTO v_completed
      FROM bookings WHERE host_id = NEW.host_id AND status = 'completed';

    -- Calculate average rating
    SELECT COALESCE(AVG(r.rating), 0) INTO v_avg_rating
      FROM reviews r
      INNER JOIN bookings b ON r.booking_id = b.id
      WHERE b.host_id = NEW.host_id;

    -- Determine level
    IF v_completed >= 25 AND v_avg_rating >= 4.5 THEN
      v_new_level := 'ELITE_HOST';
      v_new_rate := 0.07;
    ELSIF v_completed >= 10 THEN
      v_new_level := 'PRO_HOST';
      IF v_avg_rating >= 4.5 THEN
        v_new_rate := 0.07;
      ELSE
        v_new_rate := 0.09;
      END IF;
    ELSIF v_completed >= 4 THEN
      v_new_level := 'RISING_HOST';
      v_new_rate := 0.09;
    ELSE
      v_new_level := 'NEW_HOST';
      v_new_rate := 0;
    END IF;

    -- Upsert host stats
    INSERT INTO host_stats (host_id, completed_bookings_count, average_rating, current_level,
                            current_commission_rate, total_earnings, elite_eligible)
    VALUES (NEW.host_id, v_completed, v_avg_rating, v_new_level, v_new_rate,
            COALESCE(NEW.host_payout_amount, 0), (v_completed >= 10 AND v_avg_rating >= 4.5))
    ON CONFLICT (host_id) DO UPDATE SET
      completed_bookings_count = v_completed,
      average_rating = v_avg_rating,
      current_level = v_new_level,
      current_commission_rate = v_new_rate,
      total_earnings = host_stats.total_earnings + COALESCE(NEW.host_payout_amount, 0),
      elite_eligible = (v_completed >= 10 AND v_avg_rating >= 4.5),
      updated_at = NOW();

    -- Update profile host_level
    UPDATE profiles SET host_level = v_new_level WHERE id = NEW.host_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trigger_update_host_stats
  AFTER UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_host_stats_on_booking();

-- 11. GUEST STATS UPDATE TRIGGER
CREATE OR REPLACE FUNCTION update_guest_stats_on_booking()
RETURNS TRIGGER AS $$
DECLARE
  v_completed INTEGER;
  v_total_bookings INTEGER;
  v_cancelled INTEGER;
  v_cancel_rate DECIMAL(5,4);
  v_total_spent DECIMAL(12,2);
  v_new_level TEXT;
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    SELECT COUNT(*) INTO v_completed
      FROM bookings WHERE guest_id = NEW.guest_id AND status = 'completed';

    SELECT COUNT(*) INTO v_total_bookings
      FROM bookings WHERE guest_id = NEW.guest_id;

    SELECT COUNT(*) INTO v_cancelled
      FROM bookings WHERE guest_id = NEW.guest_id AND status = 'cancelled';

    IF v_total_bookings > 0 THEN
      v_cancel_rate := v_cancelled::DECIMAL / v_total_bookings;
    ELSE
      v_cancel_rate := 0;
    END IF;

    SELECT COALESCE(SUM(total), 0) INTO v_total_spent
      FROM bookings WHERE guest_id = NEW.guest_id AND status = 'completed';

    -- Determine level
    IF v_completed >= 25 AND v_cancel_rate < 0.10 THEN
      v_new_level := 'ELITE_GUEST';
    ELSIF v_completed >= 10 THEN
      v_new_level := 'VIP';
    ELSIF v_completed >= 3 THEN
      v_new_level := 'REGULAR';
    ELSE
      v_new_level := 'EXPLORER';
    END IF;

    INSERT INTO guest_stats (guest_id, completed_bookings_count, cancellation_rate,
                             total_spent, current_level)
    VALUES (NEW.guest_id, v_completed, v_cancel_rate, v_total_spent, v_new_level)
    ON CONFLICT (guest_id) DO UPDATE SET
      completed_bookings_count = v_completed,
      cancellation_rate = v_cancel_rate,
      total_spent = v_total_spent,
      current_level = v_new_level,
      updated_at = NOW();

    -- Update profile guest_level
    UPDATE profiles SET guest_level = v_new_level WHERE id = NEW.guest_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trigger_update_guest_stats
  AFTER UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_guest_stats_on_booking();

-- 12. RECALCULATE HOST STATS ON NEW REVIEW
CREATE OR REPLACE FUNCTION update_host_stats_on_review()
RETURNS TRIGGER AS $$
DECLARE
  v_host_id UUID;
  v_avg_rating DECIMAL(3,2);
  v_completed INTEGER;
  v_new_level TEXT;
  v_new_rate DECIMAL(5,4);
BEGIN
  v_host_id := NEW.host_id;

  SELECT COALESCE(AVG(r.rating), 0) INTO v_avg_rating
    FROM reviews r WHERE r.host_id = v_host_id;

  SELECT COUNT(*) INTO v_completed
    FROM bookings WHERE host_id = v_host_id AND status = 'completed';

  IF v_completed >= 25 AND v_avg_rating >= 4.5 THEN
    v_new_level := 'ELITE_HOST';
    v_new_rate := 0.07;
  ELSIF v_completed >= 10 THEN
    v_new_level := 'PRO_HOST';
    IF v_avg_rating >= 4.5 THEN
      v_new_rate := 0.07;
    ELSE
      v_new_rate := 0.09;
    END IF;
  ELSIF v_completed >= 4 THEN
    v_new_level := 'RISING_HOST';
    v_new_rate := 0.09;
  ELSE
    v_new_level := 'NEW_HOST';
    v_new_rate := 0;
  END IF;

  INSERT INTO host_stats (host_id, completed_bookings_count, average_rating, current_level,
                          current_commission_rate, elite_eligible)
  VALUES (v_host_id, v_completed, v_avg_rating, v_new_level, v_new_rate,
          (v_completed >= 10 AND v_avg_rating >= 4.5))
  ON CONFLICT (host_id) DO UPDATE SET
    average_rating = v_avg_rating,
    current_level = v_new_level,
    current_commission_rate = v_new_rate,
    elite_eligible = (v_completed >= 10 AND v_avg_rating >= 4.5),
    updated_at = NOW();

  UPDATE profiles SET host_level = v_new_level WHERE id = v_host_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER trigger_update_host_stats_on_review
  AFTER INSERT ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_host_stats_on_review();

-- 13. SEED PRICING CONFIG
INSERT INTO pricing_config (key, value, description) VALUES
  ('platform_launch_date', '"2026-03-01T00:00:00Z"', 'Platform launch date'),
  ('hook_host_commission_rate', '0.01', 'Hook model: host commission rate'),
  ('hook_guest_fee_rate', '0.07', 'Hook model: guest service fee rate'),
  ('hook_duration_months', '6', 'Hook model: duration in months'),
  ('hook_max_hosts', '100', 'Hook model: max early adopter hosts'),
  ('flat_fee_host_commission_rate', '0.09', 'Flat-fee model: host commission rate'),
  ('flat_fee_cap_amount', '99', 'Flat-fee model: max commission USD'),
  ('flat_fee_min_booking_amount', '500', 'Flat-fee model: min booking total to trigger'),
  ('flat_fee_min_days', '7', 'Flat-fee model: min days to trigger'),
  ('early_adopter_free_bookings', '3', 'Early adopter: free commission bookings count'),
  ('standard_host_commission_rate', '0.09', 'Standard commission rate'),
  ('elite_host_commission_rate', '0.07', 'Elite host reduced commission rate'),
  ('elite_min_rating', '4.5', 'Elite host: minimum average rating'),
  ('elite_min_completed_bookings', '10', 'Elite host: minimum completed bookings'),
  ('guest_base_fee_rate', '0.07', 'Guest service fee rate')
ON CONFLICT (key) DO NOTHING;

-- 14. SEED INITIAL HOST/GUEST STATS FOR TEST USERS
INSERT INTO host_stats (host_id, completed_bookings_count, average_rating, current_level,
                        current_commission_rate, total_earnings, response_rate, elite_eligible)
VALUES ('053c11bd-9fd7-484e-bb30-d75532d4db54', 1, 4.85, 'NEW_HOST', 0.01, 687.50, 98.5, FALSE)
ON CONFLICT (host_id) DO NOTHING;

INSERT INTO guest_stats (guest_id, completed_bookings_count, cancellation_rate, total_spent,
                         current_level, benefits)
VALUES ('98e8b712-ae4d-446e-9c50-bf621a1efe75', 1, 0, 687.50, 'EXPLORER', '{}')
ON CONFLICT (guest_id) DO NOTHING;
