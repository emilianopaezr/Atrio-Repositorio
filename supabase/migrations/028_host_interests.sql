-- =============================================
-- 028_host_interests.sql
-- Adds an optional `interests` array (hobbies / personality bits) to
-- profiles, shown in the listing detail's "Conoce al anfitrión" card.
-- =============================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS interests TEXT[] NOT NULL DEFAULT '{}';

GRANT SELECT (interests) ON profiles TO authenticated;
