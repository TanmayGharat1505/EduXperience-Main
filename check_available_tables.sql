-- Check Available Tables and Their Structure
-- Run this in your Supabase SQL Editor to see what tables exist

-- 1. List all tables in the public schema
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. Check if key tables exist
SELECT 
  'profiles' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') as exists
UNION ALL
SELECT 
  'tutor_profiles' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tutor_profiles') as exists
UNION ALL
SELECT 
  'student_profiles' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'student_profiles') as exists
UNION ALL
SELECT 
  'search_history' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'search_history') as exists
UNION ALL
SELECT 
  'learning_records' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'learning_records') as exists
UNION ALL
SELECT 
  'messages' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages') as exists
UNION ALL
SELECT 
  'classes' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'classes') as exists;

-- 3. Check tutor_profiles structure (if it exists)
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tutor_profiles'
ORDER BY ordinal_position;

-- 4. Check if there are any tutor profiles
SELECT COUNT(*) as total_tutor_profiles
FROM tutor_profiles;

-- 5. Check if there are any profiles with role = 'tutor'
SELECT 
  role,
  COUNT(*) as count
FROM profiles 
GROUP BY role;
