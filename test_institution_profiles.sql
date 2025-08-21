-- Test Institution Profiles Table Creation
-- This script tests the basic table creation without complex features

-- 1. Create the basic table
CREATE TABLE IF NOT EXISTS institution_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  organization_name TEXT NOT NULL,
  institution_type TEXT NOT NULL,
  established_year INTEGER,
  student_capacity INTEGER,
  accreditation TEXT,
  services_offered TEXT[],
  subjects_taught TEXT[],
  age_groups TEXT[],
  contact_person_name TEXT NOT NULL,
  contact_person_title TEXT NOT NULL,
  contact_person_email TEXT,
  contact_person_phone TEXT,
  description TEXT,
  website TEXT,
  social_media TEXT,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create basic indexes
CREATE INDEX IF NOT EXISTS idx_institution_profiles_user_id ON institution_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_institution_profiles_verified ON institution_profiles(verified);

-- 3. Enable RLS
ALTER TABLE institution_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create basic RLS policy
CREATE POLICY "Users can view own institution profile" ON institution_profiles
  FOR SELECT USING (auth.uid() = user_id);

-- 5. Test insertion with a simple record
INSERT INTO institution_profiles (
  user_id,
  organization_name,
  institution_type,
  established_year,
  contact_person_name,
  contact_person_title,
  description
) 
SELECT 
  (SELECT id FROM auth.users LIMIT 1),
  'Test Institution',
  'Training Center',
  2020,
  'Test Contact',
  'Director',
  'A test institution for verification'
WHERE NOT EXISTS (SELECT 1 FROM institution_profiles LIMIT 1);

-- 6. Check the results
SELECT 'Institution Profiles Table Test Results:' as info;
SELECT 
  COUNT(*) as total_institutions,
  COUNT(CASE WHEN verified = true THEN 1 END) as verified,
  COUNT(CASE WHEN verified = false THEN 1 END) as pending_verification
FROM institution_profiles;

-- 7. Show the test record
SELECT 
  'Test Record:' as info;
SELECT 
  organization_name,
  institution_type,
  established_year,
  verified,
  created_at
FROM institution_profiles 
LIMIT 1;
