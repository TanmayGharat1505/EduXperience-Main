-- Migration: Fix auth trigger conflict
-- This migration removes the problematic trigger on auth.users that was causing 500 errors during login

-- Drop the trigger that's interfering with Supabase authentication
DROP TRIGGER IF EXISTS trigger_sync_public_users ON auth.users;

-- Drop the function that was causing issues
DROP FUNCTION IF EXISTS sync_public_users();

-- The public_users table will remain but won't auto-sync
-- This prevents the 500 Internal Server Error during login
-- Users can still be manually added to public_users or synced through application logic
