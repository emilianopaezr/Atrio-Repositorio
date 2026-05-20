-- ═══════════════════════════════════════════════════════════════════
-- ATRIO — KYC COMPLETE SETUP
-- Paste this ENTIRE file into Supabase Studio → SQL Editor → Run.
-- It is idempotent — safe to run multiple times.
-- ═══════════════════════════════════════════════════════════════════

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ SECTION 1 — KYC schema, storage bucket, RLS, RPCs & notifications ║
-- ║ (same content as migration 022_kyc_complete.sql)              ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- 1.1  is_admin column ------------------------------------------------
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_profiles_kyc_status
  ON profiles(kyc_status)
  WHERE kyc_status = 'pending';

GRANT SELECT (is_admin) ON profiles TO authenticated;

-- 1.2  Storage bucket -------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'kyc',
  'kyc',
  FALSE,
  10 * 1024 * 1024,
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/heic']
)
ON CONFLICT (id) DO UPDATE
  SET public = FALSE,
      file_size_limit = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 1.3  Storage RLS ----------------------------------------------------
DROP POLICY IF EXISTS "kyc_owner_insert" ON storage.objects;
DROP POLICY IF EXISTS "kyc_owner_update" ON storage.objects;
DROP POLICY IF EXISTS "kyc_owner_select" ON storage.objects;
DROP POLICY IF EXISTS "kyc_owner_delete" ON storage.objects;
DROP POLICY IF EXISTS "kyc_admin_select" ON storage.objects;

CREATE POLICY "kyc_owner_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'kyc' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "kyc_owner_update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'kyc' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "kyc_owner_select" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'kyc' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "kyc_owner_delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'kyc' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "kyc_admin_select" ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'kyc'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND is_admin = TRUE
    )
  );

-- 1.4  kyc_submit (resubmit-friendly) ---------------------------------
CREATE OR REPLACE FUNCTION kyc_submit(
  p_id_front_path text,
  p_id_back_path  text,
  p_selfie_path   text
)
RETURNS profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_current_status text;
  v_profile profiles;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = '42501';
  END IF;
  IF p_id_front_path IS NULL OR p_id_back_path IS NULL OR p_selfie_path IS NULL THEN
    RAISE EXCEPTION 'all three document paths are required';
  END IF;

  SELECT kyc_status INTO v_current_status FROM profiles WHERE id = v_uid;
  IF v_current_status = 'approved' THEN
    RAISE EXCEPTION 'kyc already approved' USING ERRCODE = '22023';
  END IF;
  IF v_current_status = 'pending' THEN
    RAISE EXCEPTION 'kyc already pending review' USING ERRCODE = '22023';
  END IF;

  UPDATE profiles
  SET kyc_documents = jsonb_build_object(
        'id_front', p_id_front_path,
        'id_back',  p_id_back_path,
        'selfie',   p_selfie_path
      ),
      kyc_status       = 'pending',
      kyc_submitted_at = NOW(),
      kyc_reviewed_at  = NULL,
      kyc_review_note  = NULL,
      updated_at       = NOW()
  WHERE id = v_uid
  RETURNING * INTO v_profile;

  RETURN v_profile;
END;
$$;

