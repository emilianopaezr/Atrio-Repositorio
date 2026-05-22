-- =============================================
-- STRICT_SIGNUP.sql
-- Deferred-account-creation flow: auth.users only gets a row AFTER
-- the email OTP is verified. No more orphan accounts.
--
-- Architecture:
--   1) Client → request_signup(email, name, password)
--      → row in pending_signups + OTP email via Brevo
--   2) Client → verify_signup(email, code)
--      → atomically INSERT into auth.users, INSERT profile,
--        DELETE pending row, return user_id
--      Client then signInWithPassword(email, password) to get a session.
--   3) Daily cron drops pending_signups older than 1 hour.
--
-- Idempotent.
-- =============================================

-- 1. Required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- for bcrypt hashing
CREATE EXTENSION IF NOT EXISTS pg_net;    -- for Brevo HTTP calls

-- 2. pending_signups table
CREATE TABLE IF NOT EXISTS pending_signups (
  email TEXT PRIMARY KEY,
  display_name TEXT,
  password_hash TEXT NOT NULL,         -- bcrypt hash; Supabase-compatible
  otp_code TEXT NOT NULL,
  otp_expires_at TIMESTAMPTZ NOT NULL,
  brevo_request_id BIGINT,
  attempts INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pending_signups_expires
  ON pending_signups(otp_expires_at);

ALTER TABLE pending_signups ENABLE ROW LEVEL SECURITY;

-- Nobody can read this table directly — all access via SECURITY DEFINER functions.
DROP POLICY IF EXISTS "No direct access to pending_signups" ON pending_signups;
CREATE POLICY "No direct access to pending_signups"
  ON pending_signups FOR ALL
  TO authenticated, anon
  USING (false);

-- 3. request_signup(email, name, password) → JSONB
DROP FUNCTION IF EXISTS request_signup(TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION request_signup(
  p_email TEXT,
  p_name TEXT,
  p_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code TEXT;
  v_hash TEXT;
  v_api_key TEXT;
  v_request_id BIGINT;
  v_response RECORD;
  v_attempts INT;
  v_recent INT;
BEGIN
  -- Basic validation
  IF p_email IS NULL OR p_email !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
    RAISE EXCEPTION 'Invalid email format';
  END IF;
  IF p_password IS NULL OR LENGTH(p_password) < 8 THEN
    RAISE EXCEPTION 'Password must be at least 8 characters';
  END IF;
  IF p_name IS NULL OR LENGTH(TRIM(p_name)) < 2 THEN
    RAISE EXCEPTION 'Name must be at least 2 characters';
  END IF;

  -- Refuse if a real account already exists with this email
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = LOWER(p_email)) THEN
    RAISE EXCEPTION 'Email already registered';
  END IF;

  -- Per-email rate limit: max 3 attempts in 10 min
  SELECT attempts INTO v_recent
  FROM pending_signups
  WHERE email = LOWER(p_email)
    AND updated_at > NOW() - INTERVAL '10 minutes';
  IF v_recent IS NOT NULL AND v_recent >= 3 THEN
    RAISE EXCEPTION 'Too many attempts. Wait 10 minutes.';
  END IF;

  -- Generate OTP + hash password (bcrypt cost 10 — same as Supabase default).
  -- pgcrypto lives in the `extensions` schema in Supabase, so we have to
  -- qualify the calls — `search_path = public` on this function would
  -- otherwise miss them.
  v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
  v_hash := extensions.crypt(p_password, extensions.gen_salt('bf', 10));

  -- Get Brevo key
  SELECT value INTO v_api_key FROM app_secrets WHERE key = 'brevo_api_key';
  IF v_api_key IS NULL OR v_api_key = 'PLACEHOLDER_SET_VIA_ADMIN' THEN
    RAISE EXCEPTION 'Brevo API key not configured';
  END IF;

  -- Send OTP email. pg_net's net.http_post returns the request id as a
  -- bigint directly — using SELECT id FROM net.http_post(...) fails on
  -- some installs because there's no row, just a scalar.
  v_request_id := net.http_post(
    url := 'https://api.brevo.com/v3/smtp/email',
    headers := jsonb_build_object(
      'api-key', v_api_key,
      'Content-Type', 'application/json',
      'Accept', 'application/json'
    ),
    body := jsonb_build_object(
      'sender', jsonb_build_object('name', 'Atrio', 'email', 'contacto@atriocompany.cloud'),
      'to', jsonb_build_array(
        jsonb_build_object('email', LOWER(p_email), 'name', p_name)
      ),
      'subject', 'Tu código de verificación - Atrio',
      'htmlContent', CONCAT(
        '<div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px;">',
          '<div style="text-align:center;margin-bottom:32px;">',
            '<h1 style="color:#1a1a1a;font-size:28px;margin:0;">ATRIO</h1>',
            '<p style="color:#666;font-size:14px;margin-top:4px;">Premium Marketplace</p>',
          '</div>',
          '<div style="background:#f8f8f8;border-radius:12px;padding:32px;text-align:center;">',
            '<p style="color:#333;font-size:16px;margin:0 0 8px;">Hola ', p_name, ',</p>',
            '<p style="color:#666;font-size:14px;margin:0 0 24px;">Tu código de verificación es:</p>',
            '<div style="background:#1a1a1a;color:#c8ff00;font-size:36px;font-weight:700;letter-spacing:8px;padding:16px 32px;border-radius:8px;display:inline-block;">',
              v_code,
            '</div>',
            '<p style="color:#999;font-size:12px;margin-top:24px;">Este código expira en 15 minutos.</p>',
          '</div>',
          '<p style="color:#999;font-size:11px;text-align:center;margin-top:24px;">',
            'Si no solicitaste este código, puedes ignorar este email.',
          '</p>',
        '</div>'
      )
    )
  );

  -- Upsert pending signup (overwrite stale data, bump attempts)
  INSERT INTO pending_signups (
    email, display_name, password_hash, otp_code, otp_expires_at,
    brevo_request_id, attempts
  ) VALUES (
    LOWER(p_email), p_name, v_hash, v_code, NOW() + INTERVAL '15 minutes',
    v_request_id, 1
  )
  ON CONFLICT (email) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    password_hash = EXCLUDED.password_hash,
    otp_code = EXCLUDED.otp_code,
    otp_expires_at = EXCLUDED.otp_expires_at,
    brevo_request_id = EXCLUDED.brevo_request_id,
    attempts = COALESCE(pending_signups.attempts, 0) + 1,
    updated_at = NOW();

  -- IMPORTANT: NO polling here. PostgREST applies a short
  -- statement_timeout to the `anon` role (~3s in self-hosted
  -- Supabase), so any pg_sleep inside the function causes the call
  -- to bail with "57014 canceling statement due to statement
  -- timeout" — observed as a generic "no se pudo procesar el
  -- registro" in the app. Fire-and-forget instead: net.http_post
  -- has already queued the request and stored its id; if Brevo
  -- rejects, the next attempt (resend, or another signup) surfaces
  -- the error through net._http_response with a non-blocking
  -- diagnostic query.
  RETURN jsonb_build_object(
    'ok', true,
    'status', 'queued',
    'request_id', v_request_id
  );
END;
$$;

GRANT EXECUTE ON FUNCTION request_signup(TEXT, TEXT, TEXT) TO anon, authenticated;

-- 4. verify_signup(email, code) → creates auth.users + profile, returns user_id
DROP FUNCTION IF EXISTS verify_signup(TEXT, TEXT);
CREATE OR REPLACE FUNCTION verify_signup(
  p_email TEXT,
  p_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pending pending_signups%ROWTYPE;
  v_user_id UUID;
BEGIN
  IF p_code IS NULL OR LENGTH(p_code) != 6 OR p_code !~ '^\d{6}$' THEN
    RAISE EXCEPTION 'Invalid code format';
  END IF;

  -- Lock row to prevent race
  SELECT * INTO v_pending FROM pending_signups
  WHERE email = LOWER(p_email)
  FOR UPDATE;

  IF v_pending IS NULL OR v_pending.email IS NULL THEN
    RAISE EXCEPTION 'No pending signup for this email';
  END IF;

  IF v_pending.otp_expires_at < NOW() THEN
    DELETE FROM pending_signups WHERE email = LOWER(p_email);
    RAISE EXCEPTION 'Code expired';
  END IF;

  IF v_pending.otp_code != p_code THEN
    UPDATE pending_signups SET attempts = attempts + 1, updated_at = NOW()
    WHERE email = LOWER(p_email);
    RAISE EXCEPTION 'Invalid code';
  END IF;

  -- Double check: still no auth.users row for this email
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = LOWER(p_email)) THEN
    DELETE FROM pending_signups WHERE email = LOWER(p_email);
    RAISE EXCEPTION 'Email already registered';
  END IF;

  -- Create auth.users (compatible with Supabase Auth / GoTrue).
  --
  -- Quirks of this schema we have to honour:
  --   • confirmed_at is a generated column (derived from
  --     email_confirmed_at / phone_confirmed_at). Inserting into it
  --     raises 428C9.
  --   • GoTrue scans the token columns as Go strings; NULL values
  --     cause "Database error querying schema" on sign-in. Native
  --     Supabase signups always populate them as empty strings, so
  --     we mirror that here.
  --   • is_super_admin defaults to NULL on Supabase-native rows.
  v_user_id := gen_random_uuid();
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change_token_current,
    reauthentication_token,
    phone_change,
    phone_change_token,
    email_change
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_user_id,
    'authenticated',
    'authenticated',
    v_pending.email,
    v_pending.password_hash,
    NOW(),
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object(
      'display_name', v_pending.display_name,
      'email_verified', true
    ),
    NOW(),
    NOW(),
    false,
    false,
    '', '', '', '', '',
    '', '', ''
  );

  -- Create the identity row that Supabase signin expects (so identities is non-empty)
  INSERT INTO auth.identities (
    id,
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id::text,
    v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', v_pending.email, 'email_verified', true),
    'email',
    NOW(),
    NOW(),
    NOW()
  );

  -- Create profile (also handled by any existing trigger, but explicit is safer)
  INSERT INTO profiles (id, display_name, email_verified, created_at, updated_at)
  VALUES (v_user_id, v_pending.display_name, TRUE, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    email_verified = TRUE,
    updated_at = NOW();

  -- Cleanup
  DELETE FROM pending_signups WHERE email = LOWER(p_email);

  RETURN jsonb_build_object('ok', true, 'user_id', v_user_id);
END;
$$;

GRANT EXECUTE ON FUNCTION verify_signup(TEXT, TEXT) TO anon, authenticated;

-- 5. Cleanup cron — drop expired pending signups every 15 min
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule('atrio-cleanup-pending-signups')
      WHERE EXISTS (
        SELECT 1 FROM cron.job WHERE jobname = 'atrio-cleanup-pending-signups'
      );
    PERFORM cron.schedule(
      'atrio-cleanup-pending-signups',
      '*/15 * * * *',
      $cron$
        DELETE FROM pending_signups
        WHERE otp_expires_at < NOW() - INTERVAL '1 hour';
      $cron$
    );
  END IF;
END $$;

-- 6. Verification — show that everything is in place. Guarded so it
--    doesn't blow up when pg_cron isn't installed (self-hosted Supabase
--    without the extension just won't have cron scheduling — that's OK).
SELECT
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'request_signup') AS request_signup_exists,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'verify_signup')  AS verify_signup_exists,
  (SELECT COUNT(*) FROM pg_tables WHERE tablename = 'pending_signups') AS pending_table_exists,
  (SELECT COUNT(*) FROM pg_extension WHERE extname = 'pg_cron') AS pg_cron_installed;
