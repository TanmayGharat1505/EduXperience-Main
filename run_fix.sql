-- Run this in your Supabase SQL Editor to fix the 500 Internal Server Error during login

-- Step 1: Drop the problematic trigger and function
DROP TRIGGER IF EXISTS trigger_sync_public_users ON auth.users;
DROP FUNCTION IF EXISTS sync_public_users();

-- Step 2: Verify the trigger is removed
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table 
FROM information_schema.triggers 
WHERE event_object_table = 'users' AND event_object_schema = 'auth';

-- Step 3: Check if public_users table exists and has data
SELECT COUNT(*) as user_count FROM public_users;

-- Step 4: If public_users is empty, you can manually add some users for testing
-- (This is optional - only if you want to test the admin dashboard)
INSERT INTO public_users (id, email, role, verification_status, created_at) 
VALUES 
    ('550e8400-e29b-41d4-a716-446655440001', 'test@example.com', 'user', 'pending', NOW())
ON CONFLICT (id) DO NOTHING;

-- After running this, try logging in again - the 500 error should be resolved
