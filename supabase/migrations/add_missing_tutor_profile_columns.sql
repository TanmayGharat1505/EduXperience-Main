-- Migration: Add Missing Tutor Profile Columns
-- This migration adds all the missing columns needed for the tutor dashboard to function properly

-- First, let's check if the tutor_profiles table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tutor_profiles') THEN
        RAISE EXCEPTION 'Table tutor_profiles does not exist. Please create it first.';
    END IF;
    RAISE NOTICE 'Table tutor_profiles exists - proceeding with migration';
END $$;

-- Show current table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    COALESCE(column_default, 'none') as default_value
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
ORDER BY ordinal_position;

-- Add missing columns to tutor_profiles table
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS mobile_number TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS pin_code TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS highest_qualification TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS university_name TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS year_of_passing INTEGER;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS percentage DECIMAL(5,2);
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS teaching_experience TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS currently_teaching BOOLEAN;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS current_teaching_place TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS subjects JSONB;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS student_levels JSONB;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS curriculum JSONB;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS class_type TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS max_travel_distance INTEGER;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS class_size INTEGER;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS available_days JSONB;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS individual_fee DECIMAL(10,2);
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS group_fee DECIMAL(10,2);
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS home_tuition_fee DECIMAL(10,2);
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS demo_class BOOLEAN;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS demo_class_fee DECIMAL(10,2);
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS assignment_help BOOLEAN DEFAULT false;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS test_preparation BOOLEAN DEFAULT false;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS homework_support BOOLEAN DEFAULT false;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS weekend_classes BOOLEAN DEFAULT false;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS profile_headline TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS teaching_methodology TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS why_choose_me TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS languages JSONB;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS response_time_hours INTEGER DEFAULT 24;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS hourly_rate_min DECIMAL(10,2);
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS hourly_rate_max DECIMAL(10,2);
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS teaching_mode TEXT;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS qualifications JSONB;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS availability JSONB;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT false;
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS profile_completion_percentage INTEGER DEFAULT 0;

-- Add the missing updated_at column that the trigger function needs
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add check constraints for tutor_profiles (using safer approach)
DO $$
BEGIN
    -- Add gender constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'tutor_profiles_gender_check' 
        AND table_name = 'tutor_profiles'
    ) THEN
        ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_gender_check 
        CHECK (gender IN ('Male', 'Female', 'Other') OR gender IS NULL);
        RAISE NOTICE 'Added gender constraint';
    END IF;
    
    -- Add currently_teaching constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'tutor_profiles_currently_teaching_check' 
        AND table_name = 'tutor_profiles'
    ) THEN
        ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_currently_teaching_check 
        CHECK (currently_teaching IN (true, false) OR currently_teaching IS NULL);
        RAISE NOTICE 'Added currently_teaching constraint (boolean values)';
    END IF;
    
    -- Add demo_class constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'tutor_profiles_demo_class_check' 
        AND table_name = 'tutor_profiles'
    ) THEN
        ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_demo_class_check 
        CHECK (demo_class IN (true, false) OR demo_class IS NULL);
        RAISE NOTICE 'Added demo_class constraint (boolean values)';
    END IF;
    
    -- Add class_type constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'tutor_profiles_class_type_check' 
        AND table_name = 'tutor_profiles'
    ) THEN
        ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_class_type_check 
        CHECK (class_type IN ('Individual', 'Group', 'Both') OR class_type IS NULL);
        RAISE NOTICE 'Added class_type constraint';
    END IF;
END $$;

-- Add basic indexes for tutor_profiles (avoiding GIN indexes for now)
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_location ON tutor_profiles(pin_code);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_verified ON tutor_profiles(verified);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_hourly_rate ON tutor_profiles(hourly_rate_min, hourly_rate_max);

-- Update RLS policies for tutor_profiles
DROP POLICY IF EXISTS "Users can view their own tutor profile" ON tutor_profiles;
CREATE POLICY "Users can view their own tutor profile" ON tutor_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own tutor profile" ON tutor_profiles;
CREATE POLICY "Users can update their own tutor profile" ON tutor_profiles
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own tutor profile" ON tutor_profiles;
CREATE POLICY "Users can insert their own tutor profile" ON tutor_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow public read access to tutor profiles for students (for search functionality)
DROP POLICY IF EXISTS "Public can view tutor profiles" ON tutor_profiles;
CREATE POLICY "Public can view tutor profiles" ON tutor_profiles
    FOR SELECT USING (true);

-- Add trigger to automatically update updated_at timestamp for tutor_profiles
CREATE OR REPLACE FUNCTION update_tutor_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_tutor_profiles_updated_at ON tutor_profiles;
CREATE TRIGGER trigger_update_tutor_profiles_updated_at
    BEFORE UPDATE ON tutor_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_tutor_profiles_updated_at();

-- Grant necessary permissions for tutor_profiles
GRANT ALL ON tutor_profiles TO authenticated;

-- Add unique constraint on user_id to support upsert operations
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'tutor_profiles' 
        AND constraint_name = 'tutor_profiles_user_id_unique'
        AND constraint_type = 'UNIQUE'
    ) THEN
        ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_user_id_unique UNIQUE (user_id);
        RAISE NOTICE 'Added unique constraint on user_id for upsert operations';
    ELSE
        RAISE NOTICE 'Unique constraint on user_id already exists';
    END IF;
END $$;

-- Add comments for tutor_profiles documentation
COMMENT ON TABLE tutor_profiles IS 'Tutor profile information including qualifications, experience, and services offered';
COMMENT ON COLUMN tutor_profiles.currently_teaching IS 'Whether the tutor is currently teaching: Yes or No';
COMMENT ON COLUMN tutor_profiles.current_teaching_place IS 'Current place where the tutor is teaching';
COMMENT ON COLUMN tutor_profiles.demo_class IS 'Whether the tutor offers demo classes: Yes or No';
COMMENT ON COLUMN tutor_profiles.demo_class_fee IS 'Fee charged for demo classes in INR';
COMMENT ON COLUMN tutor_profiles.subjects IS 'JSON array of subjects the tutor can teach';
COMMENT ON COLUMN tutor_profiles.qualifications IS 'JSON array of tutor qualifications and certifications';
COMMENT ON COLUMN tutor_profiles.availability IS 'JSON object containing tutor availability schedule';

-- Final success message
DO $$
BEGIN
    RAISE NOTICE '🎉 TUTOR PROFILE MIGRATION COMPLETED SUCCESSFULLY! 🎉';
    RAISE NOTICE '';
    RAISE NOTICE 'TUTOR_PROFILES table now includes all missing fields:';
    RAISE NOTICE '  - Personal Information (Title, Mobile, DOB, Gender, Pin Code)';
    RAISE NOTICE '  - Professional Details (Bio, Experience, Qualifications, University)';
    RAISE NOTICE '  - Teaching Information (Currently Teaching, Teaching Place, Subjects)';
    RAISE NOTICE '  - Class Details (Class Type, Size, Travel Distance, Available Days)';
    RAISE NOTICE '  - Pricing (Individual, Group, Home Tuition, Demo Class Fees)';
    RAISE NOTICE '  - Services (Assignment Help, Test Prep, Homework Support, Weekend Classes)';
    RAISE NOTICE '  - Profile Content (Headline, Teaching Methodology, Why Choose Me, Languages)';
    RAISE NOTICE '';
    RAISE NOTICE 'You can now save and update all profile information in the tutor dashboard!';
END $$;



