-- =============================================
-- PRO_EMAILS.sql
-- Professional email templates + flows for:
--   1) Signup verification (replaces the simple template in
--      request_signup with a branded one)
--   2) Password reset via OTP (new flow with request_password_reset /
--      verify_password_reset RPCs)
--   3) Post-change confirmation (informational, no code) sent
--      automatically whenever auth.users.encrypted_password changes
--
-- All three use a shared helper send_atrio_email() that wraps the HTML
-- body in the same branded shell (Atrio isologo + lime accent + footer)
-- and POSTs through Brevo using the key stored in app_secrets.
--
-- Logo is fetched from GitHub raw — same asset the app ships with so
-- it stays in sync with brand updates.
--
-- Idempotent.
-- =============================================

-- ─── 1. Helper: wraps content in the branded email shell ──────────
DROP FUNCTION IF EXISTS atrio_email_shell(TEXT, TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION atrio_email_shell(
  p_preheader TEXT,
  p_heading   TEXT,
  p_body_html TEXT,
  p_cta_label TEXT DEFAULT NULL
)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CONCAT(
    '<!doctype html>',
    '<html lang="es">',
    '<head>',
      '<meta charset="utf-8">',
      '<meta name="viewport" content="width=device-width,initial-scale=1">',
      '<meta name="color-scheme" content="light only">',
      '<meta name="supported-color-schemes" content="light only">',
      '<title>Atrio</title>',
    '</head>',
    '<body style="margin:0;padding:0;background:#f4f4f4;font-family:-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;color:#0a0a0a;">',
      -- Preheader: hidden but appears in mail client preview
      '<div style="display:none;font-size:1px;color:#f4f4f4;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">',
        p_preheader,
      '</div>',
      '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f4f4f4;padding:32px 16px;">',
        '<tr><td align="center">',
          '<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.04);">',
            -- Top lime stripe
            '<tr><td style="background:#D4FF00;height:6px;line-height:6px;font-size:6px;">&nbsp;</td></tr>',
            -- Logo
            '<tr><td align="center" style="padding:40px 32px 12px;">',
              '<img src="https://raw.githubusercontent.com/emilianopaezr/Atrio-Repositorio/main/assets/images/isotipo_atrio_negro.png" alt="Atrio" width="120" style="display:block;width:120px;max-width:60%;height:auto;border:0;">',
            '</td></tr>',
            -- Heading
            '<tr><td align="center" style="padding:0 32px;">',
              '<h1 style="margin:24px 0 8px;font-size:24px;font-weight:800;letter-spacing:-0.6px;color:#0a0a0a;line-height:1.25;">',
                p_heading,
              '</h1>',
            '</td></tr>',
            -- Body content (HTML inserted as-is)
            '<tr><td style="padding:8px 40px 32px;font-size:15px;line-height:1.6;color:#3a3a3a;">',
              p_body_html,
            '</td></tr>',
            -- Footer card
            '<tr><td style="background:#fafafa;padding:24px 40px;border-top:1px solid #ececec;">',
              '<p style="margin:0;font-size:12px;line-height:1.55;color:#7a7a7a;text-align:center;">',
                '¿No solicitaste este email? Puedes ignorarlo con seguridad.<br>',
                'Tu cuenta de Atrio sigue protegida.',
              '</p>',
              '<p style="margin:14px 0 0;font-size:11px;line-height:1.5;color:#9a9a9a;text-align:center;letter-spacing:0.4px;">',
                'ATRIO · Marketplace premium de espacios, experiencias y servicios<br>',
                '<a href="mailto:contacto@atriocompany.cloud" style="color:#9a9a9a;text-decoration:underline;">contacto@atriocompany.cloud</a>',
              '</p>',
            '</td></tr>',
          '</table>',
          -- Bottom outside text
          '<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;width:100%;">',
            '<tr><td align="center" style="padding:14px 0 0;font-size:11px;color:#9a9a9a;">',
              '© Atrio Company',
            '</td></tr>',
          '</table>',
        '</td></tr>',
      '</table>',
    '</body>',
    '</html>'
  );
$$;

-- ─── 2. Helper: POSTs an email through Brevo, returns the request_id ─
DROP FUNCTION IF EXISTS send_atrio_email(TEXT, TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION send_atrio_email(
  p_to_email TEXT,
  p_to_name  TEXT,
  p_subject  TEXT,
  p_html     TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_api_key TEXT;
  v_request_id BIGINT;
BEGIN
  SELECT value INTO v_api_key FROM app_secrets WHERE key = 'brevo_api_key';
  IF v_api_key IS NULL OR v_api_key = 'PLACEHOLDER_SET_VIA_ADMIN' THEN
    RAISE EXCEPTION 'Brevo API key not configured';
  END IF;

  v_request_id := net.http_post(
    url := 'https://api.brevo.com/v3/smtp/email',
    headers := jsonb_build_object(
      'api-key', v_api_key,
      'Content-Type', 'application/json',
      'Accept', 'application/json'
    ),
    body := jsonb_build_object(
      'sender', jsonb_build_object(
        'name', 'Atrio',
        'email', 'contacto@atriocompany.cloud'
      ),
      'to', jsonb_build_array(
        jsonb_build_object('email', LOWER(p_to_email), 'name', COALESCE(p_to_name, p_to_email))
      ),
      'subject', p_subject,
      'htmlContent', p_html
    )
  );

  RETURN v_request_id;
END;
$$;

-- ─── 3. Rebuild request_signup with the branded template ──────────
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
  v_request_id BIGINT;
  v_response RECORD;
  v_attempts INT;
  v_recent INT;
  v_html TEXT;
BEGIN
  IF p_email IS NULL OR p_email !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
    RAISE EXCEPTION 'Invalid email format';
  END IF;
  IF p_password IS NULL OR LENGTH(p_password) < 8 THEN
    RAISE EXCEPTION 'Password must be at least 8 characters';
  END IF;
  IF p_name IS NULL OR LENGTH(TRIM(p_name)) < 2 THEN
    RAISE EXCEPTION 'Name must be at least 2 characters';
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE email = LOWER(p_email)) THEN
    RAISE EXCEPTION 'Email already registered';
  END IF;

  SELECT attempts INTO v_recent
  FROM pending_signups
  WHERE email = LOWER(p_email)
    AND updated_at > NOW() - INTERVAL '10 minutes';
  IF v_recent IS NOT NULL AND v_recent >= 3 THEN
    RAISE EXCEPTION 'Too many attempts. Wait 10 minutes.';
  END IF;

  v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
  v_hash := extensions.crypt(p_password, extensions.gen_salt('bf', 10));

  v_html := atrio_email_shell(
    p_preheader := 'Tu código de verificación de Atrio',
    p_heading   := 'Verifica tu email',
    p_body_html := CONCAT(
      '<p style="margin:0 0 16px;">Hola <strong>', p_name, '</strong>,</p>',
      '<p style="margin:0 0 24px;">Para terminar de crear tu cuenta, ingresa este código en la app:</p>',
      '<div style="background:#0a0a0a;border-radius:14px;padding:24px;text-align:center;margin:24px 0;">',
        '<div style="font-size:36px;font-weight:800;letter-spacing:14px;color:#D4FF00;font-family:''Courier New'',monospace;line-height:1;">',
          v_code,
        '</div>',
        '<p style="margin:14px 0 0;font-size:12px;color:rgba(255,255,255,0.55);letter-spacing:1.2px;text-transform:uppercase;">',
          'Código de verificación',
        '</p>',
      '</div>',
      '<p style="margin:24px 0 0;font-size:13px;color:#7a7a7a;">El código expira en 15 minutos. Si no solicitaste este registro, ignora este mensaje.</p>'
    )
  );

  v_request_id := send_atrio_email(
    LOWER(p_email),
    p_name,
    'Verifica tu email · Atrio',
    v_html
  );

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

  -- Wait briefly so we can surface 401 / 4xx without lying to the client.
  v_attempts := 0;
  LOOP
    SELECT status_code, content::text AS body INTO v_response
    FROM net._http_response WHERE id = v_request_id;
    EXIT WHEN v_response.status_code IS NOT NULL OR v_attempts >= 16;
    v_attempts := v_attempts + 1;
    PERFORM pg_sleep(0.5);
  END LOOP;

  IF v_response.status_code IS NULL THEN
    RETURN jsonb_build_object('ok', true, 'status', 'pending', 'request_id', v_request_id);
  END IF;

  IF v_response.status_code BETWEEN 200 AND 299 THEN
    RETURN jsonb_build_object('ok', true, 'status', v_response.status_code);
  END IF;

  RAISE EXCEPTION 'Brevo error %: %', v_response.status_code,
    left(coalesce(v_response.body, '(no body)'), 400);
END;
$$;
GRANT EXECUTE ON FUNCTION request_signup(TEXT, TEXT, TEXT) TO anon, authenticated;

-- ─── 4. Password reset OTP storage ────────────────────────────────
CREATE TABLE IF NOT EXISTS password_reset_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  attempts INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reset_codes_user ON password_reset_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_reset_codes_expires ON password_reset_codes(expires_at);

ALTER TABLE password_reset_codes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "No direct access to password_reset_codes" ON password_reset_codes;
CREATE POLICY "No direct access to password_reset_codes"
  ON password_reset_codes FOR ALL
  TO authenticated, anon
  USING (false);

-- ─── 5. request_password_reset(email) ─────────────────────────────
DROP FUNCTION IF EXISTS request_password_reset(TEXT);
CREATE OR REPLACE FUNCTION request_password_reset(p_email TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user RECORD;
  v_code TEXT;
  v_html TEXT;
  v_request_id BIGINT;
  v_recent INT;
BEGIN
  IF p_email IS NULL OR p_email !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
    RAISE EXCEPTION 'Invalid email format';
  END IF;

  -- Lookup user. We return the same response whether the email exists
  -- or not, so the endpoint can't be used to enumerate accounts.
  SELECT u.id, u.email, COALESCE(p.display_name, split_part(u.email, '@', 1)) AS name
    INTO v_user
    FROM auth.users u
    LEFT JOIN profiles p ON p.id = u.id
    WHERE u.email = LOWER(p_email);

  IF v_user.id IS NULL THEN
    -- Pretend success — no email sent, no error revealed.
    RETURN jsonb_build_object('ok', true, 'status', 'masked');
  END IF;

  -- Per-user rate limit: max 3 in 10 min
  SELECT COUNT(*) INTO v_recent
  FROM password_reset_codes
  WHERE user_id = v_user.id AND created_at > NOW() - INTERVAL '10 minutes';
  IF v_recent >= 3 THEN
    RAISE EXCEPTION 'Too many attempts. Wait 10 minutes.';
  END IF;

  v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

  -- Invalidate old codes for this user
  UPDATE password_reset_codes SET used = TRUE
    WHERE user_id = v_user.id AND used = FALSE;

  INSERT INTO password_reset_codes (user_id, code, expires_at)
  VALUES (v_user.id, v_code, NOW() + INTERVAL '15 minutes');

  v_html := atrio_email_shell(
    p_preheader := 'Restablece tu contraseña de Atrio',
    p_heading   := 'Restablece tu contraseña',
    p_body_html := CONCAT(
      '<p style="margin:0 0 16px;">Hola <strong>', v_user.name, '</strong>,</p>',
      '<p style="margin:0 0 24px;">Recibimos una solicitud para cambiar la contraseña de tu cuenta. Ingresa este código en la app para continuar:</p>',
      '<div style="background:#0a0a0a;border-radius:14px;padding:24px;text-align:center;margin:24px 0;">',
        '<div style="font-size:36px;font-weight:800;letter-spacing:14px;color:#D4FF00;font-family:''Courier New'',monospace;line-height:1;">',
          v_code,
        '</div>',
        '<p style="margin:14px 0 0;font-size:12px;color:rgba(255,255,255,0.55);letter-spacing:1.2px;text-transform:uppercase;">',
          'Código de recuperación',
        '</p>',
      '</div>',
      '<p style="margin:24px 0 0;font-size:13px;color:#7a7a7a;">El código expira en 15 minutos. Si no fuiste tú, ignora este email — tu contraseña actual sigue siendo válida.</p>'
    )
  );

  v_request_id := send_atrio_email(
    v_user.email,
    v_user.name,
    'Restablece tu contraseña · Atrio',
    v_html
  );

  RETURN jsonb_build_object('ok', true, 'status', 'sent', 'request_id', v_request_id);
END;
$$;
GRANT EXECUTE ON FUNCTION request_password_reset(TEXT) TO anon, authenticated;

-- ─── 6. verify_password_reset(email, code, new_password) ──────────
DROP FUNCTION IF EXISTS verify_password_reset(TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION verify_password_reset(
  p_email TEXT,
  p_code TEXT,
  p_new_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_code_id UUID;
  v_hash TEXT;
BEGIN
  IF p_code IS NULL OR LENGTH(p_code) != 6 OR p_code !~ '^\d{6}$' THEN
    RAISE EXCEPTION 'Invalid code format';
  END IF;
  IF p_new_password IS NULL OR LENGTH(p_new_password) < 8 THEN
    RAISE EXCEPTION 'Password must be at least 8 characters';
  END IF;

  SELECT id INTO v_user_id FROM auth.users WHERE email = LOWER(p_email);
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Invalid code';  -- same error as wrong code → no enumeration
  END IF;

  -- Find valid code
  SELECT id INTO v_code_id
  FROM password_reset_codes
  WHERE user_id = v_user_id
    AND code = p_code
    AND used = FALSE
    AND expires_at > NOW()
  ORDER BY created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF v_code_id IS NULL THEN
    UPDATE password_reset_codes SET attempts = attempts + 1
      WHERE user_id = v_user_id AND used = FALSE;
    RAISE EXCEPTION 'Invalid code';
  END IF;

  -- Mark code used
  UPDATE password_reset_codes SET used = TRUE WHERE id = v_code_id;

  -- Hash + update password
  v_hash := extensions.crypt(p_new_password, extensions.gen_salt('bf', 10));
  UPDATE auth.users
  SET encrypted_password = v_hash, updated_at = NOW()
  WHERE id = v_user_id;
  -- (The trigger from §7 will fire the confirmation email automatically.)

  RETURN jsonb_build_object('ok', true);
END;
$$;
GRANT EXECUTE ON FUNCTION verify_password_reset(TEXT, TEXT, TEXT) TO anon, authenticated;

-- ─── 7. Trigger: send confirmation email on any password change ───
DROP FUNCTION IF EXISTS notify_password_changed();
CREATE OR REPLACE FUNCTION notify_password_changed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_name TEXT;
  v_html TEXT;
BEGIN
  -- Only fire when the password actually changed
  IF NEW.encrypted_password IS NOT DISTINCT FROM OLD.encrypted_password THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(display_name, split_part(NEW.email, '@', 1))
    INTO v_name
    FROM profiles WHERE id = NEW.id;
  v_name := COALESCE(v_name, split_part(NEW.email, '@', 1));

  v_html := atrio_email_shell(
    p_preheader := 'Tu contraseña de Atrio fue actualizada',
    p_heading   := 'Contraseña actualizada',
    p_body_html := CONCAT(
      '<p style="margin:0 0 16px;">Hola <strong>', v_name, '</strong>,</p>',
      '<p style="margin:0 0 16px;">Te confirmamos que la contraseña de tu cuenta de Atrio fue actualizada con éxito.</p>',
      '<div style="background:#f8f8f8;border-radius:12px;padding:18px;margin:24px 0;font-size:13px;color:#3a3a3a;">',
        '<strong style="display:block;margin-bottom:6px;color:#0a0a0a;">¿Fuiste tú?</strong>',
        'Genial, ya puedes iniciar sesión con tu nueva contraseña.',
      '</div>',
      '<div style="background:#fff4f4;border:1px solid #ffd5d5;border-radius:12px;padding:18px;margin:16px 0;font-size:13px;color:#a02525;">',
        '<strong style="display:block;margin-bottom:6px;color:#7a1414;">¿No fuiste tú?</strong>',
        'Tu cuenta puede estar comprometida. Escríbenos inmediatamente a ',
        '<a href="mailto:contacto@atriocompany.cloud" style="color:#a02525;font-weight:700;">contacto@atriocompany.cloud</a>',
        ' y cambia tu contraseña de nuevo.',
      '</div>',
      '<p style="margin:24px 0 0;font-size:12px;color:#9a9a9a;">Recibiste este email porque alguien (¿tú?) cambió la contraseña asociada a ', NEW.email, '.</p>'
    )
  );

  PERFORM send_atrio_email(
    NEW.email,
    v_name,
    'Contraseña actualizada · Atrio',
    v_html
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_password_changed ON auth.users;
CREATE TRIGGER trg_notify_password_changed
AFTER UPDATE OF encrypted_password ON auth.users
FOR EACH ROW
EXECUTE FUNCTION notify_password_changed();

-- ─── 8. Final verification — all artefacts present ────────────────
SELECT
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'atrio_email_shell')        AS shell_helper,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'send_atrio_email')         AS send_helper,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'request_signup')            AS signup_rpc,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'request_password_reset')    AS reset_request_rpc,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'verify_password_reset')     AS reset_verify_rpc,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'notify_password_changed')   AS notify_fn,
  (SELECT COUNT(*) FROM pg_tables WHERE tablename = 'password_reset_codes')  AS reset_table,
  (SELECT COUNT(*) FROM pg_trigger WHERE tgname = 'trg_notify_password_changed') AS trigger_active;
