-- Fix: Update constraint values to match frontend data types
-- The frontend sends boolean values (true/false) but constraints expect strings (Yes/No)

-- First, check current column types
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
AND column_name IN ('currently_teaching', 'demo_class');

-- First, change the column data types from TEXT to BOOLEAN
ALTER TABLE tutor_profiles ALTER COLUMN currently_teaching TYPE BOOLEAN USING 
    CASE 
        WHEN currently_teaching = 'Yes' THEN true
        WHEN currently_teaching = 'No' THEN false
        ELSE NULL
    END;

ALTER TABLE tutor_profiles ALTER COLUMN demo_class TYPE BOOLEAN USING 
    CASE 
        WHEN demo_class = 'Yes' THEN true
        WHEN demo_class = 'No' THEN false
        ELSE NULL
    END;

-- Verify the column types were changed
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
AND column_name IN ('currently_teaching', 'demo_class');

-- Now drop the old constraints
ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_currently_teaching_check;
ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_demo_class_check;

-- Add new constraints that accept boolean values
ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_currently_teaching_check 
CHECK (currently_teaching IN (true, false) OR currently_teaching IS NULL);

ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_demo_class_check 
CHECK (demo_class IN (true, false) OR demo_class IS NULL);

-- Verify the new constraints
SELECT 
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_name LIKE '%tutor_profiles%';

-- Final verification
SELECT 'Column types and constraints updated successfully!' as status;
