-- Create Institution Profiles Table
-- This table stores detailed information about educational institutions

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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_institution_profiles_user_id ON institution_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_institution_profiles_verified ON institution_profiles(verified);
CREATE INDEX IF NOT EXISTS idx_institution_profiles_institution_type ON institution_profiles(institution_type);
CREATE INDEX IF NOT EXISTS idx_institution_profiles_services_offered ON institution_profiles USING GIN(services_offered);
CREATE INDEX IF NOT EXISTS idx_institution_profiles_subjects_taught ON institution_profiles USING GIN(subjects_taught);
CREATE INDEX IF NOT EXISTS idx_institution_profiles_age_groups ON institution_profiles USING GIN(age_groups);

-- Enable Row Level Security (RLS)
ALTER TABLE institution_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
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

-- Public can view approved institution profiles
CREATE POLICY "Public can view approved institution profiles" ON institution_profiles
  FOR SELECT USING (verified = true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_institution_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER institution_profiles_updated_at
  BEFORE UPDATE ON institution_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_institution_profiles_updated_at();

-- Insert sample institution profile if table is empty
INSERT INTO institution_profiles (
  user_id,
  organization_name,
  institution_type,
  established_year,
  student_capacity,
  services_offered,
  subjects_taught,
  age_groups,
  contact_person_name,
  contact_person_title,
  description
) 
SELECT 
  (SELECT id FROM auth.users WHERE email = 'admin@example.com' LIMIT 1),
  'Sample Educational Institute',
  'Training Center',
  2020,
  500,
  ARRAY['Online Classes', 'Offline Classes', 'One-on-One Tutoring'],
  ARRAY['Mathematics', 'Science', 'English'],
  ARRAY['High School (15-18)', 'College (18-22)', 'Adult (22+)'],
  'John Smith',
  'Director',
  'A leading educational institution providing quality education to students of all ages.'
WHERE NOT EXISTS (SELECT 1 FROM institution_profiles LIMIT 1);

-- Check the results
SELECT 'Institution Profiles Table Created:' as info;
SELECT 
  COUNT(*) as total_institutions,
  COUNT(CASE WHEN verified = true THEN 1 END) as verified,
  COUNT(CASE WHEN verified = false THEN 1 END) as pending_verification
FROM institution_profiles;

-- Show sample data
SELECT 
  'Sample Institution Profile:' as info;
SELECT 
  organization_name,
  institution_type,
  established_year,
  verified,
  created_at
FROM institution_profiles 
LIMIT 1;
