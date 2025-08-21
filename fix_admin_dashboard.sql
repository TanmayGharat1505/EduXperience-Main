-- Fix Admin Dashboard Data Issues
-- This script ensures all necessary tables and data exist for the admin dashboard

-- 1. Check what tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'public_users', 'tutor_profiles', 'profiles', 'verification_requests')
ORDER BY table_name;

-- 2. Create users table if it doesn't exist (for admin dashboard)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  verification_status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create public_users table if it doesn't exist (alternative users table)
CREATE TABLE IF NOT EXISTS public_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  verification_status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Insert sample users if tables are empty
INSERT INTO users (user_id, email, role, verification_status)
SELECT 
  id,
  email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id) THEN 'tutor'
    WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = id AND role = 'student') THEN 'student'
    ELSE 'user'
  END as role,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id AND verified = true) THEN 'approved'
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id AND verified = false) THEN 'pending'
    ELSE 'pending'
  END as verification_status
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM users)
ON CONFLICT (user_id) DO NOTHING;

-- 5. Insert into public_users as well
INSERT INTO public_users (user_id, email, role, verification_status)
SELECT 
  id,
  email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id) THEN 'tutor'
    WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = id AND role = 'student') THEN 'student'
    ELSE 'user'
  END as role,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id AND verified = true) THEN 'approved'
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id AND verified = false) THEN 'pending'
    ELSE 'pending'
  END as verification_status
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM public_users)
ON CONFLICT (user_id) DO NOTHING;

-- 6. Check verification_requests table
SELECT 
  'verification_requests' as table_name,
  COUNT(*) as record_count
FROM verification_requests
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
  'users' as table_name,
  COUNT(*) as record_count
FROM users
UNION ALL
SELECT 
  'public_users' as table_name,
  COUNT(*) as record_count
FROM public_users;

-- 7. Show sample data from each table
SELECT 'Sample verification_requests:' as info;
SELECT * FROM verification_requests LIMIT 3;

SELECT 'Sample tutor_profiles:' as info;
SELECT id, user_id, verified, bio FROM tutor_profiles LIMIT 3;

SELECT 'Sample profiles:' as info;
SELECT user_id, full_name, role FROM profiles LIMIT 3;

SELECT 'Sample users:' as info;
SELECT user_id, email, role, verification_status FROM users LIMIT 3;
