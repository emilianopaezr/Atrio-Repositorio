-- =============================================
-- 016: Device Tokens (FCM) for Push Notifications
-- =============================================
-- One user can register multiple devices; each device has a unique FCM token.
-- On logout, the row is deleted so the user stops receiving pushes on that device.

CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  app_version TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_token    ON device_tokens(token);

-- Row-level security: users can only see/modify their own tokens.
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "device_tokens_select_own" ON device_tokens;
CREATE POLICY "device_tokens_select_own"
  ON device_tokens FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "device_tokens_insert_own" ON device_tokens;
CREATE POLICY "device_tokens_insert_own"
  ON device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "device_tokens_update_own" ON device_tokens;
CREATE POLICY "device_tokens_update_own"
  ON device_tokens FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "device_tokens_delete_own" ON device_tokens;
CREATE POLICY "device_tokens_delete_own"
  ON device_tokens FOR DELETE
  USING (auth.uid() = user_id);

-- RPC: upsert a token (used by the app). Attaching uniqueness on `token`
-- means if a device gets reassigned to another user we update user_id.
CREATE OR REPLACE FUNCTION register_device_token(
  p_token TEXT,
  p_platform TEXT,
  p_app_version TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  INSERT INTO device_tokens (user_id, token, platform, app_version)
  VALUES (auth.uid(), p_token, p_platform, p_app_version)
  ON CONFLICT (token) DO UPDATE
    SET user_id     = EXCLUDED.user_id,
        platform    = EXCLUDED.platform,
        app_version = EXCLUDED.app_version,
        updated_at  = NOW();
END;
$func$;

CREATE OR REPLACE FUNCTION unregister_device_token(p_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
BEGIN
  DELETE FROM device_tokens
  WHERE token = p_token
    AND user_id = auth.uid();
END;
$func$;

GRANT EXECUTE ON FUNCTION register_device_token(TEXT, TEXT, TEXT)   TO authenticated;
GRANT EXECUTE ON FUNCTION unregister_device_token(TEXT)             TO authenticated;

-- Touch updated_at automatically on any update.
CREATE OR REPLACE FUNCTION touch_device_tokens_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $func$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$func$;

DROP TRIGGER IF EXISTS trg_device_tokens_updated_at ON device_tokens;
CREATE TRIGGER trg_device_tokens_updated_at
BEFORE UPDATE ON device_tokens
FOR EACH ROW EXECUTE FUNCTION touch_device_tokens_updated_at();

COMMENT ON TABLE  device_tokens IS
  'FCM push tokens per device. One user → many devices. Cleaned on logout.';
COMMENT ON FUNCTION register_device_token IS
  'Upsert the caller''s FCM token. Reassigns token to new user on collision.';
