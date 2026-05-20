-- =============================================
-- 021_identity_verification.sql
-- Identity verification: email + phone + KYC document upload.
-- Adds columns, syncs auth.users.{email,phone}_confirmed_at to profile,
-- recomputes is_verified, and exposes kyc_submit/approve/reject RPCs.
-- =============================================

-- 1. Profile columns ----------------------------------------------------
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS phone_verified     BOOLEAN     NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS phone_verified_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS kyc_documents      JSONB       NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS kyc_submitted_at   TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS kyc_reviewed_at    TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS kyc_review_note    TEXT;

GRANT SELECT (phone_verified, phone_verified_at, kyc_documents,
              kyc_submitted_at, kyc_reviewed_at, kyc_review_note)
  ON profiles TO authenticated;

-- 2. Sync trigger: auth.users.phone_confirmed_at -> profile.phone_verified
CREATE OR REPLACE FUNCTION sync_phone_verified_to_profile()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.phone_confirmed_at IS NOT NULL
     AND (OLD.phone_confirmed_at IS NULL OR OLD.phone_confirmed_at <> NEW.phone_confirmed_at) THEN
    UPDATE profiles
    SET phone           = NEW.phone,
        phone_verified  = TRUE,
        phone_verified_at = NEW.phone_confirmed_at,
        updated_at      = NOW()
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_phone_verified ON auth.users;
CREATE TRIGGER trg_sync_phone_verified
  AFTER UPDATE OF phone_confirmed_at ON auth.users
  FOR EACH ROW EXECUTE FUNCTION sync_phone_verified_to_profile();

-- 3. Sync trigger: auth.users.email_confirmed_at -> profile.email_verified
CREATE OR REPLACE FUNCTION sync_email_verified_to_profile()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.email_confirmed_at IS NOT NULL
     AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at <> NEW.email_confirmed_at) THEN
    UPDATE profiles
    SET email_verified = TRUE,
        updated_at     = NOW()
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_email_verified ON auth.users;
CREATE TRIGGER trg_sync_email_verified
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW EXECUTE FUNCTION sync_email_verified_to_profile();

-- 4. Recompute profile.is_verified whenever any of the three flags moves.
CREATE OR REPLACE FUNCTION recompute_profile_is_verified()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.is_verified :=
       COALESCE(NEW.email_verified, FALSE)
   AND COALESCE(NEW.phone_verified, FALSE)
   AND COALESCE(NEW.kyc_status, 'none') = 'approved';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_recompute_is_verified ON profiles;
CREATE TRIGGER trg_recompute_is_verified
  BEFORE UPDATE OF email_verified, phone_verified, kyc_status ON profiles
  FOR EACH ROW EXECUTE FUNCTION recompute_profile_is_verified();

-- 5. RPC: kyc_submit (called by client after uploading docs to storage)
CREATE OR REPLACE FUNCTION kyc_submit(
  p_id_front_path text,
  p_id_back_path  text,
  p_selfie_path   text
)
RETURNS profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_profile profiles;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = '42501';
  END IF;
  IF p_id_front_path IS NULL OR p_id_back_path IS NULL OR p_selfie_path IS NULL THEN
    RAISE EXCEPTION 'all three document paths are required';
  END IF;

  UPDATE profiles
  SET kyc_documents = jsonb_build_object(
        'id_front', p_id_front_path,
        'id_back',  p_id_back_path,
        'selfie',   p_selfie_path
      ),
      kyc_status       = 'pending',
      kyc_submitted_at = NOW(),
      kyc_review_note  = NULL,
      updated_at       = NOW()
  WHERE id = v_uid
  RETURNING * INTO v_profile;

  RETURN v_profile;
END;
$$;

REVOKE EXECUTE ON FUNCTION kyc_submit(text, text, text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION kyc_submit(text, text, text) TO authenticated;

-- 6. Admin RPCs: approve / reject (service_role only)
CREATE OR REPLACE FUNCTION kyc_approve(p_user_id uuid, p_note text DEFAULT NULL)
RETURNS profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_p profiles;
BEGIN
  UPDATE profiles
  SET kyc_status      = 'approved',
      kyc_reviewed_at = NOW(),
      kyc_review_note = p_note,
      updated_at      = NOW()
  WHERE id = p_user_id
  RETURNING * INTO v_p;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile % not found', p_user_id; END IF;
  RETURN v_p;
END;
$$;

CREATE OR REPLACE FUNCTION kyc_reject(p_user_id uuid, p_reason text)
RETURNS profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_p profiles;
BEGIN
  UPDATE profiles
  SET kyc_status      = 'rejected',
      kyc_reviewed_at = NOW(),
      kyc_review_note = p_reason,
      updated_at      = NOW()
  WHERE id = p_user_id
  RETURNING * INTO v_p;
  IF NOT FOUND THEN RAISE EXCEPTION 'profile % not found', p_user_id; END IF;
  RETURN v_p;
END;
$$;

REVOKE EXECUTE ON FUNCTION kyc_approve(uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION kyc_reject(uuid, text)  FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION kyc_approve(uuid, text) TO service_role;
GRANT  EXECUTE ON FUNCTION kyc_reject(uuid, text)  TO service_role;

-- 7. Backfill: mark phone_verified TRUE for users that already had
--    phone_confirmed_at set in auth.users.
UPDATE profiles p
SET phone_verified    = TRUE,
    phone_verified_at = u.phone_confirmed_at,
    phone             = COALESCE(p.phone, u.phone)
FROM auth.users u
WHERE u.id = p.id
  AND u.phone_confirmed_at IS NOT NULL
  AND p.phone_verified = FALSE;
