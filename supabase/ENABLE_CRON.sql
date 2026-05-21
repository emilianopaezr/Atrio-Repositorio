-- =============================================
-- ENABLE_CRON.sql
-- Run this if VERIFY_CRON.sql showed pg_cron missing or the job not scheduled.
-- Safe to re-run (idempotent).
-- Copy & paste into Supabase Dashboard → SQL Editor → Run.
-- =============================================

-- 1. Install the pg_cron extension (idempotent).
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Ensure the function exists (re-create to pick up any patches).
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
      payment_status = 'paid'
      AND status IN ('pending', 'confirmed', 'active')
      AND COALESCE(check_out, booking_date::timestamptz, check_in) < NOW()
    RETURNING id
  )
  SELECT COUNT(*) INTO affected_count FROM updated;

  RETURN affected_count;
END;
$$;

COMMENT ON FUNCTION mark_completed_bookings IS
  'Sweeps bookings whose end date passed and marks them as completed. Run on cron or call from admin UI.';

-- 3. Re-schedule the job (idempotent: unschedule first if it already exists).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'atrio-mark-completed-bookings'
  ) THEN
    PERFORM cron.unschedule('atrio-mark-completed-bookings');
  END IF;

  -- Runs every hour at minute 5.
  PERFORM cron.schedule(
    'atrio-mark-completed-bookings',
    '5 * * * *',
    $cron$ SELECT mark_completed_bookings(); $cron$
  );
END $$;

-- 4. Backfill: run it once immediately so the DB is current.
SELECT mark_completed_bookings() AS bookings_completed_now;

-- 5. Confirm the job is active.
SELECT jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'atrio-mark-completed-bookings';
