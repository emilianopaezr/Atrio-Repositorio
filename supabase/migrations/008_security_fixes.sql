-- =============================================
-- Migration 008: Security Fixes
-- Fixes CRITICAL/HIGH RLS policy vulnerabilities
-- =============================================

-- =============================================
-- 1. Fix host_stats RLS
-- CRITICAL: "Service can manage host stats" uses FOR ALL USING (true)
-- which allows ANY user to INSERT/UPDATE/DELETE any host's stats.
-- Fix: Remove permissive policy, restrict writes to service role / triggers only.
-- =============================================

DROP POLICY IF EXISTS "Service can manage host stats" ON host_stats;
DROP POLICY IF EXISTS "Host can read own stats" ON host_stats;

-- SELECT: Only the host can read their own stats
CREATE POLICY "Host can read own stats"
  ON host_stats FOR SELECT
  USING (auth.uid() = host_id);

-- INSERT: Block all client-side inserts (only SECURITY DEFINER functions and service_role can bypass RLS)
CREATE POLICY "System manages host stats insert"
  ON host_stats FOR INSERT
  WITH CHECK (false);

-- UPDATE: Block all client-side updates (only SECURITY DEFINER functions and service_role can bypass RLS)
CREATE POLICY "System manages host stats update"
  ON host_stats FOR UPDATE
  USING (false);

-- DELETE: Block all client-side deletes
CREATE POLICY "System manages host stats delete"
  ON host_stats FOR DELETE
  USING (false);


-- =============================================
-- 2. Fix guest_stats RLS
-- CRITICAL: Same issue as host_stats - FOR ALL USING (true) is wide open.
-- =============================================

DROP POLICY IF EXISTS "Service can manage guest stats" ON guest_stats;
DROP POLICY IF EXISTS "Guest can read own stats" ON guest_stats;

-- SELECT: Only the guest can read their own stats
CREATE POLICY "Guest can read own stats"
  ON guest_stats FOR SELECT
  USING (auth.uid() = guest_id);

-- INSERT: Block all client-side inserts
CREATE POLICY "System manages guest stats insert"
  ON guest_stats FOR INSERT
  WITH CHECK (false);

-- UPDATE: Block all client-side updates
CREATE POLICY "System manages guest stats update"
  ON guest_stats FOR UPDATE
  USING (false);

-- DELETE: Block all client-side deletes
CREATE POLICY "System manages guest stats delete"
  ON guest_stats FOR DELETE
  USING (false);


-- =============================================
-- 3. Fix time_slot_bookings INSERT
-- HIGH: Current policy allows any authenticated user to insert slots
-- for any booking, even bookings that don't belong to them.
-- Fix: Verify the user is the guest on the related booking.
-- =============================================

DROP POLICY IF EXISTS "Authenticated can insert time slot bookings" ON time_slot_bookings;

CREATE POLICY "Booking guest can insert time slot bookings"
  ON time_slot_bookings FOR INSERT
  WITH CHECK (
    booking_id IN (
      SELECT id FROM bookings WHERE guest_id = auth.uid()
    )
  );


-- =============================================
-- 4. Fix pricing_config SELECT
-- HIGH: Current policy uses USING (true) which allows anonymous
-- (unauthenticated) access. Restrict to authenticated users only.
-- =============================================

DROP POLICY IF EXISTS "Anyone can read pricing config" ON pricing_config;

CREATE POLICY "Authenticated can read pricing config"
  ON pricing_config FOR SELECT
  USING (auth.uid() IS NOT NULL);
