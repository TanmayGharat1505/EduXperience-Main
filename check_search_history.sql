-- Check Search History Table and Data
-- Run this in your Supabase SQL Editor to debug tutor loading issues

-- 1. Check if search_history table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'search_history'
) as table_exists;

-- 2. If table exists, check its structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'search_history'
ORDER BY ordinal_position;

-- 3. Check if there's any data in the table
SELECT COUNT(*) as total_records
FROM search_history;

-- 4. Sample some records
SELECT * FROM search_history LIMIT 5;

-- 5. Check if there are any tutor profiles
SELECT COUNT(*) as total_tutor_profiles
FROM tutor_profiles;

-- 6. Sample some tutor profiles
SELECT 
  id,
  user_id,
  bio,
  experience_years,
  hourly_rate_min,
  teaching_mode,
  verified,
  created_at
FROM tutor_profiles 
LIMIT 5;

-- 7. Check if there are any tutor profiles with verified status
SELECT 
  verified,
  COUNT(*) as count
FROM tutor_profiles 
GROUP BY verified;

-- 8. Check if there are any profiles with role = 'tutor'
SELECT 
  role,
  COUNT(*) as count
FROM profiles 
GROUP BY role;

-- 9. Check if there are any profiles with profile_photo_url
SELECT 
  COUNT(*) as profiles_with_photos,
  COUNT(*) FILTER (WHERE profile_photo_url IS NOT NULL) as profiles_with_photos_count
FROM profiles 
WHERE role = 'tutor';
