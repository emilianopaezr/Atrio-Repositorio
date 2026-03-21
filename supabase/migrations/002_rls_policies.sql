-- ============================================
-- ATRIO MVP - Row Level Security Policies
-- Run AFTER 001_initial_schema.sql
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE host_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- =============================================
-- PROFILES
-- =============================================
-- Anyone can view profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Profile insert is handled by the trigger (SECURITY DEFINER)
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- =============================================
-- LISTINGS
-- =============================================
-- Published listings are viewable by everyone
CREATE POLICY "Published listings are viewable by everyone"
  ON listings FOR SELECT
  USING (status = 'published' OR host_id = auth.uid());

-- Hosts can create listings
CREATE POLICY "Hosts can create listings"
  ON listings FOR INSERT
  WITH CHECK (auth.uid() = host_id);

-- Hosts can update their own listings
CREATE POLICY "Hosts can update own listings"
  ON listings FOR UPDATE
  USING (auth.uid() = host_id)
  WITH CHECK (auth.uid() = host_id);

-- Hosts can delete their own listings
CREATE POLICY "Hosts can delete own listings"
  ON listings FOR DELETE
  USING (auth.uid() = host_id);

-- =============================================
-- AVAILABILITY
-- =============================================
-- Everyone can view availability for published listings
CREATE POLICY "Availability viewable for published listings"
  ON availability FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM listings
      WHERE listings.id = availability.listing_id
      AND (listings.status = 'published' OR listings.host_id = auth.uid())
    )
  );

-- Hosts can manage availability for their listings
CREATE POLICY "Hosts can manage own listing availability"
  ON availability FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM listings
      WHERE listings.id = availability.listing_id
      AND listings.host_id = auth.uid()
    )
  );

CREATE POLICY "Hosts can update own listing availability"
  ON availability FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM listings
      WHERE listings.id = availability.listing_id
      AND listings.host_id = auth.uid()
    )
  );

CREATE POLICY "Hosts can delete own listing availability"
  ON availability FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM listings
      WHERE listings.id = availability.listing_id
      AND listings.host_id = auth.uid()
    )
  );

-- =============================================
-- BOOKINGS
-- =============================================
-- Users can view their own bookings (as guest or host)
CREATE POLICY "Users can view own bookings"
  ON bookings FOR SELECT
  USING (auth.uid() = guest_id OR auth.uid() = host_id);

-- Guests can create bookings
CREATE POLICY "Guests can create bookings"
  ON bookings FOR INSERT
  WITH CHECK (auth.uid() = guest_id);

-- Participants can update bookings (status changes)
CREATE POLICY "Participants can update bookings"
  ON bookings FOR UPDATE
  USING (auth.uid() = guest_id OR auth.uid() = host_id);

-- =============================================
-- CONVERSATIONS
-- =============================================
-- Participants can view their conversations
CREATE POLICY "Users can view own conversations"
  ON conversations FOR SELECT
  USING (auth.uid() = ANY(participant_ids));

-- Authenticated users can create conversations
CREATE POLICY "Authenticated users can create conversations"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() = ANY(participant_ids));

-- Participants can update conversation metadata
CREATE POLICY "Participants can update conversations"
  ON conversations FOR UPDATE
  USING (auth.uid() = ANY(participant_ids));

-- =============================================
-- MESSAGES
-- =============================================
-- Participants can view messages in their conversations
CREATE POLICY "Users can view messages in own conversations"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND auth.uid() = ANY(conversations.participant_ids)
    )
  );

-- Users can send messages in their conversations
CREATE POLICY "Users can send messages in own conversations"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND auth.uid() = ANY(conversations.participant_ids)
    )
  );

-- Users can update their own messages (mark as read)
CREATE POLICY "Users can update messages in own conversations"
  ON messages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
      AND auth.uid() = ANY(conversations.participant_ids)
    )
  );

-- =============================================
-- REVIEWS
-- =============================================
-- Everyone can view reviews
CREATE POLICY "Reviews are viewable by everyone"
  ON reviews FOR SELECT
  USING (true);

-- Users can create reviews for their bookings
CREATE POLICY "Users can create reviews for own bookings"
  ON reviews FOR INSERT
  WITH CHECK (auth.uid() = reviewer_id);

-- Hosts can reply to reviews (update host_reply)
CREATE POLICY "Hosts can reply to reviews"
  ON reviews FOR UPDATE
  USING (auth.uid() = host_id);

-- =============================================
-- TRANSACTIONS
-- =============================================
-- Hosts can view their own transactions
CREATE POLICY "Hosts can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = host_id);

-- System inserts transactions (via service_role or trigger)
-- For MVP, allow hosts to see their transactions
CREATE POLICY "Service can insert transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = host_id);

-- =============================================
-- HOST PROFILES
-- =============================================
-- Hosts can view their own financial profile
CREATE POLICY "Hosts can view own financial profile"
  ON host_profiles FOR SELECT
  USING (auth.uid() = id);

-- Hosts can create their financial profile
CREATE POLICY "Hosts can create own financial profile"
  ON host_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Hosts can update their financial profile
CREATE POLICY "Hosts can update own financial profile"
  ON host_profiles FOR UPDATE
  USING (auth.uid() = id);

-- =============================================
-- NOTIFICATIONS
-- =============================================
-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- System can create notifications
CREATE POLICY "Service can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);
