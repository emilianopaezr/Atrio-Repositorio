-- =============================================
-- 020_app_secrets.sql
-- Tabla para guardar secretos de servidor (MP_ACCESS_TOKEN, etc.) cuando
-- el compose de EasyPanel no permite inyectar env vars al contenedor
-- functions. RLS denegada a todos: solo service_role accede (bypass RLS).
-- =============================================

CREATE TABLE IF NOT EXISTS app_secrets (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE app_secrets ENABLE ROW LEVEL SECURITY;

-- Sin políticas → ningún cliente con anon/authenticated puede leer.
-- service_role bypassa RLS; las Edge Functions usan service_role.

REVOKE ALL ON app_secrets FROM anon, authenticated;
GRANT  SELECT, INSERT, UPDATE, DELETE ON app_secrets TO service_role;

COMMENT ON TABLE app_secrets IS
  'Server-only secrets read by Edge Functions. Locked by RLS (no policies). Rotate by UPDATE.';
