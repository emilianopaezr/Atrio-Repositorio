-- =============================================
-- 026_service_requests.sql
-- Lets the publish-service "Solicitar" flow persist requests in the
-- same `listings` table as offers, with a discriminator + urgency.
--   • is_request  — TRUE when the listing is a customer-side request
--                   for someone to provide a service.
--   • urgency     — 'today' | 'tomorrow' | 'week' | 'flexible'
-- =============================================

ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS is_request BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS urgency    TEXT;

CREATE INDEX IF NOT EXISTS idx_listings_is_request
  ON listings(is_request)
  WHERE is_request = TRUE;