REVOKE EXECUTE ON FUNCTION kyc_submit(text, text, text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION kyc_submit(text, text, text) TO authenticated;

-- 1.5  Admin RPCs ------------------------------------------------------
CREATE OR REPLACE FUNCTION kyc_approve(p_user_id uuid, p_note text DEFAULT NULL)
RETURNS profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_p profiles; v_admin BOOLEAN;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = '42501';
  END IF;
  SELECT is_admin INTO v_admin FROM profiles WHERE id = auth.uid();
  IF NOT COALESCE(v_admin, FALSE) THEN
    RAISE EXCEPTION 'admin only' USING ERRCODE = '42501';
  END IF;

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
DECLARE v_p profiles; v_admin BOOLEAN;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = '42501';
  END IF;
  SELECT is_admin INTO v_admin FROM profiles WHERE id = auth.uid();
  IF NOT COALESCE(v_admin, FALSE) THEN
    RAISE EXCEPTION 'admin only' USING ERRCODE = '42501';
  END IF;
  IF p_reason IS NULL OR length(trim(p_reason)) = 0 THEN
    RAISE EXCEPTION 'reason required' USING ERRCODE = '22023';
  END IF;

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

REVOKE EXECUTE ON FUNCTION kyc_approve(uuid, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION kyc_reject(uuid, text)  FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION kyc_approve(uuid, text) TO authenticated, service_role;
GRANT  EXECUTE ON FUNCTION kyc_reject(uuid, text)  TO authenticated, service_role;

-- 1.6  Admin helper: list pending submissions --------------------------
CREATE OR REPLACE FUNCTION kyc_list_pending()
RETURNS TABLE (
  user_id          uuid,
  display_name     text,
  email            text,
  phone            text,
  kyc_status       text,
  kyc_documents    jsonb,
  kyc_submitted_at timestamptz,
  email_verified   boolean,
  phone_verified   boolean
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_admin BOOLEAN;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized' USING ERRCODE = '42501';
  END IF;
  SELECT is_admin INTO v_admin FROM profiles WHERE id = auth.uid();
  IF NOT COALESCE(v_admin, FALSE) THEN
    RAISE EXCEPTION 'admin only' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
    SELECT p.id,
           p.display_name,
           u.email,
           p.phone,
           p.kyc_status,
           p.kyc_documents,
           p.kyc_submitted_at,
           p.email_verified,
           p.phone_verified
    FROM profiles p
    LEFT JOIN auth.users u ON u.id = p.id
    WHERE p.kyc_status = 'pending'
    ORDER BY p.kyc_submitted_at ASC NULLS LAST;
END;
$$;

REVOKE EXECUTE ON FUNCTION kyc_list_pending() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION kyc_list_pending() TO authenticated, service_role;

-- 1.7  Notification trigger -------------------------------------------
CREATE OR REPLACE FUNCTION notify_kyc_status_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_title text;
  v_body  text;
BEGIN
  IF NEW.kyc_status = OLD.kyc_status THEN
    RETURN NEW;
  END IF;

  IF NEW.kyc_status = 'approved' THEN
    v_title := 'Documento aprobado';
    v_body  := 'Tu cuenta ya está verificada. Ahora apareces destacado en búsquedas.';
  ELSIF NEW.kyc_status = 'rejected' THEN
    v_title := 'Necesitamos otra foto';
    v_body  := COALESCE(NEW.kyc_review_note,
                        'Revisa tu envío y vuelve a intentarlo.');
  ELSIF NEW.kyc_status = 'pending' AND OLD.kyc_status IN ('rejected', 'none') THEN
    v_title := 'Documentos recibidos';
    v_body  := 'Estamos revisando tu envío. Te avisaremos en 24-48 horas.';
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO notifications (user_id, type, title, body, is_read)
  VALUES (NEW.id, 'kyc', v_title, v_body, FALSE);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_kyc_status_change ON profiles;
CREATE TRIGGER trg_notify_kyc_status_change
  AFTER UPDATE OF kyc_status ON profiles
  FOR EACH ROW EXECUTE FUNCTION notify_kyc_status_change();


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ SECTION 2 — Mark yourself as admin                            ║
-- ║ Replace the email below with the one you use to log in.       ║
-- ╚═══════════════════════════════════════════════════════════════╝

UPDATE profiles
SET is_admin = TRUE
WHERE id = (
  SELECT id FROM auth.users
  WHERE email = 'emilianopaezr@gmail.com'   -- ◀── CHANGE THIS
);


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ SECTION 3 — Reload PostgREST schema cache                      ║
-- ║ So the new RPCs become callable immediately.                   ║
-- ╚═══════════════════════════════════════════════════════════════╝

NOTIFY pgrst, 'reload schema';


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ SECTION 4 — Health check (read-only, just to confirm)         ║
-- ║ After running, you should see:                                ║
-- ║   • bucket_exists: t                                          ║
-- ║   • admin_count: ≥ 1                                          ║
-- ║   • kyc_status counts                                         ║
-- ╚═══════════════════════════════════════════════════════════════╝

SELECT
  (SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'kyc')) AS bucket_exists,
  (SELECT COUNT(*)::int FROM profiles WHERE is_admin = TRUE)      AS admin_count,
  (SELECT jsonb_object_agg(kyc_status, c)
     FROM (SELECT kyc_status, COUNT(*)::int AS c
             FROM profiles
             GROUP BY kyc_status) s)                              AS kyc_counts;
