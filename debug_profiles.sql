-- Debug Profiles Table - Check what data is available for tutors
-- Run this to see what's in the profiles table

-- 1. Check the structure of profiles table
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Check how many profiles exist and their roles
SELECT 
  role,
  COUNT(*) as count
FROM profiles 
GROUP BY role;

-- 3. Check tutor profiles specifically
SELECT 
  user_id,
  full_name,
  role,
  profile_photo_url,
  city,
  area,
  gender
FROM profiles 
WHERE role = 'tutor'
LIMIT 10;

-- 4. Check if there are any profiles without role specified (ENUM can't be empty string)
SELECT 
  user_id,
  full_name,
  role,
  profile_photo_url
FROM profiles 
WHERE role IS NULL
LIMIT 10;

-- 5. Check total count of profiles
SELECT COUNT(*) as total_profiles FROM profiles;

-- 6. Check if there are any profiles that might be tutors but have different role values
SELECT DISTINCT role FROM profiles WHERE role IS NOT NULL;

-- 7. Check what ENUM values are allowed for the role field
SELECT 
  t.typname as enum_name,
  e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'app_role'
ORDER BY e.enumsortorder;
