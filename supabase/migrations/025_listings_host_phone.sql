-- =============================================
-- 025_listings_host_phone.sql
-- Adds optional contact-phone fields per listing so a host can publish
-- their phone publicly. The phone is sourced from the user's profile
-- but the visibility is per-listing.
--   • host_phone        — TEXT (E.164 or local format, optional)
--   • show_host_phone   — BOOLEAN DEFAULT FALSE (publishes the number)
-- =============================================

ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS host_phone      TEXT,
  ADD COLUMN IF NOT EXISTS show_host_phone BOOLEAN NOT NULL DEFAULT FALSE;

-- Defensive: clamp any pre-existing nulls (no-op on fresh schemas).
UPDATE listings SET show_host_phone = FALSE WHERE show_host_phone IS NULL;
