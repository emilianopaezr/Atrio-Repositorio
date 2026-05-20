-- =============================================
-- 027_host_profile_details.sql
-- Adds optional "about" fields shown in the listing detail's
-- "Conoce al anfitrión" section, inspired by Airbnb's host card.
--   • profession      — TEXT (e.g. "Psicóloga", "Arquitecto")
--   • decade_born     — TEXT (e.g. "80s", "90s", "70s")
--   • languages       — TEXT[] (e.g. ARRAY['es','en'])
--   • response_time_hours — INTEGER (mean reply latency in hours)
-- =============================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS profession           TEXT,
  ADD COLUMN IF NOT EXISTS decade_born          TEXT,
  ADD COLUMN IF NOT EXISTS languages            TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS response_time_hours  INTEGER;

GRANT SELECT (profession, decade_born, languages, response_time_hours)
  ON profiles TO authenticated;
