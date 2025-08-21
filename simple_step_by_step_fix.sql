-- Simple step-by-step fix for boolean columns
-- Run each section separately in your Supabase SQL Editor

-- STEP 1: Check what columns exist and their types
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
AND column_name IN ('currently_teaching', 'demo_class');

-- STEP 2: If columns don't exist, add them as boolean
-- (Only run this if the columns don't exist)
-- ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS currently_teaching BOOLEAN;
-- ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS demo_class BOOLEAN;

-- STEP 3: If columns exist as TEXT, drop them and recreate as boolean
-- (Only run this if the columns exist as TEXT)
-- ALTER TABLE tutor_profiles DROP COLUMN IF EXISTS currently_teaching;
-- ALTER TABLE tutor_profiles DROP COLUMN IF EXISTS demo_class;
-- ALTER TABLE tutor_profiles ADD COLUMN currently_teaching BOOLEAN;
-- ALTER TABLE tutor_profiles ADD COLUMN demo_class BOOLEAN;

-- STEP 4: Drop any existing constraints
ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_currently_teaching_check;
ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_demo_class_check;

-- STEP 5: Add new boolean constraints
ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_currently_teaching_check 
CHECK (currently_teaching IN (true, false) OR currently_teaching IS NULL);

ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_demo_class_check 
CHECK (demo_class IN (true, false) OR demo_class IS NULL);

-- STEP 6: Verify the fix
SELECT 'Constraints added successfully!' as status;
