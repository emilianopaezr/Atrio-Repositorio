-- =============================================
-- CLEANUP_UNVERIFIED.sql
-- Releases emails that got stuck on a half-signup: the user exists in
-- auth.users but never confirmed (no session, profile row but
-- email_verified=false, no real activity).
--
-- Use in two ways:
--   A) One-off: release a specific email manually.
--   B) Scheduled: drop orphan accounts older than 24h on a cron job.
-- =============================================

-- ─── OPTION A: Release a single email manually ─────────────────────
-- Replace 'paez8374@gmail.com' below, then run.
-- This will delete the auth.users row + cascade to profile + otp_codes.
--
-- DELETE FROM auth.users
-- WHERE email = 'paez8374@gmail.com'
--   AND confirmed_at IS NULL
--   AND created_at < NOW() - INTERVAL '5 minutes';

-- ─── Preview before deleting (safer) ───────────────────────────────
-- Run this first to see what would be deleted.
SELECT
  u.id,
  u.email,
  u.created_at,
  u.confirmed_at,
  COALESCE(p.email_verified, false) AS profile_verified,
  NOW() - u.created_at AS age,
  CASE
    WHEN u.confirmed_at IS NOT NULL THEN '✅ Confirmed — leave alone'
    WHEN u.created_at > NOW() - INTERVAL '5 minutes' THEN '⏳ Just signed up — wait'
    WHEN u.created_at > NOW() - INTERVAL '24 hours' THEN '🟡 Orphan < 24h'
    ELSE '🔴 Orphan > 24h — safe to delete'
  END AS state
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
WHERE u.confirmed_at IS NULL
ORDER BY u.created_at DESC;

-- ─── OPTION B: Delete all old unverified accounts (idempotent) ─────
-- Uncomment the DELETE below when you've reviewed the preview above.
--
-- DELETE FROM auth.users
-- WHERE confirmed_at IS NULL
--   AND created_at < NOW() - INTERVAL '24 hours';

-- ─── OPTION C: Schedule a daily cleanup ────────────────────────────
-- Run this once to schedule a nightly orphan-account sweep. Safe to
-- re-run — unschedules the existing job first.
--
-- DO $$
-- BEGIN
--   IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
--     PERFORM cron.unschedule('atrio-cleanup-unverified')
--       WHERE EXISTS (
--         SELECT 1 FROM cron.job WHERE jobname = 'atrio-cleanup-unverified'
--       );
--     PERFORM cron.schedule(
--       'atrio-cleanup-unverified',
--       '0 3 * * *', -- every day at 03:00
--       $cron$
--         DELETE FROM auth.users
--         WHERE confirmed_at IS NULL
--           AND created_at < NOW() - INTERVAL '24 hours';
--       $cron$
--     );
--   END IF;
-- END $$;
