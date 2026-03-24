-- ============================================
-- ATRIO - Booking System V2
-- Rental modes: hours, full_day, nights
-- Time slots, real-time availability
-- ============================================

-- 1. Add rental_mode and schedule config to listings
ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS rental_mode TEXT DEFAULT 'nights'
    CHECK (rental_mode IN ('hours', 'full_day', 'nights')),
  ADD COLUMN IF NOT EXISTS available_days INTEGER[] DEFAULT '{1,2,3,4,5,6,0}',
  ADD COLUMN IF NOT EXISTS available_from TIME DEFAULT '09:00',
  ADD COLUMN IF NOT EXISTS available_until TIME DEFAULT '22:00',
  ADD COLUMN IF NOT EXISTS min_hours INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS max_hours INTEGER DEFAULT 12,
  ADD COLUMN IF NOT EXISTS min_nights INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS max_nights INTEGER DEFAULT 30,
  ADD COLUMN IF NOT EXISTS slot_duration_minutes INTEGER DEFAULT 60,
  ADD COLUMN IF NOT EXISTS max_capacity INTEGER,
  ADD COLUMN IF NOT EXISTS instant_booking BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS check_in_time TIME DEFAULT '15:00',
  ADD COLUMN IF NOT EXISTS check_out_time TIME DEFAULT '11:00',
  ADD COLUMN IF NOT EXISTS cancellation_policy TEXT DEFAULT 'flexible'
    CHECK (cancellation_policy IN ('flexible', 'moderate', 'strict'));

-- 2. Add time slots to bookings
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS rental_mode TEXT DEFAULT 'nights'
    CHECK (rental_mode IN ('hours', 'full_day', 'nights')),
  ADD COLUMN IF NOT EXISTS time_slots JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS booking_date DATE,
  ADD COLUMN IF NOT EXISTS start_time TIME,
  ADD COLUMN IF NOT EXISTS end_time TIME,
  ADD COLUMN IF NOT EXISTS duration_hours DECIMAL(4,1);

-- 3. Enhance availability table for time slots
ALTER TABLE availability
  ADD COLUMN IF NOT EXISTS time_slots JSONB DEFAULT '[]',
  ADD COLUMN IF NOT EXISTS spots_total INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS spots_booked INTEGER DEFAULT 0;

-- 4. Create time_slot_bookings for atomic hour-level locking
CREATE TABLE IF NOT EXISTS time_slot_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
  slot_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT DEFAULT 'held' CHECK (status IN ('held', 'confirmed', 'cancelled')),
  held_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(listing_id, slot_date, start_time, booking_id)
);

-- Index for fast availability lookups
CREATE INDEX IF NOT EXISTS idx_time_slots_lookup
  ON time_slot_bookings(listing_id, slot_date, status)
  WHERE status IN ('held', 'confirmed');

CREATE INDEX IF NOT EXISTS idx_time_slots_held_until
  ON time_slot_bookings(held_until)
  WHERE status = 'held';

CREATE INDEX IF NOT EXISTS idx_bookings_rental_mode ON bookings(rental_mode);
CREATE INDEX IF NOT EXISTS idx_bookings_booking_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_listings_rental_mode ON listings(rental_mode);

-- 5. Function: Check slot availability (prevents race conditions)
CREATE OR REPLACE FUNCTION check_and_book_slots(
  p_listing_id UUID,
  p_booking_id UUID,
  p_slot_date DATE,
  p_slots JSONB -- array of {start_time, end_time}
) RETURNS BOOLEAN AS $$
DECLARE
  v_slot JSONB;
  v_conflict INTEGER;
BEGIN
  -- Check each slot for conflicts
  FOR v_slot IN SELECT * FROM jsonb_array_elements(p_slots) LOOP
    SELECT COUNT(*) INTO v_conflict
    FROM time_slot_bookings
    WHERE listing_id = p_listing_id
      AND slot_date = p_slot_date
      AND status IN ('held', 'confirmed')
      AND (held_until IS NULL OR held_until > NOW())
      AND start_time < (v_slot->>'end_time')::TIME
      AND end_time > (v_slot->>'start_time')::TIME;

    IF v_conflict > 0 THEN
      RETURN FALSE;
    END IF;
  END LOOP;

  -- No conflicts: insert all slots atomically
  INSERT INTO time_slot_bookings (listing_id, booking_id, slot_date, start_time, end_time, status)
  SELECT
    p_listing_id,
    p_booking_id,
    p_slot_date,
    (slot->>'start_time')::TIME,
    (slot->>'end_time')::TIME,
    'confirmed'
  FROM jsonb_array_elements(p_slots) AS slot;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 6. Function: Check date availability for nights mode
CREATE OR REPLACE FUNCTION check_dates_available(
  p_listing_id UUID,
  p_check_in DATE,
  p_check_out DATE
) RETURNS BOOLEAN AS $$
DECLARE
  v_conflict INTEGER;
