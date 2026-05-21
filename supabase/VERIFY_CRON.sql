-- =============================================
-- VERIFY_CRON.sql
-- Diagnostic script for the auto_complete_bookings cron job.
-- Copy & paste into Supabase Dashboard → SQL Editor → Run.
-- =============================================

-- 1. Is the pg_cron extension installed?
SELECT
  extname,
  extversion,
  CASE
    WHEN extname = 'pg_cron' THEN '✅ Installed'
    ELSE '❌ Missing'
  END AS status
FROM pg_extension
WHERE extname IN ('pg_cron');

-- 2. Does mark_completed_bookings() function exist?
SELECT
  proname AS function_name,
  CASE
    WHEN proname = 'mark_completed_bookings' THEN '✅ Exists'
    ELSE '❌ Missing'
  END AS status
FROM pg_proc
WHERE proname = 'mark_completed_bookings';

-- 3. Is the cron job scheduled?
SELECT
  jobid,
  jobname,
  schedule,
  command,
  active
FROM cron.job
WHERE jobname = 'atrio-mark-completed-bookings';

-- 4. Last 5 runs of the cron job (most recent first)
SELECT
  start_time,
  status,
  return_message,
  end_time - start_time AS duration
FROM cron.job_run_details
WHERE jobid = (
  SELECT jobid FROM cron.job WHERE jobname = 'atrio-mark-completed-bookings'
)
ORDER BY start_time DESC
LIMIT 5;

-- 5. How many bookings would be auto-completed RIGHT NOW?
SELECT
  COUNT(*) AS pending_to_complete
FROM bookings
WHERE
  payment_status = 'paid'
  AND status IN ('pending', 'confirmed', 'active')
  AND COALESCE(check_out, booking_date::timestamptz, check_in) < NOW();
