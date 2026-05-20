-- =============================================
-- 024_listings_rules_blockhours.sql
-- Adds two columns the Flutter app already inserts but were missing
-- from the listings schema, causing "create listing" to fail silently.
--   • rules        — TEXT[]  (house rules selected from RulesCatalog)
--   • block_hours  — INTEGER (slot length when rental_mode='hours')
-- =============================================

ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS rules        TEXT[]  NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS block_hours  INTEGER NOT NULL DEFAULT 1;

-- Defensive: any pre-existing NULL gets coerced to default values.
UPDATE listings SET rules       = '{}' WHERE rules       IS NULL;
UPDATE listings SET block_hours = 1    WHERE block_hours IS NULL;
