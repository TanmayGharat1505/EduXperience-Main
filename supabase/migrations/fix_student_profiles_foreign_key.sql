-- Fix foreign key relationship between student_profiles and profiles
-- This migration ensures the foreign key constraint exists and is properly configured

-- First, let's check if the foreign key constraint already exists
DO $$
BEGIN
    -- Check if the foreign key constraint already exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'student_profiles_user_id_fkey' 
        AND table_name = 'student_profiles'
    ) THEN
        -- Add the foreign key constraint
        ALTER TABLE student_profiles 
        ADD CONSTRAINT student_profiles_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint added successfully';
    ELSE
        RAISE NOTICE 'Foreign key constraint already exists';
    END IF;
END $$;

-- Ensure the user_id column exists and has the correct type
ALTER TABLE student_profiles 
ALTER COLUMN user_id TYPE UUID USING user_id::UUID;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_student_profiles_user_id ON student_profiles(user_id);

-- Update RLS policies to allow proper access
DROP POLICY IF EXISTS "Users can view their own student profile" ON student_profiles;
CREATE POLICY "Users can view their own student profile" ON student_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own student profile" ON student_profiles;
CREATE POLICY "Users can update their own student profile" ON student_profiles
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own student profile" ON student_profiles;
CREATE POLICY "Users can insert their own student profile" ON student_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow public read access to student profiles for tutors
DROP POLICY IF EXISTS "Public can view student profiles" ON student_profiles;
CREATE POLICY "Public can view student profiles" ON student_profiles
    FOR SELECT USING (true); 