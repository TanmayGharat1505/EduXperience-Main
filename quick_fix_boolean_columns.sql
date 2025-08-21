-- Quick fix: Change column types and update constraints in one go
-- Run this in your Supabase SQL Editor

-- Change column types from TEXT to BOOLEAN
ALTER TABLE tutor_profiles ALTER COLUMN currently_teaching TYPE BOOLEAN USING 
    CASE WHEN currently_teaching = 'Yes' THEN true WHEN currently_teaching = 'No' THEN false ELSE NULL END;

ALTER TABLE tutor_profiles ALTER COLUMN demo_class TYPE BOOLEAN USING 
    CASE WHEN demo_class = 'Yes' THEN true WHEN demo_class = 'No' THEN false ELSE NULL END;

-- Drop old constraints and add new ones
ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_currently_teaching_check;
ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_demo_class_check;

ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_currently_teaching_check 
CHECK (currently_teaching IN (true, false) OR currently_teaching IS NULL);

ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_demo_class_check 
CHECK (demo_class IN (true, false) OR demo_class IS NULL);

SELECT 'Boolean columns and constraints fixed!' as status;
