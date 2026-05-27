-- =============================================
-- 031_kyc_admin_notify.sql
-- Low-cost KYC: when a user submits identity documents, every admin
-- (profile.is_admin = TRUE) gets an in-app notification with a link to
-- the admin review screen. No third-party KYC SaaS needed yet.
--
-- The notification row hits the existing notifications table, so the
-- admin sees it in their bell + (when push is wired) on lockscreen.
--
-- Idempotente.
-- =============================================

-- 1. Trigger function — fires when kyc_status transitions to 'pending'
CREATE OR REPLACE FUNCTION notify_admins_on_kyc_pending()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_name TEXT;
  v_admin     RECORD;
  v_payload   JSONB;
BEGIN
  -- Only react to a NEW pending submission. Re-approvals / rejections
  -- don't generate noise, otherwise the inbox fills up every time an
  -- admin acts.
  IF NEW.kyc_status IS DISTINCT FROM 'pending' THEN
    RETURN NEW;
  END IF;
  IF OLD.kyc_status = 'pending' THEN
    RETURN NEW;
  END IF;

  v_user_name := COALESCE(NULLIF(NEW.display_name, ''), 'Un usuario');
  v_payload := jsonb_build_object(
    'kyc_user_id', NEW.id,
    'kyc_user_name', v_user_name,
    'deeplink', '/admin/kyc/' || NEW.id::text
  );

  -- Insert one notification per active admin.
  FOR v_admin IN
    SELECT id FROM profiles WHERE is_admin = TRUE
  LOOP
    INSERT INTO notifications (
      user_id,
      type,
      title,
      body,
      data,
      is_read,
      created_at
    ) VALUES (
      v_admin.id,
      'kyc_pending_review',
      'Verificación pendiente',
      v_user_name || ' envió sus documentos para revisar.',
      v_payload,
      false,
      NOW()
    );
  END LOOP;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION notify_admins_on_kyc_pending IS
  'Fan-out notification to every admin when a user submits KYC.';

-- 2. Wire trigger (drop + recreate to keep this script idempotent)
DROP TRIGGER IF EXISTS trg_notify_admins_on_kyc_pending ON profiles;
CREATE TRIGGER trg_notify_admins_on_kyc_pending
  AFTER UPDATE OF kyc_status ON profiles
  FOR EACH ROW
  WHEN (NEW.kyc_status = 'pending' AND
        (OLD.kyc_status IS NULL OR OLD.kyc_status <> 'pending'))
  EXECUTE FUNCTION notify_admins_on_kyc_pending();

-- 3. Helper RPC: count of pending KYC submissions (cheap dashboard badge)
CREATE OR REPLACE FUNCTION kyc_pending_count()
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::int
  FROM profiles
  WHERE kyc_status = 'pending';
$$;

REVOKE EXECUTE ON FUNCTION kyc_pending_count() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION kyc_pending_count() TO authenticated;

-- 4. Sanity check ---------------------------------------------------
SELECT
  (SELECT EXISTS(
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_notify_admins_on_kyc_pending'
  )) AS trigger_present,
  (SELECT EXISTS(
    SELECT 1 FROM pg_proc WHERE proname = 'kyc_pending_count'
  )) AS rpc_present,
  (SELECT COUNT(*) FROM profiles WHERE is_admin = TRUE) AS admin_count;
