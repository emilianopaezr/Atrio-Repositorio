-- =============================================
-- EMAILS_MINIMAL.sql
-- Professional minimalist email redesign.
--
-- Changes vs previous shell:
--   • Drop the lime stripe at the top — too loud for this layout.
--   • Drop the "ATRIO · Marketplace premium" footer eyebrow text —
--     the brand is communicated entirely through the isologo image,
--     never spelled out in body copy.
--   • White card on a soft off-white page background, no border. The
--     shadow alone separates it.
--   • Code container is now WHITE with a thin gray border, black
--     monospace code, lime accent reduced to a 2-pixel underline.
--   • Heading 28px (was 30), tighter line-height.
--
-- Updates the shell + both body templates (request_signup,
-- request_password_reset) + the password-changed trigger.
-- Idempotent.
-- =============================================

-- ─── 1. Minimal shell ──────────────────────────────────────────────
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
      '<link rel="preconnect" href="https://fonts.googleapis.com">',
      '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>',
      '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">',
      '<style>',
        'body{margin:0;padding:0;width:100%!important;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;}',
        'table{border-collapse:collapse!important;}',
        'img{border:0;outline:none;text-decoration:none;-ms-interpolation-mode:bicubic;}',
        '.atrio-body,.atrio-body *{font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif!important;}',
        '@media only screen and (max-width:520px){',
          '.atrio-card{border-radius:0!important;}',
          '.atrio-pad{padding-left:28px!important;padding-right:28px!important;}',
          '.atrio-code{font-size:30px!important;letter-spacing:8px!important;}',
        '}',
      '</style>',
    '</head>',
    '<body class="atrio-body" style="margin:0;padding:0;background:#f6f6f5;color:#0a0a0a;">',
      '<div style="display:none;font-size:1px;color:#f6f6f5;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">',
        p_preheader,
      '</div>',
      '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f6f6f5;padding:56px 16px;">',
        '<tr><td align="center">',
          '<table role="presentation" width="560" class="atrio-card" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;width:100%;background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 1px 2px rgba(10,10,10,0.04),0 12px 40px rgba(10,10,10,0.06);">',
            -- Isologo block (more breathing room, no eyebrow, no stripe)
            '<tr><td align="center" class="atrio-pad" style="padding:56px 48px 8px;">',
              '<img src="https://raw.githubusercontent.com/emilianopaezr/Atrio-Repositorio/main/assets/images/isotipo_atrio_negro.png" alt="" width="112" style="display:block;width:112px;max-width:50%;height:auto;border:0;">',
            '</td></tr>',
            -- Heading
            '<tr><td align="center" class="atrio-pad" style="padding:0 48px;">',
              '<h1 style="margin:36px 0 6px;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:26px;font-weight:700;letter-spacing:-0.6px;color:#0a0a0a;line-height:1.2;">',
                p_heading,
              '</h1>',
            '</td></tr>',
            -- Body
            '<tr><td class="atrio-pad" style="padding:14px 56px 48px;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:15px;font-weight:400;line-height:1.65;color:#3a3a3a;letter-spacing:-0.05px;">',
              p_body_html,
            '</td></tr>',
          '</table>',
          -- Footer (outside the card, even smaller)
          '<table role="presentation" width="560" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;width:100%;">',
            '<tr><td align="center" style="padding:24px 24px 0;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:12px;font-weight:400;color:#9a9a9a;line-height:1.6;letter-spacing:-0.05px;">',
              'Si no solicitaste este email puedes ignorarlo con seguridad.',
            '</td></tr>',
            '<tr><td align="center" style="padding:12px 24px 0;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:11px;font-weight:500;color:#b5b5b5;letter-spacing:-0.05px;">',
              '<a href="mailto:contacto@atriocompany.cloud" style="color:#9a9a9a;text-decoration:none;">contacto@atriocompany.cloud</a>',
              '<span style="color:#d0d0d0;"> · </span>',
              '© Atrio Company',
            '</td></tr>',
          '</table>',
        '</td></tr>',
      '</table>',
    '</body>',
    '</html>'
  );
$$;

