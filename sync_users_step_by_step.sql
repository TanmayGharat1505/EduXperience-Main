-- Step-by-step user sync script
-- Run each section separately in your Supabase SQL Editor

-- SECTION 1: Create the sync function
-- Run this first
CREATE OR REPLACE FUNCTION sync_users_manually()
RETURNS INTEGER AS $$
DECLARE
    user_count INTEGER := 0;
    auth_user RECORD;
BEGIN
    -- Loop through auth.users and sync to public_users
    FOR auth_user IN 
        SELECT 
            id, 
            email, 
            COALESCE(raw_user_meta_data->>'role', 'user') as role,
            created_at
        FROM auth.users
    LOOP
        INSERT INTO public_users (id, email, role, verification_status, created_at)
        VALUES (auth_user.id, auth_user.email, auth_user.role, 'pending', auth_user.created_at)
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            role = EXCLUDED.role,
            updated_at = NOW();
        
        user_count := user_count + 1;
    END LOOP;
    
    RETURN user_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- SECTION 2: Grant permissions
-- Run this after SECTION 1
GRANT EXECUTE ON FUNCTION sync_users_manually() TO postgres;

-- SECTION 3: Test the function
-- Run this after SECTION 2
SELECT sync_users_manually() as synced_users;

-- SECTION 4: Check results
-- Run this after SECTION 3
SELECT COUNT(*) as total_users FROM public_users;
SELECT * FROM public_users LIMIT 5;
