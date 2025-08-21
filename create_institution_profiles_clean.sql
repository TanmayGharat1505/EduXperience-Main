-- Create Institution Profiles Table (Clean Version)
-- This table stores detailed information about educational institutions

-- 1. Create the table
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
CREATE INDEX IF NOT EXISTS idx_institution_profiles_institution_type ON institution_profiles(institution_type);

-- 3. Enable Row Level Security
ALTER TABLE institution_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies
-- Users can view their own institution profile
CREATE POLICY "Users can view own institution profile" ON institution_profiles
  FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own institution profile
CREATE POLICY "Users can update own institution profile" ON institution_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can insert their own institution profile
CREATE POLICY "Users can insert own institution profile" ON institution_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admins can view all institution profiles
CREATE POLICY "Admins can view all institution profiles" ON institution_profiles
  FOR ALL USING (auth.role() = 'admin');

-- Public can view verified institution profiles
CREATE POLICY "Public can view verified institution profiles" ON institution_profiles
  FOR SELECT USING (verified = true);

-- 5. Test the table creation
SELECT 'Institution Profiles Table Created Successfully!' as status;

-- 6. Check if table exists and has correct structure
SELECT 
  'Table Structure Check:' as info;
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'institution_profiles'
ORDER BY ordinal_position;

-- 7. Show table count
SELECT 
  'Table Status:' as info;
SELECT 
  COUNT(*) as total_institutions
FROM institution_profiles;
