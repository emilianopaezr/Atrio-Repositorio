-- =============================================
-- FIX_EMAIL_LOGGING.sql
-- Patch request_verification() to:
--   1) Log the Brevo response_id so we can debug failures.
--   2) Wait briefly for the HTTP response and surface failures as a
--      proper RAISE EXCEPTION (the client currently shows
--      "No se pudo enviar el código" generically — this gives us a
--      reason in the Postgres log).
--   3) Store the request_id in otp_codes so we can correlate later.
-- Idempotent: re-running just replaces the function.
-- =============================================

-- 1. Add brevo_request_id column if missing (idempotent).
ALTER TABLE otp_codes
  ADD COLUMN IF NOT EXISTS brevo_request_id BIGINT;

-- 2. Rewrite the function with response inspection.
CREATE OR REPLACE FUNCTION request_verification()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_email TEXT;
  v_display_name TEXT;
  v_code TEXT;
  v_api_key TEXT;
  v_request_id BIGINT;
  v_recent_count INT;
  v_response RECORD;
  v_attempts INT;
BEGIN
  -- 1. Auth
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 2. Rate limit: 3 per 10 min
  SELECT COUNT(*) INTO v_recent_count
  FROM otp_codes
  WHERE user_id = v_user_id
    AND created_at > NOW() - INTERVAL '10 minutes';
  IF v_recent_count >= 3 THEN
    RAISE EXCEPTION 'Too many verification requests. Wait a few minutes.';
  END IF;

  -- 3. Email
  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;
  IF v_email IS NULL THEN
    RAISE EXCEPTION 'No email found for user';
  END IF;

  SELECT COALESCE(display_name, split_part(v_email, '@', 1))
    INTO v_display_name
    FROM profiles WHERE id = v_user_id;
  v_display_name := COALESCE(v_display_name, split_part(v_email, '@', 1));

  -- 4. Code
  v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

  UPDATE otp_codes SET used = TRUE
    WHERE user_id = v_user_id AND used = FALSE;

  -- 5. API key
  SELECT value INTO v_api_key FROM app_secrets WHERE key = 'brevo_api_key';
  IF v_api_key IS NULL OR v_api_key = 'PLACEHOLDER_SET_VIA_ADMIN' THEN
    RAISE EXCEPTION 'Brevo API key not configured. Insert via: INSERT INTO app_secrets (key, value) VALUES (''brevo_api_key'', ''<your-key>'') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;';
  END IF;

  -- 6. Brevo HTTP request
  SELECT id INTO v_request_id
  FROM net.http_post(
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
        jsonb_build_object('email', v_email, 'name', v_display_name)
      ),
      'subject', 'Tu código de verificación - Atrio',
      'htmlContent', CONCAT(
        '<div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:32px;">',
          '<div style="text-align:center;margin-bottom:32px;">',
            '<h1 style="color:#1a1a1a;font-size:28px;margin:0;">ATRIO</h1>',
            '<p style="color:#666;font-size:14px;margin-top:4px;">Premium Marketplace</p>',
          '</div>',
          '<div style="background:#f8f8f8;border-radius:12px;padding:32px;text-align:center;">',
            '<p style="color:#333;font-size:16px;margin:0 0 8px;">Hola ', v_display_name, ',</p>',
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

  -- 7. Persist code WITH the request_id so we can later correlate it
  --    with the Brevo response in net._http_response.
  INSERT INTO otp_codes (user_id, code, expires_at, brevo_request_id)
  VALUES (v_user_id, v_code, NOW() + INTERVAL '15 minutes', v_request_id);

  -- 8. Poll briefly for the Brevo response (≤ 5s). pg_net is async, so
  --    we have to wait for the row to appear in net._http_response.
  v_attempts := 0;
  LOOP
    SELECT status_code, content::text AS body
      INTO v_response
      FROM net._http_response
      WHERE id = v_request_id;

    IF v_response.status_code IS NOT NULL THEN
      EXIT;
    END IF;

    v_attempts := v_attempts + 1;
    IF v_attempts >= 10 THEN
      -- Timed out waiting for Brevo. Don't fail hard — Brevo MAY still
      -- deliver. Return a warning so the client can show it.
      RETURN jsonb_build_object(
        'ok', false,
        'reason', 'brevo_timeout',
        'request_id', v_request_id
      );
    END IF;

    PERFORM pg_sleep(0.5);
  END LOOP;

  -- 9. Inspect Brevo response. 201 Created = success.
  IF v_response.status_code BETWEEN 200 AND 299 THEN
    RETURN jsonb_build_object(
      'ok', true,
      'status', v_response.status_code,
      'request_id', v_request_id
    );
  END IF;

  -- Brevo returned an error — surface it so the client can show a real
  -- message and so we can see it in postgres logs.
  RAISE EXCEPTION 'Brevo error %: %', v_response.status_code,
    left(coalesce(v_response.body, '(no body)'), 400);
END;
$$;

GRANT EXECUTE ON FUNCTION request_verification() TO authenticated;
