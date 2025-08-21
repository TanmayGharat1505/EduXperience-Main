-- Restore Tutor Profiles Fields - TEXT Qualifications Version
-- Since qualifications is TEXT, not JSONB, we'll handle it differently

-- 1. Add back the missing fields with default values
ALTER TABLE tutor_profiles 
ADD COLUMN IF NOT EXISTS subjects TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS class_size TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS available_days TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS student_levels TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS curriculum TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS highest_qualification TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS university TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS demo_class_fee TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS demo_available BOOLEAN DEFAULT FALSE;

-- 2. Try to parse qualifications TEXT field if it contains JSON-like data
-- This handles cases where qualifications might contain JSON strings
UPDATE tutor_profiles 
SET 
  subjects = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"subjects"%' 
    THEN COALESCE(
      (SELECT string_to_array(
        regexp_replace(
          regexp_replace(
            regexp_replace(qualifications, '.*"subjects"\s*:\s*\[([^\]]*)\].*', '\1', 'g'),
            '"', '', 'g'
          ),
          ',', ' '
        )
      ), ARRAY[]::TEXT[])
    ELSE ARRAY[]::TEXT[]
  END,
  
  class_size = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"class_size"%' 
    THEN COALESCE(
      (SELECT string_to_array(
        regexp_replace(
          regexp_replace(
            regexp_replace(qualifications, '.*"class_size"\s*:\s*\[([^\]]*)\].*', '\1', 'g'),
            '"', '', 'g'
          ),
          ',', ' '
        )
      ), ARRAY[]::TEXT[])
    ELSE ARRAY[]::TEXT[]
  END,
  
  available_days = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"available_days"%' 
    THEN COALESCE(
      (SELECT string_to_array(
        regexp_replace(
          regexp_replace(
            regexp_replace(qualifications, '.*"available_days"\s*:\s*\[([^\]]*)\].*', '\1', 'g'),
            '"', '', 'g'
          ),
          ',', ' '
        )
      ), ARRAY[]::TEXT[])
    ELSE ARRAY[]::TEXT[]
  END,
  
  student_levels = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"student_levels"%' 
    THEN COALESCE(
      (SELECT string_to_array(
        regexp_replace(
          regexp_replace(
            regexp_replace(qualifications, '.*"student_levels"\s*:\s*\[([^\]]*)\].*', '\1', 'g'),
            '"', '', 'g'
          ),
          ',', ' '
        )
      ), ARRAY[]::TEXT[])
    ELSE ARRAY[]::TEXT[]
  END,
  
  curriculum = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"curriculum"%' 
    THEN COALESCE(
      (SELECT string_to_array(
        regexp_replace(
          regexp_replace(
            regexp_replace(qualifications, '.*"curriculum"\s*:\s*\[([^\]]*)\].*', '\1', 'g'),
            '"', '', 'g'
          ),
          ',', ' '
        )
      ), ARRAY[]::TEXT[])
    ELSE ARRAY[]::TEXT[]
  END,
  
  highest_qualification = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"highest_qualification"%' 
    THEN COALESCE(
      regexp_replace(
        regexp_replace(qualifications, '.*"highest_qualification"\s*:\s*"([^"]*)".*', '\1', 'g'),
        'highest_qualification', ''
      ), ''
    )
    ELSE ''
  END,
  
  university = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"university"%' 
    THEN COALESCE(
      regexp_replace(
        regexp_replace(qualifications, '.*"university"\s*:\s*"([^"]*)".*', '\1', 'g'),
        'university', ''
      ), ''
    )
    ELSE ''
  END,
  
  demo_class_fee = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"demo_class_fee"%' 
    THEN COALESCE(
      regexp_replace(
        regexp_replace(qualifications, '.*"demo_class_fee"\s*:\s*"([^"]*)".*', '\1', 'g'),
        'demo_class_fee', ''
      ), ''
    )
    ELSE ''
  END,
  
  demo_available = CASE 
    WHEN qualifications IS NOT NULL AND qualifications != '' 
    AND qualifications LIKE '%"demo_available"%' 
    THEN COALESCE(
      CASE 
        WHEN qualifications LIKE '%"demo_available":true%' THEN TRUE
        WHEN qualifications LIKE '%"demo_available":false%' THEN FALSE
        ELSE FALSE
      END, FALSE
    )
    ELSE FALSE
  END
WHERE qualifications IS NOT NULL AND qualifications != '';

-- 3. Add indexes for better performance on the restored fields
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_subjects ON tutor_profiles USING GIN(subjects);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_class_size ON tutor_profiles USING GIN(class_size);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_available_days ON tutor_profiles USING GIN(available_days);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_student_levels ON tutor_profiles USING GIN(student_levels);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_curriculum ON tutor_profiles USING GIN(curriculum);

-- 4. Verify the structure was restored
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tutor_profiles'
AND column_name IN ('subjects', 'class_size', 'available_days', 'student_levels', 'curriculum', 'highest_qualification', 'university', 'demo_class_fee', 'demo_available')
ORDER BY column_name;

-- 5. Check if there are any tutor profiles with the restored fields
SELECT 
  COUNT(*) as total_tutors,
  COUNT(subjects) as tutors_with_subjects,
  COUNT(class_size) as tutors_with_class_size,
  COUNT(available_days) as tutors_with_available_days
FROM tutor_profiles;

-- 6. Sample some data to verify it's working
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
