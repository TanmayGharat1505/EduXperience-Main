-- Fix foreign key relationship between tutor_profiles and profiles
-- This migration ensures the foreign key constraint exists and is properly configured

-- First, let's check if the foreign key constraint already exists
DO $$
BEGIN
    -- Check if the foreign key constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'tutor_profiles_user_id_fkey' 
        AND table_name = 'tutor_profiles'
    ) THEN
        -- Add the foreign key constraint
        ALTER TABLE tutor_profiles 
        ADD CONSTRAINT tutor_profiles_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint added successfully';
    ELSE
        RAISE NOTICE 'Foreign key constraint already exists';
    END IF;
END $$;

-- Ensure the user_id column exists and has the correct type
ALTER TABLE tutor_profiles 
ALTER COLUMN user_id TYPE UUID USING user_id::UUID;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_user_id ON tutor_profiles(user_id);

-- Update RLS policies to allow proper access
DROP POLICY IF EXISTS "Users can view their own tutor profile" ON tutor_profiles;
CREATE POLICY "Users can view their own tutor profile" ON tutor_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own tutor profile" ON tutor_profiles;
CREATE POLICY "Users can update their own tutor profile" ON tutor_profiles
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own tutor profile" ON tutor_profiles;
CREATE POLICY "Users can insert their own tutor profile" ON tutor_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow public read access to tutor profiles for students
DROP POLICY IF EXISTS "Public can view tutor profiles" ON tutor_profiles;
CREATE POLICY "Public can view tutor profiles" ON tutor_profiles
    FOR SELECT USING (true);

-- Ensure the profiles table has the correct structure
ALTER TABLE profiles 
ALTER COLUMN user_id TYPE UUID USING user_id::UUID;

-- Add unique constraint on user_id in profiles if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'profiles_user_id_key' 
        AND table_name = 'profiles'
    ) THEN
        ALTER TABLE profiles ADD CONSTRAINT profiles_user_id_key UNIQUE (user_id);
    END IF;
END $$; 