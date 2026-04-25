-- =============================================
-- 014: Mercado Pago Payment Integration
-- =============================================

-- Add Mercado Pago payment tracking columns to bookings
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS mp_payment_id TEXT,
  ADD COLUMN IF NOT EXISTS mp_preference_id TEXT;

-- Index for quick lookup by MP payment ID (webhook processing)
CREATE INDEX IF NOT EXISTS idx_bookings_mp_payment_id
  ON bookings(mp_payment_id) WHERE mp_payment_id IS NOT NULL;

-- Index for quick lookup by MP preference ID
CREATE INDEX IF NOT EXISTS idx_bookings_mp_preference_id
  ON bookings(mp_preference_id) WHERE mp_preference_id IS NOT NULL;

-- Ensure payment_status has all needed values
-- (existing column, just documenting valid values)
COMMENT ON COLUMN bookings.payment_status IS
  'Payment status: pending, paid, failed, refunded, cancelled';

-- Function to auto-expire unpaid bookings after 30 minutes
-- Called via pg_cron or application-level scheduling
CREATE OR REPLACE FUNCTION expire_unpaid_bookings()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  expired_count INTEGER;
BEGIN
  UPDATE bookings
  SET status = 'cancelled',
      payment_status = 'cancelled',
      updated_at = NOW()
  WHERE payment_status = 'pending'
    AND status IN ('pending', 'confirmed')
    AND created_at < NOW() - INTERVAL '30 minutes'
    AND mp_preference_id IS NOT NULL;  -- Only auto-expire MP-initiated bookings

  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$;
