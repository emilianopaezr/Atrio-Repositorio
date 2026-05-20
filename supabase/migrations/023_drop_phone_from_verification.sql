-- =============================================
-- 023_drop_phone_from_verification.sql
-- The product no longer requires phone verification. is_verified is now:
--   email_verified AND kyc_status='approved'
-- This file:
--   1. Replaces recompute_profile_is_verified() to drop the phone check.
--   2. Recreates the trigger so it fires only on email_verified / kyc_status.
--   3. Backfills existing rows so anyone who was only blocked by missing
--      phone_verified now flips to is_verified = TRUE if their email + KYC
--      already passed.
-- =============================================

CREATE OR REPLACE FUNCTION recompute_profile_is_verified()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.is_verified :=
       COALESCE(NEW.email_verified, FALSE)
   AND COALESCE(NEW.kyc_status, 'none') = 'approved';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_recompute_is_verified ON profiles;
CREATE TRIGGER trg_recompute_is_verified
  BEFORE UPDATE OF email_verified, kyc_status ON profiles
  FOR EACH ROW EXECUTE FUNCTION recompute_profile_is_verified();

-- Backfill: recompute for every existing profile.
UPDATE profiles
SET is_verified = (
  COALESCE(email_verified, FALSE)
  AND COALESCE(kyc_status, 'none') = 'approved'
);
