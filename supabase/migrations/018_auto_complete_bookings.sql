-- =============================================
-- 018_auto_complete_bookings.sql
-- Auto-mark bookings as 'completed' once their end date has passed.
-- Fixes "Mis Reservas: pasadas vacía" — bookings stayed in 'pending'/'confirmed'
-- forever because nothing transitioned them to 'completed'.
-- =============================================

-- 1. Function: marks a booking as completed if it qualifies.
CREATE OR REPLACE FUNCTION mark_completed_bookings()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  affected_count integer;
BEGIN
  WITH updated AS (
    UPDATE bookings
    SET status = 'completed',
        updated_at = NOW()
    WHERE
      -- Only successfully paid bookings should auto-complete.
      payment_status = 'paid'
      -- Anything still active that has run its course.
      AND status IN ('pending', 'confirmed', 'active')
      -- End date is strictly in the past.
      AND COALESCE(check_out, booking_date::timestamptz, check_in) < NOW()
    RETURNING id
  )
  SELECT COUNT(*) INTO affected_count FROM updated;

  RETURN affected_count;
END;
$$;

COMMENT ON FUNCTION mark_completed_bookings IS
  'Sweeps bookings whose end date passed and marks them as completed. Run on cron or call from admin UI.';

-- 2. Schedule via pg_cron if available (Supabase ships with it).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Remove old job if it exists (idempotent)
    PERFORM cron.unschedule('atrio-mark-completed-bookings')
    WHERE EXISTS (
      SELECT 1 FROM cron.job WHERE jobname = 'atrio-mark-completed-bookings'
    );

    -- Run every hour at minute 5.
    PERFORM cron.schedule(
      'atrio-mark-completed-bookings',
      '5 * * * *',
      $cron$ SELECT mark_completed_bookings(); $cron$
    );
  END IF;
END $$;

-- 3. One-time backfill: clean up the rows that are already overdue today.
SELECT mark_completed_bookings();
