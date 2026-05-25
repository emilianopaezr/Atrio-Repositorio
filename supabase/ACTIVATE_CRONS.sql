-- =============================================
-- ACTIVATE_CRONS.sql
-- One-shot script that ensures both production cron jobs are
-- installed and active in your self-hosted Supabase.
--
-- Jobs scheduled:
--   1. atrio-mark-completed-bookings   — hourly at :05
--      Marks paid bookings whose end-date has passed as 'completed'.
--   2. atrio-cleanup-pending-signups   — every 15 minutes
--      Drops abandoned signup rows whose OTP expired.
--
-- Safe to re-run. Idempotent: unschedules existing jobs by name
-- before re-scheduling, so you can edit the schedule string and
-- re-run without dupes.
--
-- HOW TO RUN:
--   Supabase Dashboard → SQL Editor → New Query
--   Paste the entire contents → Run.
--   Check the final SELECT to confirm both jobs are 'active = t'.
-- =============================================

-- 0. Extensions ---------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. mark_completed_bookings function ----------------------------
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
  'Hourly sweep: marks past-end-date paid bookings as completed.';

-- 2. Schedule mark_completed_bookings ----------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'atrio-mark-completed-bookings'
  ) THEN
    PERFORM cron.unschedule('atrio-mark-completed-bookings');
  END IF;

  PERFORM cron.schedule(
    'atrio-mark-completed-bookings',
    '5 * * * *',              -- every hour at minute :05
    $cron$ SELECT mark_completed_bookings(); $cron$
  );
END $$;

-- 3. Backfill once so the table is consistent immediately --------
SELECT mark_completed_bookings() AS bookings_marked_completed_now;

-- 4. Schedule pending_signups cleanup ----------------------------
-- Drops rows where the OTP has expired. These are users who started
-- signup but never verified — we want to let them retry from scratch.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'atrio-cleanup-pending-signups'
  ) THEN
    PERFORM cron.unschedule('atrio-cleanup-pending-signups');
  END IF;

  PERFORM cron.schedule(
    'atrio-cleanup-pending-signups',
    '*/15 * * * *',            -- every 15 minutes
    $cron$
      DELETE FROM pending_signups
      WHERE otp_expires_at < NOW();
    $cron$
  );
END $$;

-- 5. Optional: also clean up expired password_reset_codes --------
-- These were already cleaned by the verify function, but a sweep
-- catches abandoned reset attempts that just timed out.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'password_reset_codes') THEN
    IF EXISTS (
      SELECT 1 FROM cron.job WHERE jobname = 'atrio-cleanup-password-reset'
    ) THEN
      PERFORM cron.unschedule('atrio-cleanup-password-reset');
    END IF;

    PERFORM cron.schedule(
      'atrio-cleanup-password-reset',
      '*/30 * * * *',          -- every 30 minutes
      $cron$
        DELETE FROM password_reset_codes
        WHERE expires_at < NOW() - INTERVAL '1 hour';
      $cron$
    );
  END IF;
END $$;

-- 6. Verification ------------------------------------------------
SELECT
  jobname,
  schedule,
  active,
  command
FROM cron.job
WHERE jobname LIKE 'atrio-%'
ORDER BY jobname;
