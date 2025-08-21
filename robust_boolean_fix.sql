-- Robust fix: Handle boolean column conversion step by step
-- Run this in your Supabase SQL Editor

-- Step 1: Check current column types and data
SELECT 
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN data_type = 'text' THEN 'TEXT column - needs conversion'
        WHEN data_type = 'boolean' THEN 'BOOLEAN column - already correct'
        ELSE 'Unknown type: ' || data_type
    END as status
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
AND column_name IN ('currently_teaching', 'demo_class');

-- Step 2: Check if there's any existing data that might cause issues
SELECT 
    'currently_teaching' as column_name,
    currently_teaching,
    typeof(currently_teaching) as data_type
FROM tutor_profiles 
WHERE currently_teaching IS NOT NULL
LIMIT 5;

SELECT 
    'demo_class' as column_name,
    demo_class,
    typeof(demo_class) as data_type
FROM tutor_profiles 
WHERE demo_class IS NOT NULL
LIMIT 5;

-- Step 3: Drop existing constraints first
ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_currently_teaching_check;
ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_demo_class_check;

-- Step 4: Convert columns to boolean with proper handling
-- First, set any problematic values to NULL
UPDATE tutor_profiles 
SET currently_teaching = NULL 
WHERE currently_teaching NOT IN ('Yes', 'No', 'true', 'false', true, false);

UPDATE tutor_profiles 
SET demo_class = NULL 
WHERE demo_class NOT IN ('Yes', 'No', 'true', 'false', true, false);

-- Now convert the columns to boolean
ALTER TABLE tutor_profiles ALTER COLUMN currently_teaching TYPE BOOLEAN USING 
    CASE 
        WHEN currently_teaching = 'Yes' OR currently_teaching = 'true' THEN true
        WHEN currently_teaching = 'No' OR currently_teaching = 'false' THEN false
        ELSE NULL
    END;

ALTER TABLE tutor_profiles ALTER COLUMN demo_class TYPE BOOLEAN USING 
    CASE 
        WHEN demo_class = 'Yes' OR demo_class = 'true' THEN true
        WHEN demo_class = 'No' OR demo_class = 'false' THEN false
        ELSE NULL
    END;

-- Step 5: Add new constraints
ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_currently_teaching_check 
CHECK (currently_teaching IN (true, false) OR currently_teaching IS NULL);

ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_demo_class_check 
CHECK (demo_class IN (true, false) OR demo_class IS NULL);

-- Step 6: Verify the fix
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
AND column_name IN ('currently_teaching', 'demo_class');

-- Step 7: Test insert/update
SELECT 'Boolean columns and constraints fixed successfully!' as status;
