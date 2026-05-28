-- =============================================
-- 033_account_deletion.sql
-- Self-serve account deletion: log the user's reason in a
-- standalone table BEFORE the row in auth.users gets dropped,
-- then cascade-delete the user.
--
-- Idempotente.
-- =============================================

-- 1. Survey log — survives the user being deleted on purpose.
CREATE TABLE IF NOT EXISTS account_deletion_reasons (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Snapshot of the deleted user so we can still distinguish a
  -- specific row when the auth.users row is gone.
  user_id     UUID,
  user_email  TEXT,
  reason_code TEXT NOT NULL,
  reason_text TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_account_deletion_reasons_created
  ON account_deletion_reasons(created_at DESC);

ALTER TABLE account_deletion_reasons ENABLE ROW LEVEL SECURITY;

-- Nobody reads this directly from the client — only the deletion
-- RPC inserts into it, and an admin can read via service_role.
DROP POLICY IF EXISTS "deletion_no_select" ON account_deletion_reasons;
CREATE POLICY "deletion_no_select"
  ON account_deletion_reasons FOR SELECT
  USING (false);

DROP POLICY IF EXISTS "deletion_no_client_writes" ON account_deletion_reasons;
CREATE POLICY "deletion_no_client_writes"
  ON account_deletion_reasons FOR INSERT
  WITH CHECK (false);

-- 2. The RPC — logs the reason, then drops the auth.users row.
--    Everything downstream cascades because the FKs from profiles
--    / bookings / messages already reference auth.users(id) with
--    ON DELETE CASCADE (set up in migration 001 + later).
CREATE OR REPLACE FUNCTION delete_my_account(
  p_reason_code TEXT,
  p_reason_text TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid   UUID := auth.uid();
  v_email TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;
  IF p_reason_code IS NULL OR length(trim(p_reason_code)) = 0 THEN
    RAISE EXCEPTION 'reason_code required';
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = v_uid;

  INSERT INTO account_deletion_reasons (
    user_id, user_email, reason_code, reason_text
  ) VALUES (
    v_uid, v_email, p_reason_code, p_reason_text
  );

  -- Drop the auth.users row. ON DELETE CASCADE on profiles + all
  -- the FKs we own takes the rest of the data with it.
  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

REVOKE EXECUTE ON FUNCTION delete_my_account(TEXT, TEXT) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION delete_my_account(TEXT, TEXT) TO authenticated;

-- 3. Sanity check.
SELECT
  (SELECT EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'account_deletion_reasons')) AS table_present,
  (SELECT EXISTS(SELECT 1 FROM pg_proc   WHERE proname   = 'delete_my_account'))        AS rpc_present;
