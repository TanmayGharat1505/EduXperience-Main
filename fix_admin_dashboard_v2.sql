-- Fix Admin Dashboard Data Issues - Version 2
-- This script ensures only tutors and institutions are shown for verification
-- Students are excluded from admin verification

-- 1. Check what tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'public_users', 'tutor_profiles', 'profiles', 'verification_requests')
ORDER BY table_name;

-- 2. Drop existing users tables to recreate with correct data
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS public_users CASCADE;

-- 3. Create users table for admin dashboard (tutors and institutions only)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('tutor', 'institution')),
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create public_users table (alternative for admin dashboard)
CREATE TABLE public_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('tutor', 'institution')),
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Insert only tutors and institutions (exclude students)
INSERT INTO users (user_id, email, role, verification_status)
SELECT 
  id,
  email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id) THEN 'tutor'
    WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = id AND role = 'institution') THEN 'institution'
    ELSE 'tutor' -- Default to tutor if profile exists but role is unclear
  END as role,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id AND verified = true) THEN 'approved'
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id AND verified = false) THEN 'pending'
    ELSE 'pending'
  END as verification_status
FROM auth.users
WHERE EXISTS (
  SELECT 1 FROM tutor_profiles WHERE user_id = id
) OR EXISTS (
  SELECT 1 FROM profiles WHERE user_id = id AND role = 'institution'
);

-- 6. Insert into public_users as well
INSERT INTO public_users (user_id, email, role, verification_status)
SELECT 
  id,
  email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id) THEN 'tutor'
    WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = id AND role = 'institution') THEN 'institution'
    ELSE 'tutor'
  END as role,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id AND verified = true) THEN 'approved'
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id AND verified = false) THEN 'pending'
    ELSE 'pending'
  END as verification_status
FROM auth.users
WHERE EXISTS (
  SELECT 1 FROM tutor_profiles WHERE user_id = id
) OR EXISTS (
  SELECT 1 FROM profiles WHERE user_id = id AND role = 'institution'
);

-- 7. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_user_id ON users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_verification_status ON users(verification_status);
CREATE INDEX IF NOT EXISTS idx_public_users_user_id ON public_users(user_id);
CREATE INDEX IF NOT EXISTS idx_public_users_role ON public_users(role);
CREATE INDEX IF NOT EXISTS idx_public_users_verification_status ON public_users(verification_status);

-- 8. Enable Row Level Security (RLS) for admin access only
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_users ENABLE ROW LEVEL SECURITY;

-- 9. Create RLS policies for admin access
CREATE POLICY "Admin can view all users" ON users
  FOR ALL USING (auth.role() = 'admin');

CREATE POLICY "Admin can view all public users" ON public_users
  FOR ALL USING (auth.role() = 'admin');

-- 10. Check the results
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
  'users (tutors/institutions only)' as table_name,
  COUNT(*) as record_count
FROM users
UNION ALL
SELECT 
  'public_users (tutors/institutions only)' as table_name,
  COUNT(*) as record_count
FROM public_users;

-- 11. Show verification data (tutors and institutions only)
SELECT 'Users requiring verification:' as info;
SELECT 
  u.user_id,
  u.email,
  u.role,
  u.verification_status,
  CASE 
    WHEN u.role = 'tutor' THEN tp.bio
    WHEN u.role = 'institution' THEN p.bio
    ELSE 'No bio'
  END as bio
FROM users u
LEFT JOIN tutor_profiles tp ON u.user_id = tp.user_id
LEFT JOIN profiles p ON u.user_id = p.user_id
ORDER BY u.verification_status, u.created_at;
