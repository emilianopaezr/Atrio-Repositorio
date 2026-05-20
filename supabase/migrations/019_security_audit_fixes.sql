-- =============================================
-- 019_security_audit_fixes.sql
-- Fixes detected during the full security audit (2026-05-01).
-- =============================================

-- =============================================
-- 1. PROFILES — close anonymous read leak
-- Previously "Profiles are viewable by everyone" let any anonymous caller
-- read phone numbers, KYC status and favorite_listing_ids of every user.
-- Fix: require authentication, expose a safe public view for cross-user joins.
-- =============================================

DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;

CREATE POLICY "Authenticated users can view profiles"
  ON profiles FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Public-safe view (bypasses RLS, exposes ONLY non-sensitive columns).
-- Used by anon callers and future cross-user joins.
DROP VIEW IF EXISTS public_profiles CASCADE;
CREATE VIEW public_profiles AS
SELECT id, display_name, photo_url, bio, is_host, is_verified,
       host_level, guest_level, email_verified, created_at, updated_at
FROM profiles;

GRANT SELECT ON public_profiles TO anon, authenticated;

-- Owner-only RPC for retrieving the full row (sensitive columns included).
CREATE OR REPLACE FUNCTION get_my_profile()
RETURNS profiles
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM profiles WHERE id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION get_my_profile() TO authenticated;

-- NOTE: Authenticated users can still read other users' phone/kyc_status
-- via the base table. Mitigation requires migrating joins to use
-- public_profiles. Tracked as a P2 follow-up.

-- =============================================
-- 2. STORAGE — avatars (public read, owner-only writes)
-- Path convention: avatars/{user_id}/{filename}
-- =============================================

DROP POLICY IF EXISTS "avatars_public_read" ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_insert" ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_update" ON storage.objects;
DROP POLICY IF EXISTS "avatars_owner_delete" ON storage.objects;

CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_owner_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_owner_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_owner_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- =============================================
-- 3. STORAGE — listings (public read, host-controlled writes)
-- Path convention: listings/{host_id}/...
-- =============================================

DROP POLICY IF EXISTS "listings_public_read" ON storage.objects;
DROP POLICY IF EXISTS "listings_host_insert" ON storage.objects;
DROP POLICY IF EXISTS "listings_host_update" ON storage.objects;
DROP POLICY IF EXISTS "listings_host_delete" ON storage.objects;

CREATE POLICY "listings_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'listings');

CREATE POLICY "listings_host_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'listings'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "listings_host_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'listings'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "listings_host_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'listings'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- =============================================
-- 4. STORAGE — kyc (private bucket, owner-only)
-- Path convention: kyc/{user_id}/{filename}
-- Service role bypasses RLS for admin review.
-- =============================================

DROP POLICY IF EXISTS "kyc_owner_read" ON storage.objects;
DROP POLICY IF EXISTS "kyc_owner_insert" ON storage.objects;
DROP POLICY IF EXISTS "kyc_owner_update" ON storage.objects;
DROP POLICY IF EXISTS "kyc_owner_delete" ON storage.objects;

CREATE POLICY "kyc_owner_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'kyc'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc_owner_insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'kyc'
    AND auth.uid() IS NOT NULL
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc_owner_update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'kyc'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "kyc_owner_delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'kyc'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- =============================================
-- 5. STORAGE — drop legacy 'listing' (singular) bucket if empty
-- =============================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'listing')
     AND NOT EXISTS (SELECT 1 FROM storage.objects WHERE bucket_id = 'listing') THEN
    DELETE FROM storage.buckets WHERE id = 'listing';
  END IF;
END $$;
