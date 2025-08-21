-- Restore Admin Dashboard to Previous Working State
-- This removes the verification system and restores simple profile moderation
-- ONLY for tutors and institutions (students are excluded)

-- 1. Drop the verification system tables that were added
DROP TABLE IF EXISTS verification_requests CASCADE;
DROP TABLE IF EXISTS verification_documents CASCADE;
DROP TABLE IF EXISTS verification_references CASCADE;
DROP TABLE IF EXISTS subject_proficiency_tests CASCADE;
DROP TABLE IF EXISTS test_questions CASCADE;
DROP TABLE IF EXISTS test_attempts CASCADE;
DROP TABLE IF EXISTS verification_workflow_logs CASCADE;

-- 2. Drop the admin-specific users tables
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS public_users CASCADE;

-- 3. Restore the original tutor_profiles structure (remove verified field if it doesn't exist)
-- First check if verified field exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tutor_profiles' AND column_name = 'verified'
    ) THEN
        ALTER TABLE tutor_profiles ADD COLUMN verified BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- 4. Set all existing tutor profiles to need verification (pending)
UPDATE tutor_profiles SET verified = FALSE WHERE verified IS NULL OR verified = true;

-- 5. Create a simple users table for admin dashboard (ONLY tutors and institutions)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('tutor', 'institution')),
  verification_status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create public_users table (alternative, ONLY tutors and institutions)
CREATE TABLE IF NOT EXISTS public_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('tutor', 'institution')),
  verification_status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Populate users table with ONLY tutors and institutions (exclude students)
INSERT INTO users (user_id, email, role, verification_status)
SELECT 
  id,
  email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id) THEN 'tutor'
    WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = id AND role = 'institution') THEN 'institution'
    WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = id AND role = 'tutor') THEN 'tutor'
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
  SELECT 1 FROM profiles WHERE user_id = id AND role IN ('tutor', 'institution')
);

-- 8. Populate public_users table as well (ONLY tutors and institutions)
INSERT INTO public_users (user_id, email, role, verification_status)
SELECT 
  id,
  email,
  CASE 
    WHEN EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = id) THEN 'tutor'
    WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = id AND role = 'institution') THEN 'institution'
    WHEN EXISTS (SELECT 1 FROM profiles WHERE user_id = id AND role = 'tutor') THEN 'tutor'
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
  SELECT 1 FROM profiles WHERE user_id = id AND role IN ('tutor', 'institution')
);

-- 9. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_user_id ON users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_verification_status ON users(verification_status);
CREATE INDEX IF NOT EXISTS idx_public_users_user_id ON public_users(user_id);
CREATE INDEX IF NOT EXISTS idx_public_users_role ON public_users(role);
CREATE INDEX IF NOT EXISTS idx_public_users_verification_status ON public_users(verification_status);

-- 10. Check table structures first
SELECT 'Table Structures Check:' as info;
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'tutor_profiles')
ORDER BY table_name, ordinal_position;

-- 11. Check the restored data (should only show tutors and institutions)
SELECT 'Restored Data Summary (Tutors & Institutions Only):' as info;
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
FROM profiles;

-- 12. Show users by role and verification status (tutors and institutions only)
SELECT 'Users by Role and Status (Tutors & Institutions Only):' as info;
SELECT 
  role,
  verification_status,
  COUNT(*) as count
FROM users
GROUP BY role, verification_status
ORDER BY role, verification_status;

-- 13. Show pending verification (tutors and institutions only)
SELECT 'Pending Verification (Tutors & Institutions):' as info;
SELECT 
  u.user_id,
  u.email,
  u.role,
  u.verification_status,
  CASE 
    WHEN u.role = 'tutor' THEN COALESCE(tp.bio, 'Tutor profile')
    WHEN u.role = 'institution' THEN COALESCE(
      p.bio, 
      p.full_name, 
      p.organization_name, 
      'Institution profile'
    )
    ELSE 'No bio'
  END as bio
FROM users u
LEFT JOIN tutor_profiles tp ON u.user_id = tp.user_id
LEFT JOIN profiles p ON u.user_id = p.user_id
WHERE u.verification_status = 'pending'
ORDER BY u.created_at;
