-- Debug Admin Dashboard - Check Current State
-- This script will help us understand why the admin dashboard shows 0 users

-- 1. Check if auth.users exist
SELECT '=== AUTH USERS CHECK ===' as section;
SELECT 
  COUNT(*) as total_auth_users,
  'auth.users table exists and has data' as status
FROM auth.users;

-- 2. Check if profiles table exists and has data
SELECT '=== PROFILES TABLE CHECK ===' as section;
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') 
    THEN 'EXISTS' 
    ELSE 'MISSING' 
  END as profiles_table_status;

SELECT 
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN role = 'student' THEN 1 END) as student_profiles,
  COUNT(CASE WHEN role = 'tutor' THEN 1 END) as tutor_profiles,
  COUNT(CASE WHEN role = 'institution' THEN 1 END) as institution_profiles
FROM profiles;

-- 3. Check if tutor_profiles table exists and has data
SELECT '=== TUTOR PROFILES TABLE CHECK ===' as section;
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tutor_profiles') 
    THEN 'EXISTS' 
    ELSE 'MISSING' 
  END as tutor_profiles_table_status;

SELECT 
  COUNT(*) as total_tutor_profiles,
  COUNT(CASE WHEN verified = true THEN 1 END) as verified_tutors,
  COUNT(CASE WHEN verified = false THEN 1 END) as pending_tutors
FROM tutor_profiles;

-- 4. Check if institution_profiles table exists and has data
SELECT '=== INSTITUTION PROFILES TABLE CHECK ===' as section;
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'institution_profiles') 
    THEN 'EXISTS' 
    ELSE 'MISSING' 
  END as institution_profiles_table_status;

SELECT 
  COUNT(*) as total_institution_profiles,
  COUNT(CASE WHEN verified = true THEN 1 END) as verified_institutions,
  COUNT(CASE WHEN verified = false THEN 1 END) as pending_institutions
FROM institution_profiles;

-- 5. Check if users table exists (this is what the admin dashboard tries to load from)
SELECT '=== USERS TABLE CHECK ===' as section;
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') 
    THEN 'EXISTS' 
    ELSE 'MISSING' 
  END as users_table_status;

-- If users table exists, check its data
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
    RAISE NOTICE 'Users table exists, checking data...';
    EXECUTE 'SELECT COUNT(*) as total_users FROM users';
  ELSE
    RAISE NOTICE 'Users table does not exist';
  END IF;
END $$;

-- 6. Check if public_users table exists
SELECT '=== PUBLIC_USERS TABLE CHECK ===' as section;
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'public_users') 
    THEN 'EXISTS' 
    ELSE 'MISSING' 
  END as public_users_table_status;

-- If public_users table exists, check its data
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'public_users') THEN
    RAISE NOTICE 'Public_users table exists, checking data...';
    EXECUTE 'SELECT COUNT(*) as total_public_users FROM public_users';
  ELSE
    RAISE NOTICE 'Public_users table does not exist';
  END IF;
END $$;

-- 7. Summary of what we found
SELECT '=== SUMMARY ===' as section;
SELECT 
  'Expected: Admin dashboard should show users from auth.users + profiles + tutor_profiles + institution_profiles' as expectation,
  'Current: Dashboard shows 0 users' as current_state,
  'Likely cause: Users table missing or createUsersFromExistingData() not working' as diagnosis;

-- 8. What we need to do
SELECT '=== SOLUTION STEPS ===' as section;
SELECT 
  'Step 1: Create users table if missing' as action_1,
  'Step 2: Populate users table with data from auth.users + profiles' as action_2,
  'Step 3: Ensure admin dashboard can load users' as action_3;
