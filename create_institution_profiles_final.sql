-- Create Institution Profiles Table - Final Working Version
-- This script creates the institution_profiles table with proper schema and RLS policies

-- 1. Create the institution_profiles table
CREATE TABLE IF NOT EXISTS institution_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  institution_name TEXT NOT NULL,
  institution_type TEXT NOT NULL,
  established_year INTEGER NOT NULL,
  description TEXT,
  contact_person_name TEXT NOT NULL,
  contact_person_title TEXT NOT NULL,
  country TEXT NOT NULL,
  state TEXT NOT NULL,
  city TEXT NOT NULL,
  address TEXT NOT NULL,
  verified BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_institution_profiles_user_id ON institution_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_institution_profiles_verified ON institution_profiles(verified);
CREATE INDEX IF NOT EXISTS idx_institution_profiles_institution_type ON institution_profiles(institution_type);

-- 3. Enable Row Level Security
ALTER TABLE institution_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies
-- Policy 1: Allow users to insert their own institution profile
CREATE POLICY "Allow new institution profile creation" ON institution_profiles
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy 2: Allow users to view their own institution profile
CREATE POLICY "Users can view own institution profile" ON institution_profiles
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy 3: Allow users to update their own institution profile
CREATE POLICY "Users can update own institution profile" ON institution_profiles
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- Policy 4: Allow public viewing of verified institution profiles
CREATE POLICY "Public can view verified institution profiles" ON institution_profiles
  FOR SELECT 
  USING (verified = true);

-- Policy 5: Allow admins to manage all institution profiles
CREATE POLICY "Admins can manage all institution profiles" ON institution_profiles
  FOR ALL 
  USING (auth.role() = 'admin');

-- 5. Create a trigger to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_institution_profiles_updated_at 
  BEFORE UPDATE ON institution_profiles 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- 6. Insert sample data (optional - for testing)
INSERT INTO institution_profiles (
  user_id,
  institution_name,
  institution_type,
  established_year,
  description,
  contact_person_name,
  contact_person_title,
  country,
  state,
  city,
  address,
  verified
) VALUES (
  '00000000-0000-0000-0000-000000000000', -- Replace with actual user ID for testing
  'Sample University',
  'University',
  2020,
  'A sample educational institution for testing purposes',
  'John Doe',
  'Director',
  'United States',
  'California',
  'Los Angeles',
  '123 Sample Street',
  false
) ON CONFLICT (user_id) DO NOTHING;

-- 7. Verify the table was created successfully
SELECT 'Institution Profiles Table Created Successfully!' as status;
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'institution_profiles'
ORDER BY ordinal_position;

-- 8. Show the RLS policies
SELECT 'RLS Policies Created:' as info;
SELECT 
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE tablename = 'institution_profiles';