-- ─── 2. Helper: reusable white code-box markup ────────────────────
-- White background, thin gray border, big monospaced digits in black,
-- a 2px lime underline below the code (the only color accent), small
-- label in gray.
DROP FUNCTION IF EXISTS atrio_code_box(TEXT, TEXT);
CREATE OR REPLACE FUNCTION atrio_code_box(p_code TEXT, p_label TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CONCAT(
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:28px 0;">',
      '<tr><td align="center">',
        '<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="background:#ffffff;border:1px solid #e8e8e8;border-radius:14px;">',
          '<tr><td align="center" style="padding:26px 36px 18px;">',
            '<div class="atrio-code" style="font-family:''SF Mono'',''Menlo'',''Consolas'',''Courier New'',monospace;font-size:38px;font-weight:600;letter-spacing:12px;color:#0a0a0a;line-height:1;padding-right:0;">',
              p_code,
            '</div>',
            '<div style="height:2px;width:42px;background:#D4FF00;margin:14px auto 0;line-height:2px;font-size:2px;">&nbsp;</div>',
            '<div style="margin-top:14px;font-family:''Inter'',-apple-system,BlinkMacSystemFont,''Segoe UI'',Roboto,Helvetica,Arial,sans-serif;font-size:11px;font-weight:600;color:#9a9a9a;letter-spacing:1.2px;text-transform:uppercase;">',
              p_label,
            '</div>',
          '</td></tr>',
        '</table>',
      '</td></tr>',
    '</table>'
  );
$$;

-- ─── 3. Rebuild request_signup using the new boxes ────────────────
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

  SELECT attempts INTO v_recent FROM pending_signups
    WHERE email = LOWER(p_email)
      AND updated_at > NOW() - INTERVAL '10 minutes';
  IF v_recent IS NOT NULL AND v_recent >= 3 THEN
    RAISE EXCEPTION 'Too many attempts. Wait 10 minutes.';
  END IF;

  v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
  v_hash := extensions.crypt(p_password, extensions.gen_salt('bf', 10));

  v_html := atrio_email_shell(
    p_preheader := 'Tu código de verificación',
    p_heading   := 'Verifica tu email',
    p_body_html := CONCAT(
      '<p style="margin:0 0 8px;">Hola ', p_name, ',</p>',
      '<p style="margin:0;">Para terminar de crear tu cuenta, ingresa este código en la app.</p>',
      atrio_code_box(v_code, 'Código de verificación'),
      '<p style="margin:0;font-size:13px;color:#8a8a8a;">El código expira en 15 minutos.</p>'
    )
  );

  v_request_id := send_atrio_email(
    LOWER(p_email), p_name, 'Verifica tu email · Atrio', v_html
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

  RETURN jsonb_build_object('ok', true, 'status', 'queued', 'request_id', v_request_id);
END;
$$;
GRANT EXECUTE ON FUNCTION request_signup(TEXT, TEXT, TEXT) TO anon, authenticated;

-- ─── 4. Rebuild request_password_reset with the new boxes ─────────
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

  SELECT u.id, u.email, COALESCE(p.display_name, split_part(u.email, '@', 1)) AS name
    INTO v_user
    FROM auth.users u
    LEFT JOIN profiles p ON p.id = u.id
    WHERE u.email = LOWER(p_email);

  IF v_user.id IS NULL THEN
    RETURN jsonb_build_object('ok', true, 'status', 'masked');
  END IF;

  SELECT COUNT(*) INTO v_recent
  FROM password_reset_codes
  WHERE user_id = v_user.id AND created_at > NOW() - INTERVAL '10 minutes';
  IF v_recent >= 3 THEN
    RAISE EXCEPTION 'Too many attempts. Wait 10 minutes.';
  END IF;

  v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

  UPDATE password_reset_codes SET used = TRUE
    WHERE user_id = v_user.id AND used = FALSE;

  INSERT INTO password_reset_codes (user_id, code, expires_at)
  VALUES (v_user.id, v_code, NOW() + INTERVAL '15 minutes');

  v_html := atrio_email_shell(
    p_preheader := 'Restablece tu contraseña',
    p_heading   := 'Restablece tu contraseña',
    p_body_html := CONCAT(
      '<p style="margin:0 0 8px;">Hola ', v_user.name, ',</p>',
      '<p style="margin:0;">Recibimos una solicitud para cambiar tu contraseña. Ingresa este código en la app para continuar.</p>',
      atrio_code_box(v_code, 'Código de recuperación'),
      '<p style="margin:0;font-size:13px;color:#8a8a8a;">El código expira en 15 minutos. Si no fuiste tú, ignora este email — tu contraseña actual sigue siendo válida.</p>'
    )
  );

  v_request_id := send_atrio_email(
    v_user.email, v_user.name,
    'Restablece tu contraseña · Atrio',
    v_html
  );

  RETURN jsonb_build_object('ok', true, 'status', 'sent', 'request_id', v_request_id);
END;
$$;
GRANT EXECUTE ON FUNCTION request_password_reset(TEXT) TO anon, authenticated;

-- ─── 5. Rebuild notify_password_changed with the same minimal style ─
DROP FUNCTION IF EXISTS notify_password_changed() CASCADE;
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
  IF NEW.encrypted_password IS NOT DISTINCT FROM OLD.encrypted_password THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(display_name, split_part(NEW.email, '@', 1))
    INTO v_name
    FROM profiles WHERE id = NEW.id;
  v_name := COALESCE(v_name, split_part(NEW.email, '@', 1));

  v_html := atrio_email_shell(
    p_preheader := 'Tu contraseña fue actualizada',
    p_heading   := 'Contraseña actualizada',
    p_body_html := CONCAT(
      '<p style="margin:0 0 8px;">Hola ', v_name, ',</p>',
      '<p style="margin:0 0 20px;">Te confirmamos que la contraseña de tu cuenta fue actualizada con éxito.</p>',
      '<div style="background:#fafafa;border-radius:12px;padding:18px 20px;margin:0 0 12px;font-size:13.5px;color:#3a3a3a;line-height:1.55;">',
        '<strong style="display:block;margin-bottom:4px;color:#0a0a0a;font-weight:600;">¿Fuiste tú?</strong>',
        'Ya puedes iniciar sesión con tu nueva contraseña.',
      '</div>',
      '<div style="background:#fff8f8;border:1px solid #ffdada;border-radius:12px;padding:18px 20px;font-size:13px;color:#a02525;line-height:1.55;">',
        '<strong style="display:block;margin-bottom:4px;color:#7a1414;font-weight:600;">¿No fuiste tú?</strong>',
        'Tu cuenta puede estar comprometida. Escríbenos a ',
        '<a href="mailto:contacto@atriocompany.cloud" style="color:#7a1414;font-weight:600;">contacto@atriocompany.cloud</a>',
        ' y cambia tu contraseña.',
      '</div>'
    )
  );

  PERFORM send_atrio_email(
    NEW.email, v_name,
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

-- ─── 6. Verification ─────────────────────────────────────────────
SELECT
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'atrio_email_shell')      AS shell,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'atrio_code_box')         AS code_box,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'request_signup')         AS signup,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'request_password_reset') AS reset,
  (SELECT COUNT(*) FROM pg_proc WHERE proname = 'notify_password_changed') AS notify;
