-- ============================================
-- ATRIO - Email Verification System (OTP via Brevo)
-- Run this SQL in your Supabase SQL Editor
-- ============================================
-- EJECUTAR EN ORDEN: cada bloque separado por comentarios
-- Si un bloque da error, lee el comentario y ajusta.
-- ============================================

-- =============================================
-- PASO 1: Extensión pg_net (para hacer HTTP requests)
-- =============================================
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- =============================================
-- PASO 2: Columna email_verified en profiles
-- =============================================
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;

-- =============================================
-- PASO 3: Tabla OTP codes
-- =============================================
CREATE TABLE IF NOT EXISTS otp_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_otp_codes_user_id ON otp_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_otp_codes_expires ON otp_codes(expires_at);

ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;

-- Drop policy if exists to avoid error on re-run
DROP POLICY IF EXISTS "Users can view own OTP codes" ON otp_codes;
CREATE POLICY "Users can view own OTP codes"
  ON otp_codes FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- =============================================
-- PASO 4: Tabla para guardar secrets (alternativa a vault)
-- =============================================
-- Usamos nuestra propia tabla porque vault no siempre está
-- disponible en Supabase self-hosted (EasyPanel).
-- Drop and recreate to ensure correct schema
DROP TABLE IF EXISTS app_secrets;
CREATE TABLE app_secrets (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Solo SECURITY DEFINER functions pueden acceder
ALTER TABLE app_secrets ENABLE ROW LEVEL SECURITY;

-- La API key de Brevo se inyecta manualmente via SQL directo en producción.
-- NO commitear claves reales al repo.
-- Ejemplo (ejecutar fuera de este archivo):
--   INSERT INTO app_secrets (key, value) VALUES ('brevo_api_key', '<TU_KEY>')
--   ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO app_secrets (key, value)
VALUES ('brevo_api_key', 'PLACEHOLDER_SET_VIA_ADMIN')
ON CONFLICT (key) DO NOTHING;

-- =============================================
-- PASO 5: Función request_verification()
-- =============================================
CREATE OR REPLACE FUNCTION request_verification()
RETURNS void
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
BEGIN
  -- 1. Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 2. Rate limiting: max 3 requests per 10 minutes
  SELECT COUNT(*) INTO v_recent_count
  FROM otp_codes
  WHERE user_id = v_user_id
    AND created_at > NOW() - INTERVAL '10 minutes';

  IF v_recent_count >= 3 THEN
    RAISE EXCEPTION 'Too many verification requests. Wait a few minutes.';
  END IF;

  -- 3. Get user email
  SELECT email INTO v_email
  FROM auth.users
  WHERE id = v_user_id;

  IF v_email IS NULL THEN
    RAISE EXCEPTION 'No email found for user';
  END IF;

  -- 4. Get display name
  SELECT COALESCE(display_name, split_part(v_email, '@', 1))
  INTO v_display_name
  FROM profiles
  WHERE id = v_user_id;

  IF v_display_name IS NULL THEN
    v_display_name := split_part(v_email, '@', 1);
  END IF;

  -- 5. Generate 6-digit code
  v_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

  -- 6. Invalidate previous codes
  UPDATE otp_codes
  SET used = TRUE
  WHERE user_id = v_user_id AND used = FALSE;

  -- 7. Store new code (15 min expiry)
  INSERT INTO otp_codes (user_id, code, expires_at)
  VALUES (v_user_id, v_code, NOW() + INTERVAL '15 minutes');

  -- 8. Get Brevo API key from app_secrets
  SELECT value INTO v_api_key
  FROM app_secrets
  WHERE key = 'brevo_api_key';

  IF v_api_key IS NULL THEN
    RAISE EXCEPTION 'Brevo API key not configured';
  END IF;

  -- 9. Send email via Brevo API
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
        jsonb_build_object(
          'email', v_email,
          'name', v_display_name
        )
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

END;
$$;

GRANT EXECUTE ON FUNCTION request_verification() TO authenticated;

-- =============================================
-- PASO 6: Función verify_otp_code()
-- =============================================
CREATE OR REPLACE FUNCTION verify_otp_code(p_user_id UUID, p_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_otp_id UUID;
  v_calling_user UUID;
BEGIN
  -- Verify caller is the same user
  v_calling_user := auth.uid();
  IF v_calling_user IS NULL OR v_calling_user != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Code must be exactly 6 digits
  IF p_code IS NULL OR LENGTH(p_code) != 6 OR p_code !~ '^\d{6}$' THEN
    RETURN FALSE;
  END IF;

  -- Find valid code
  SELECT id INTO v_otp_id
  FROM otp_codes
  WHERE user_id = p_user_id
    AND code = p_code
    AND used = FALSE
    AND expires_at > NOW()
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_otp_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Mark as used
  UPDATE otp_codes SET used = TRUE WHERE id = v_otp_id;

  -- Mark email as verified
  UPDATE profiles
  SET email_verified = TRUE, updated_at = NOW()
  WHERE id = p_user_id;

  RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION verify_otp_code(UUID, TEXT) TO authenticated;
