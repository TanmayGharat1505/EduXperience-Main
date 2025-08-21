-- Fix Tutor Profiles Roles
-- This script ensures that users with tutor_profiles have the correct role in profiles table

-- 1. First, let's see what we have
SELECT 
  'Current state' as info,
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN role = 'tutor' THEN 1 END) as tutor_profiles,
  COUNT(CASE WHEN role IS NULL THEN 1 END) as null_role_profiles
FROM profiles;

-- 2. Show profiles that have tutor_profiles but wrong/missing role
SELECT 
  p.user_id,
  p.full_name,
  p.role,
  tp.id as tutor_profile_id,
  tp.bio
FROM profiles p
JOIN tutor_profiles tp ON p.user_id = tp.user_id
WHERE p.role != 'tutor' OR p.role IS NULL
LIMIT 10;

-- 3. Update profiles to have 'tutor' role if they have a tutor_profile
UPDATE profiles 
SET role = 'tutor'
WHERE user_id IN (
  SELECT DISTINCT user_id FROM tutor_profiles
) 
AND (role != 'tutor' OR role IS NULL);

-- 4. Verify the fix
SELECT 
  'After fix' as info,
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN role = 'tutor' THEN 1 END) as tutor_profiles,
  COUNT(CASE WHEN role IS NULL THEN 1 END) as null_role_profiles
FROM profiles;

-- 5. Show the updated tutor profiles
SELECT 
  p.user_id,
  p.full_name,
  p.role,
  p.profile_photo_url,
  p.city,
  p.area,
  p.gender,
  tp.bio,
  tp.rating
FROM profiles p
JOIN tutor_profiles tp ON p.user_id = tp.user_id
WHERE p.role = 'tutor'
LIMIT 10;
