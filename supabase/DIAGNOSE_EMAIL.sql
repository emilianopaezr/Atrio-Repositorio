-- =============================================
-- DIAGNOSE_EMAIL.sql
-- Diagnose why verification emails are not arriving.
-- Run in Supabase SQL Editor (as the service_role / admin connection).
-- =============================================

-- 1. Is the Brevo API key configured? (Should NOT be PLACEHOLDER_SET_VIA_ADMIN)
SELECT
  key,
  CASE
    WHEN value = 'PLACEHOLDER_SET_VIA_ADMIN' THEN '❌ NOT SET — emails will fail'
    WHEN length(value) < 20 THEN '❌ Suspiciously short — probably invalid'
    WHEN value LIKE 'xkeysib-%' THEN '✅ Looks like a real Brevo key'
    ELSE '⚠️ Unexpected format'
  END AS status,
  length(value) AS key_length,
  left(value, 10) || '...' AS preview
FROM app_secrets
WHERE key = 'brevo_api_key';

-- 2. Is pg_net installed?
SELECT
  extname,
  extversion,
  '✅ pg_net is available' AS status
FROM pg_extension
WHERE extname = 'pg_net';

-- 3. Recent OTP codes generated (last 24h)
SELECT
  id,
  user_id,
  code,
  used,
  expires_at,
  created_at,
  CASE
    WHEN expires_at > NOW() AND used = FALSE THEN '🟢 Active'
    WHEN used = TRUE THEN '✅ Used'
    ELSE '⏰ Expired'
  END AS state
FROM otp_codes
ORDER BY created_at DESC
LIMIT 10;

-- 4. Recent pg_net HTTP responses (Brevo API replies)
-- This shows the LAST 10 outgoing requests so you can see if Brevo
-- replied 200 OK or 401/403/etc.
SELECT
  id,
  status_code,
  content_type,
  -- Show only first 300 chars of body — full body may be huge.
  left(content::text, 300) AS body_preview,
  created
FROM net._http_response
ORDER BY created DESC
LIMIT 10;

-- 5. The current user's email + verification status (replace 'YOUR_EMAIL' below)
-- SELECT
--   u.email,
--   u.confirmed_at,
--   p.email_verified,
--   p.created_at
-- FROM auth.users u
-- LEFT JOIN profiles p ON p.id = u.id
-- WHERE u.email = 'YOUR_EMAIL_HERE'
-- ORDER BY u.created_at DESC
-- LIMIT 5;
