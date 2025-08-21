-- Test Admin Dashboard Database Setup
-- Run this to check if tables exist and have data

-- 1. Check if tables exist
SELECT 'Table Existence Check:' as info;
SELECT 
  table_name,
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = t.table_name) 
    THEN 'EXISTS' 
    ELSE 'MISSING' 
  END as status
FROM (VALUES 
  ('users'),
  ('public_users'),
  ('tutor_profiles'),
  ('profiles'),
  ('reviews'),
  ('tutor_content'),
  ('transactions'),
  ('payouts'),
  ('refunds'),
  ('fees')
) AS t(table_name)
ORDER BY table_name;

-- 2. Check table record counts
SELECT 'Table Record Counts:' as info;
SELECT 
  'users' as table_name,
  COUNT(*) as record_count
FROM users
UNION ALL
SELECT 
  'public_users' as table_name,
  COUNT(*) as record_count
FROM public_users
UNION ALL
SELECT 
  'tutor_profiles' as table_name,
  COUNT(*) as record_count
FROM tutor_profiles
UNION ALL
SELECT 
  'profiles' as table_name,
  COUNT(*) as record_count
FROM profiles
UNION ALL
SELECT 
  'reviews' as table_name,
  COUNT(*) as record_count
FROM reviews
UNION ALL
SELECT 
  'tutor_content' as table_name,
  COUNT(*) as record_count
FROM tutor_content
UNION ALL
SELECT 
  'transactions' as table_name,
  COUNT(*) as record_count
FROM transactions
UNION ALL
SELECT 
  'payouts' as table_name,
  COUNT(*) as record_count
FROM payouts
UNION ALL
SELECT 
  'refunds' as table_name,
  COUNT(*) as record_count
FROM refunds
UNION ALL
SELECT 
  'fees' as table_name,
  COUNT(*) as record_count
FROM fees;

-- 3. Check users table structure and sample data
SELECT 'Users Table Structure:' as info;
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- 4. Show sample users (tutors and institutions only)
SELECT 'Sample Users (Tutors & Institutions):' as info;
SELECT 
  id,
  user_id,
  email,
  role,
  verification_status,
  created_at
FROM users
WHERE role IN ('tutor', 'institution')
ORDER BY created_at DESC
LIMIT 10;

-- 5. Check if there are any users with 'student' role
SELECT 'Users with Student Role (should be 0):' as info;
SELECT COUNT(*) as student_count
FROM users
WHERE role = 'student';

-- 6. Check verification status distribution
SELECT 'Verification Status Distribution:' as info;
SELECT 
  verification_status,
  COUNT(*) as count
FROM users
WHERE role IN ('tutor', 'institution')
GROUP BY verification_status
ORDER BY verification_status;
