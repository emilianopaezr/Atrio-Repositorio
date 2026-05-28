-- =============================================
-- 032_reviews_host_reply.sql
-- Adds host_reply_at + makes paez admin in one go.
-- Idempotent.
-- =============================================

-- 1. host_reply_at — timestamp for when the host posted/edited
--    their public reply. The reply itself lives in `host_reply`
--    (already added in 001/002).
ALTER TABLE reviews
  ADD COLUMN IF NOT EXISTS host_reply_at TIMESTAMPTZ;

-- 2. Make paez.r.emiliano@gmail.com admin (idempotent).
UPDATE profiles
SET is_admin = TRUE
WHERE id = (
  SELECT id FROM auth.users
  WHERE LOWER(email) = LOWER('paez.r.emiliano@gmail.com')
)
RETURNING id, display_name, is_admin;

-- 3. Verify.
SELECT u.email, p.display_name, p.is_admin
FROM profiles p
JOIN auth.users u ON u.id = p.id
WHERE p.is_admin = TRUE
ORDER BY u.email;
