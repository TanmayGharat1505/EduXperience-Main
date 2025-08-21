-- Restore Original Tutor Profiles Table Structure
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

-- 2. Update existing records to populate these fields from qualifications JSONB
-- This will migrate existing data to the new columns
UPDATE tutor_profiles 
SET 
  subjects = COALESCE(qualifications->>'subjects', '[]')::TEXT[],
  class_size = COALESCE(qualifications->>'class_size', '[]')::TEXT[],
  available_days = COALESCE(qualifications->>'available_days', '[]')::TEXT[],
  student_levels = COALESCE(qualifications->>'student_levels', '[]')::TEXT[],
  curriculum = COALESCE(qualifications->>'curriculum', '[]')::TEXT[],
  highest_qualification = qualifications->>'highest_qualification',
  university = qualifications->>'university',
  demo_class_fee = qualifications->>'demo_class_fee',
  demo_available = COALESCE((qualifications->>'demo_available')::BOOLEAN, FALSE)
WHERE qualifications IS NOT NULL;

-- 3. Set default values for records where qualifications is NULL
UPDATE tutor_profiles 
SET 
  subjects = ARRAY[]::TEXT[],
  class_size = ARRAY[]::TEXT[],
  available_days = ARRAY[]::TEXT[],
  student_levels = ARRAY[]::TEXT[],
  curriculum = ARRAY[]::TEXT[],
  demo_available = FALSE
WHERE qualifications IS NULL;

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
