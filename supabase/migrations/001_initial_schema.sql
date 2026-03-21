-- ============================================
-- ATRIO MVP - Initial Database Schema
-- Run this SQL on your Supabase SQL Editor
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. PROFILES (extends auth.users)
-- =============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  photo_url TEXT,
  phone TEXT,
  bio TEXT,
  is_host BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  kyc_status TEXT DEFAULT 'none' CHECK (kyc_status IN ('none', 'pending', 'approved', 'rejected')),
  favorite_listing_ids UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 2. LISTINGS
-- =============================================
CREATE TABLE IF NOT EXISTS listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('space', 'experience', 'service')),
  title TEXT NOT NULL,
  description TEXT,
  images TEXT[] DEFAULT '{}',
  category TEXT,
  tags TEXT[] DEFAULT '{}',
  amenities TEXT[] DEFAULT '{}',
  address TEXT,
  city TEXT,
  country TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  base_price DECIMAL(10,2),
  currency TEXT DEFAULT 'USD',
  price_unit TEXT DEFAULT 'night' CHECK (price_unit IN ('night', 'hour', 'session', 'person')),
  cleaning_fee DECIMAL(10,2) DEFAULT 0,
  capacity INTEGER,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'paused')),
  rating DECIMAL(3,2) DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 3. AVAILABILITY
-- =============================================
CREATE TABLE IF NOT EXISTS availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  is_available BOOLEAN DEFAULT TRUE,
  custom_price DECIMAL(10,2),
  booking_id UUID,
  UNIQUE(listing_id, date)
);

-- =============================================
-- 4. BOOKINGS
-- =============================================
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guest_id UUID NOT NULL REFERENCES profiles(id),
  host_id UUID NOT NULL REFERENCES profiles(id),
  listing_id UUID NOT NULL REFERENCES listings(id),
  check_in TIMESTAMPTZ NOT NULL,
  check_out TIMESTAMPTZ NOT NULL,
  guests_count INTEGER DEFAULT 1,
  base_total DECIMAL(10,2),
  cleaning_fee DECIMAL(10,2) DEFAULT 0,
  service_fee DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'active', 'completed', 'cancelled', 'rejected')),
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
  special_requests TEXT,
  conversation_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 5. CONVERSATIONS
-- =============================================
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_ids UUID[] NOT NULL,
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  listing_id UUID REFERENCES listings(id) ON DELETE SET NULL,
  last_message_text TEXT,
  last_message_sender UUID,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 6. MESSAGES
-- =============================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id),
  text TEXT,
  type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'system')),
  image_url TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 7. REVIEWS
-- =============================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES profiles(id),
  host_id UUID NOT NULL REFERENCES profiles(id),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  host_reply TEXT,
  host_reply_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 8. TRANSACTIONS (host wallet)
-- =============================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL REFERENCES profiles(id),
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('earning', 'payout', 'refund', 'fee')),
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 9. HOST PROFILES (financial)
-- =============================================
CREATE TABLE IF NOT EXISTS host_profiles (
  id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  bank_name TEXT,
  account_last4 TEXT,
  bank_configured BOOLEAN DEFAULT FALSE,
  total_earnings DECIMAL(12,2) DEFAULT 0,
  current_balance DECIMAL(12,2) DEFAULT 0,
  pending_balance DECIMAL(12,2) DEFAULT 0,
  response_rate DECIMAL(5,2) DEFAULT 0,
  is_superhost BOOLEAN DEFAULT FALSE,
  joined_as_host_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- 10. NOTIFICATIONS
-- =============================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT,
  body TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- INDEXES for performance
-- =============================================
CREATE INDEX IF NOT EXISTS idx_listings_host_id ON listings(host_id);
CREATE INDEX IF NOT EXISTS idx_listings_type ON listings(type);
CREATE INDEX IF NOT EXISTS idx_listings_status ON listings(status);
CREATE INDEX IF NOT EXISTS idx_listings_city ON listings(city);
CREATE INDEX IF NOT EXISTS idx_listings_is_featured ON listings(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_availability_listing_date ON availability(listing_id, date);
CREATE INDEX IF NOT EXISTS idx_bookings_guest_id ON bookings(guest_id);
CREATE INDEX IF NOT EXISTS idx_bookings_host_id ON bookings(host_id);
CREATE INDEX IF NOT EXISTS idx_bookings_listing_id ON bookings(listing_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sent_at ON messages(sent_at);
CREATE INDEX IF NOT EXISTS idx_reviews_listing_id ON reviews(listing_id);
CREATE INDEX IF NOT EXISTS idx_transactions_host_id ON transactions(host_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- =============================================
-- TRIGGERS
-- =============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trigger_listings_updated_at
  BEFORE UPDATE ON listings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trigger_bookings_updated_at
  BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-create profile on new user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists, then create
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update listing rating when review is added
CREATE OR REPLACE FUNCTION update_listing_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE listings
  SET rating = (
    SELECT COALESCE(AVG(rating), 0)
    FROM reviews
    WHERE listing_id = NEW.listing_id
  ),
  review_count = (
    SELECT COUNT(*)
    FROM reviews
    WHERE listing_id = NEW.listing_id
  )
  WHERE id = NEW.listing_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_listing_rating
  AFTER INSERT OR UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_listing_rating();
