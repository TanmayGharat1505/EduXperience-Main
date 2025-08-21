-- Check Profiles Table Structure
-- This script will show us what columns actually exist in the profiles table

-- 1. Check if profiles table exists
SELECT 'Profiles Table Existence Check:' as info;
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') 
    THEN 'EXISTS' 
    ELSE 'MISSING' 
  END as status;

-- 2. Show profiles table structure
SELECT 'Profiles Table Structure:' as info;
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- 3. Check if institution_profiles table exists
SELECT 'Institution Profiles Table Existence Check:' as info;
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'institution_profiles') 
    THEN 'EXISTS' 
    ELSE 'MISSING' 
  END as status;

-- 4. Show institution_profiles table structure (if it exists)
SELECT 'Institution Profiles Table Structure:' as info;
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'institution_profiles'
ORDER BY ordinal_position;

-- 5. Show sample data from profiles table
SELECT 'Sample Profiles Data:' as info;
SELECT 
  user_id,
  full_name,
  email,
  role,
  phone,
  bio
FROM profiles 
LIMIT 3;
