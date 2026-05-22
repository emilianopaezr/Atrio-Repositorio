-- =============================================
-- SYNC_AUTH_TO_PROFILE.sql
-- Keeps profiles.email_verified in sync with auth.users.confirmed_at.
--
-- Why: Supabase Auth can auto-confirm users at signup (depending on
-- project settings), so auth.users.confirmed_at gets populated
-- immediately. Our custom OTP flow waits for profiles.email_verified
-- = TRUE before letting the user into the app. If Brevo never delivers
-- the OTP, the two flags stay out of sync and the user is locked in
-- the verification screen forever.
--
-- This script:
--   1. Backfills existing users: any auth.users.confirmed_at NOT NULL
--      → profiles.email_verified = TRUE.
--   2. Installs a trigger so future confirmations propagate
--      automatically.
-- Idempotent.
-- =============================================

-- 1. Backfill once for existing users
UPDATE profiles p
SET email_verified = TRUE, updated_at = NOW()
FROM auth.users u
WHERE p.id = u.id
  AND u.confirmed_at IS NOT NULL
  AND p.email_verified = FALSE;

-- 2. Trigger function: when auth.users.confirmed_at changes from NULL
--    to a timestamp, mirror to profiles.email_verified.
CREATE OR REPLACE FUNCTION sync_email_verified_to_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.confirmed_at IS NOT NULL
     AND (OLD.confirmed_at IS NULL OR OLD.confirmed_at IS DISTINCT FROM NEW.confirmed_at)
  THEN
    UPDATE profiles
    SET email_verified = TRUE, updated_at = NOW()
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

-- 3. Drop + recreate the trigger (idempotent).
DROP TRIGGER IF EXISTS trg_sync_email_verified ON auth.users;
CREATE TRIGGER trg_sync_email_verified
AFTER UPDATE OR INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION sync_email_verified_to_profile();

-- 4. Verify
SELECT
  u.email,
  u.confirmed_at IS NOT NULL AS auth_confirmed,
  p.email_verified AS profile_verified,
  CASE
    WHEN (u.confirmed_at IS NOT NULL) = p.email_verified THEN '✅ Synced'
    ELSE '🔴 Out of sync'
  END AS state
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
ORDER BY u.created_at DESC
LIMIT 10;
