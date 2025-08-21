-- Restore Original Tutor Profiles Table Structure - FIXED VERSION
-- This will add back the fields that the Student Dashboard needs to work properly

-- 1. Add back the missing fields that were working before
ALTER TABLE tutor_profiles 
ADD COLUMN IF NOT EXISTS subjects TEXT[],
ADD COLUMN IF NOT EXISTS class_size TEXT[],
ADD COLUMN IF NOT EXISTS available_days TEXT[],
ADD COLUMN IF NOT EXISTS student_levels TEXT[],
ADD COLUMN IF NOT EXISTS curriculum TEXT[],
ADD COLUMN IF NOT EXISTS highest_qualification TEXT,
ADD COLUMN IF NOT EXISTS university TEXT,
ADD COLUMN IF NOT EXISTS demo_class_fee TEXT,
ADD COLUMN IF NOT EXISTS demo_available BOOLEAN DEFAULT FALSE;

-- 2. Set default values for all records first
UPDATE tutor_profiles 
SET 
  subjects = ARRAY[]::TEXT[],
  class_size = ARRAY[]::TEXT[],
  available_days = ARRAY[]::TEXT[],
  student_levels = ARRAY[]::TEXT[],
  curriculum = ARRAY[]::TEXT[],
  highest_qualification = '',
  university = '',
  demo_class_fee = '',
  demo_available = FALSE;

-- 3. Try to parse qualifications if it's JSONB, otherwise leave as defaults
-- First, check if qualifications is JSONB and has data
DO $$
DECLARE
    col_type text;
BEGIN
    -- Get the data type of qualifications column
    SELECT data_type INTO col_type
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tutor_profiles' 
    AND column_name = 'qualifications';
    
    -- If qualifications is JSONB, try to extract data
    IF col_type = 'jsonb' THEN
        -- Update records where qualifications is valid JSONB
        UPDATE tutor_profiles 
        SET 
          subjects = COALESCE(
            CASE 
              WHEN qualifications ? 'subjects' AND jsonb_typeof(qualifications->'subjects') = 'array'
              THEN qualifications->'subjects'
              ELSE '[]'::jsonb
            END::text, '[]'
          )::TEXT[],
          class_size = COALESCE(
            CASE 
              WHEN qualifications ? 'class_size' AND jsonb_typeof(qualifications->'class_size') = 'array'
              THEN qualifications->'class_size'
              ELSE '[]'::jsonb
            END::text, '[]'
          )::TEXT[],
          available_days = COALESCE(
            CASE 
              WHEN qualifications ? 'available_days' AND jsonb_typeof(qualifications->'available_days') = 'array'
              THEN qualifications->'available_days'
              ELSE '[]'::jsonb
            END::text, '[]'
          )::TEXT[],
          student_levels = COALESCE(
            CASE 
              WHEN qualifications ? 'student_levels' AND jsonb_typeof(qualifications->'student_levels') = 'array'
              THEN qualifications->'student_levels'
              ELSE '[]'::jsonb
            END::text, '[]'
          )::TEXT[],
          curriculum = COALESCE(
            CASE 
              WHEN qualifications ? 'curriculum' AND jsonb_typeof(qualifications->'curriculum') = 'array'
              THEN qualifications->'curriculum'
              ELSE '[]'::jsonb
            END::text, '[]'
          )::TEXT[],
          highest_qualification = COALESCE(qualifications->>'highest_qualification', ''),
          university = COALESCE(qualifications->>'university', ''),
          demo_class_fee = COALESCE(qualifications->>'demo_class_fee', ''),
          demo_available = COALESCE((qualifications->>'demo_available')::BOOLEAN, FALSE)
        WHERE qualifications IS NOT NULL 
        AND qualifications != '{}'::jsonb;
        
        RAISE NOTICE 'Updated records with JSONB qualifications data';
    ELSE
        RAISE NOTICE 'Qualifications column is not JSONB (type: %), skipping JSONB extraction', col_type;
    END IF;
END $$;

-- 4. Add indexes for better performance on the restored fields
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_subjects ON tutor_profiles USING GIN(subjects);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_class_size ON tutor_profiles USING GIN(class_size);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_available_days ON tutor_profiles USING GIN(available_days);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_student_levels ON tutor_profiles USING GIN(student_levels);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_curriculum ON tutor_profiles USING GIN(curriculum);

-- 5. Verify the structure was restored
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tutor_profiles'
AND column_name IN ('subjects', 'class_size', 'available_days', 'student_levels', 'curriculum', 'highest_qualification', 'university', 'demo_class_fee', 'demo_available')
ORDER BY column_name;

-- 6. Check if there are any tutor profiles with the restored fields
SELECT 
  COUNT(*) as total_tutors,
  COUNT(subjects) as tutors_with_subjects,
  COUNT(class_size) as tutors_with_class_size,
  COUNT(available_days) as tutors_with_available_days
FROM tutor_profiles;

-- 7. Sample some data to verify it's working
SELECT 
  id,
  user_id,
  subjects,
  class_size,
  available_days,
  student_levels,
  curriculum,
  highest_qualification,
  university,
  demo_class_fee,
  demo_available
FROM tutor_profiles 
LIMIT 3;