BEGIN
  -- Check for any confirmed bookings that overlap
  SELECT COUNT(*) INTO v_conflict
  FROM bookings
  WHERE listing_id = p_listing_id
    AND status IN ('pending', 'confirmed', 'active')
    AND check_in::DATE < p_check_out
    AND check_out::DATE > p_check_in;

  IF v_conflict > 0 THEN
    RETURN FALSE;
  END IF;

  -- Check availability table for blocked dates
  SELECT COUNT(*) INTO v_conflict
  FROM availability
  WHERE listing_id = p_listing_id
    AND date >= p_check_in
    AND date < p_check_out
    AND is_available = FALSE;

  IF v_conflict > 0 THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 7. Function: Get booked dates for a listing (for calendar display)
CREATE OR REPLACE FUNCTION get_booked_dates(
  p_listing_id UUID,
  p_start_date DATE,
  p_end_date DATE
) RETURNS TABLE(
  booked_date DATE,
  is_blocked BOOLEAN,
  booking_id UUID,
  booking_status TEXT
) AS $$
BEGIN
  RETURN QUERY
  -- From bookings: generate series of dates for each booking
  SELECT
    d::DATE AS booked_date,
    FALSE AS is_blocked,
    b.id AS booking_id,
    b.status AS booking_status
  FROM bookings b,
    generate_series(b.check_in::DATE, b.check_out::DATE - INTERVAL '1 day', '1 day') AS d
  WHERE b.listing_id = p_listing_id
    AND b.status IN ('pending', 'confirmed', 'active')
    AND d::DATE >= p_start_date
    AND d::DATE <= p_end_date

  UNION ALL

  -- From availability: blocked dates
  SELECT
    a.date AS booked_date,
    TRUE AS is_blocked,
    a.booking_id,
    NULL AS booking_status
  FROM availability a
  WHERE a.listing_id = p_listing_id
    AND a.is_available = FALSE
    AND a.date >= p_start_date
    AND a.date <= p_end_date;
END;
$$ LANGUAGE plpgsql;

-- 8. Function: Get booked time slots for a date
CREATE OR REPLACE FUNCTION get_booked_time_slots(
  p_listing_id UUID,
  p_date DATE
) RETURNS TABLE(
  start_time TIME,
  end_time TIME,
  slot_status TEXT,
  slot_booking_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    tsb.start_time,
    tsb.end_time,
    tsb.status AS slot_status,
    tsb.booking_id AS slot_booking_id
  FROM time_slot_bookings tsb
  WHERE tsb.listing_id = p_listing_id
    AND tsb.slot_date = p_date
    AND tsb.status IN ('held', 'confirmed')
    AND (tsb.held_until IS NULL OR tsb.held_until > NOW());
END;
$$ LANGUAGE plpgsql;

-- 9. Auto-mark availability when booking is confirmed
CREATE OR REPLACE FUNCTION on_booking_confirmed()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status = 'pending') THEN
    -- For nights mode: mark dates as unavailable
    IF NEW.rental_mode = 'nights' OR NEW.rental_mode = 'full_day' THEN
      INSERT INTO availability (listing_id, date, is_available, booking_id)
      SELECT
        NEW.listing_id,
        d::DATE,
        FALSE,
        NEW.id
      FROM generate_series(
        NEW.check_in::DATE,
        NEW.check_out::DATE - INTERVAL '1 day',
        '1 day'
      ) AS d
      ON CONFLICT (listing_id, date) DO UPDATE
        SET is_available = FALSE, booking_id = NEW.id;
    END IF;

    -- For hours mode: confirm held time slots
    IF NEW.rental_mode = 'hours' THEN
      UPDATE time_slot_bookings
      SET status = 'confirmed', held_until = NULL
      WHERE booking_id = NEW.id AND status = 'held';
    END IF;
  END IF;

  -- On cancellation: free up dates/slots
  IF NEW.status = 'cancelled' AND OLD.status IN ('pending', 'confirmed', 'active') THEN
    DELETE FROM availability
    WHERE booking_id = NEW.id;

    UPDATE time_slot_bookings
    SET status = 'cancelled'
    WHERE booking_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_booking_confirmed ON bookings;
CREATE TRIGGER trigger_booking_confirmed
  AFTER UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION on_booking_confirmed();

-- 10. Clean up expired holds (run periodically or via cron)
CREATE OR REPLACE FUNCTION cleanup_expired_holds()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  WITH expired AS (
    DELETE FROM time_slot_bookings
    WHERE status = 'held' AND held_until < NOW()
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM expired;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- 11. Enable realtime on key tables
ALTER PUBLICATION supabase_realtime ADD TABLE availability;
ALTER PUBLICATION supabase_realtime ADD TABLE time_slot_bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE bookings;

-- 12. RLS for time_slot_bookings
ALTER TABLE time_slot_bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view time slot bookings"
  ON time_slot_bookings FOR SELECT USING (true);

CREATE POLICY "Authenticated can insert time slot bookings"
  ON time_slot_bookings FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Booking owner can update time slot bookings"
  ON time_slot_bookings FOR UPDATE
  USING (
    booking_id IN (
      SELECT id FROM bookings WHERE guest_id = auth.uid() OR host_id = auth.uid()
    )
  );

-- 13. Update existing listings to set rental_mode based on price_unit
UPDATE listings SET rental_mode = 'hours' WHERE price_unit = 'hour';
UPDATE listings SET rental_mode = 'nights' WHERE price_unit = 'night';
UPDATE listings SET rental_mode = 'full_day' WHERE price_unit = 'session';
