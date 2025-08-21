-- Fix Users Table Constraint Issue
-- The error shows that "student" role violates the check constraint

-- 1. First, let's see what the current constraint actually allows
SELECT '=== CURRENT CONSTRAINT CHECK ===' as section;
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND contype = 'c';

-- 2. Check what values are currently in the profiles table for roles
SELECT '=== CURRENT PROFILES ROLES ===' as section;
SELECT DISTINCT role, COUNT(*) as count
FROM profiles 
WHERE role IS NOT NULL
GROUP BY role
ORDER BY role;

-- 3. Check what values are in auth.users (if any role info exists)
SELECT '=== AUTH USERS CHECK ===' as section;
SELECT 
  COUNT(*) as total_auth_users,
  'auth.users table exists and has data' as status
FROM auth.users;

-- 4. Drop the problematic constraint and recreate it with correct values
SELECT '=== FIXING CONSTRAINT ===' as section;

-- Drop the existing constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- Recreate the constraint with the correct role values
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN ('student', 'tutor', 'institution', 'admin'));

-- 5. Also check and fix the verification_status constraint
SELECT '=== CHECKING VERIFICATION STATUS CONSTRAINT ===' as section;
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND contype = 'c';

-- 6. Now try to populate the table again
SELECT '=== POPULATING TABLE AGAIN ===' as section;

-- Create a simpler function that handles the role mapping correctly
CREATE OR REPLACE FUNCTION populate_users_table_fixed()
RETURNS void AS $$
DECLARE
  auth_user RECORD;
  profile_record RECORD;
  tutor_profile_record RECORD;
  institution_profile_record RECORD;
  user_role TEXT;
  verification_status TEXT;
BEGIN
  -- Clear existing data
  DELETE FROM users;
  
  -- Loop through all auth users
  FOR auth_user IN SELECT * FROM auth.users LOOP
    -- Try to find profile information
    SELECT role INTO profile_record FROM profiles WHERE user_id = auth_user.id LIMIT 1;
    
    -- Try to find tutor profile
    SELECT verified INTO tutor_profile_record FROM tutor_profiles WHERE user_id = auth_user.id LIMIT 1;
    
    -- Try to find institution profile
    SELECT verified INTO institution_profile_record FROM institution_profiles WHERE user_id = auth_user.id LIMIT 1;
    
    -- Determine role - ensure it's one of the allowed values
    IF profile_record.role IS NOT NULL AND profile_record.role IN ('student', 'tutor', 'institution', 'admin') THEN
      user_role := profile_record.role;
    ELSE
      -- Try to infer role from existing profiles
      IF EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = auth_user.id) THEN
        user_role := 'tutor';
      ELSIF EXISTS (SELECT 1 FROM institution_profiles WHERE user_id = auth_user.id) THEN
        user_role := 'institution';
      ELSE
        user_role := 'student'; -- Default to student if no other role found
      END IF;
    END IF;
    
    -- Ensure role is valid
    IF user_role NOT IN ('student', 'tutor', 'institution', 'admin') THEN
      user_role := 'student'; -- Fallback to student
    END IF;
    
    -- Determine verification status
    IF user_role = 'student' THEN
      verification_status := 'approved'; -- Students are auto-approved
    ELSIF user_role = 'tutor' THEN
      IF tutor_profile_record.verified IS NOT NULL THEN
        verification_status := CASE WHEN tutor_profile_record.verified THEN 'approved' ELSE 'pending' END;
      ELSE
        verification_status := 'pending';
      END IF;
    ELSIF user_role = 'institution' THEN
      IF institution_profile_record.verified IS NOT NULL THEN
        verification_status := CASE WHEN institution_profile_record.verified THEN 'approved' ELSE 'pending' END;
      ELSE
        verification_status := 'pending';
      END IF;
    ELSE
      verification_status := 'pending';
    END IF;
    
    -- Ensure verification_status is valid
    IF verification_status NOT IN ('pending', 'approved', 'rejected') THEN
      verification_status := 'pending'; -- Fallback to pending
    END IF;
    
    -- Insert user record
    INSERT INTO users (id, user_id, email, role, verification_status, created_at, updated_at)
    VALUES (
      auth_user.id,
      auth_user.id,
      COALESCE(auth_user.email, 'unknown@example.com'),
      user_role,
      verification_status,
      auth_user.created_at,
      COALESCE(auth_user.updated_at, auth_user.created_at)
    );
    
  END LOOP;
  
  RAISE NOTICE 'Users table populated with % records', (SELECT COUNT(*) FROM users);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Execute the fixed function
SELECT populate_users_table_fixed();

-- 7. Verify the data was created
SELECT '=== USERS TABLE POPULATED ===' as status;
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'student' THEN 1 END) as students,
  COUNT(CASE WHEN role = 'tutor' THEN 1 END) as tutors,
  COUNT(CASE WHEN role = 'institution' THEN 1 END) as institutions,
  COUNT(CASE WHEN verification_status = 'pending' THEN 1 END) as pending,
  COUNT(CASE WHEN verification_status = 'approved' THEN 1 END) as approved,
  COUNT(CASE WHEN verification_status = 'rejected' THEN 1 END) as rejected
FROM users;

-- 8. Show sample data
SELECT '=== SAMPLE USER DATA ===' as status;
SELECT 
  email,
  role,
  verification_status,
  created_at
FROM users 
ORDER BY created_at DESC 
LIMIT 5;

-- 9. Clean up
DROP FUNCTION IF EXISTS populate_users_table();
DROP FUNCTION IF EXISTS populate_users_table_fixed();
