-- Check Current Tutor Profiles Table Structure
-- Run this to see what fields are actually available

-- 1. Check the current table structure
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tutor_profiles'
ORDER BY ordinal_position;

-- 2. Check if there are any tutor profiles
SELECT COUNT(*) as total_tutor_profiles
FROM tutor_profiles;

-- 3. Sample a few tutor profiles to see the data structure
SELECT 
  id,
  user_id,
  bio,
  experience_years,
  hourly_rate_min,
  hourly_rate_max,
  teaching_mode,
  rating,
  verified,
  qualifications,
  created_at
FROM tutor_profiles 
LIMIT 3;

-- 4. Check what's in the qualifications JSONB field
SELECT 
  user_id,
  qualifications,
  jsonb_typeof(qualifications) as qualifications_type
FROM tutor_profiles 
WHERE qualifications IS NOT NULL
LIMIT 5;

-- 5. Check if there are any profiles with role = 'tutor'
SELECT 
  role,
  COUNT(*) as count
FROM profiles 
GROUP BY role;

-- 6. Check if the old fields still exist (subjects, class_size, etc.)
-- This will show if the migration removed important fields
SELECT 
  'subjects' as field_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tutor_profiles' 
    AND column_name = 'subjects'
  ) as exists
UNION ALL
SELECT 
  'class_size' as field_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tutor_profiles' 
    AND column_name = 'class_size'
  ) as exists
UNION ALL
SELECT 
  'available_days' as field_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tutor_profiles' 
    AND column_name = 'available_days'
  ) as exists
UNION ALL
SELECT 
  'subjects' as field_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tutor_profiles' 
    AND column_name = 'subjects'
  ) as exists;
