-- ============================================
-- FIX: Drop the problematic trigger
-- The profile will be created from the app code instead
-- Run this in your Supabase SQL Editor
-- ============================================

-- Drop the trigger that causes "Database error saving new user"
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Keep the function for reference but it won't auto-fire
-- DROP FUNCTION IF EXISTS handle_new_user();

-- Also allow the profiles INSERT policy to work for new users
-- The existing policy requires auth.uid() = id, which is correct
-- But we need to make sure it works immediately after signup
