-- Fixed Restore - Correct Data Types
-- Based on the actual database schema where class_size is INTEGER

-- 1. Add back the missing fields with correct data types
ALTER TABLE tutor_profiles 
ADD COLUMN IF NOT EXISTS subjects TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS class_size INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS available_days TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS student_levels TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS curriculum TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN IF NOT EXISTS highest_qualification TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS university TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS demo_class_fee TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS demo_available BOOLEAN DEFAULT FALSE;

-- 2. Add indexes for better performance (correct types)
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_subjects ON tutor_profiles USING GIN(subjects);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_class_size ON tutor_profiles(class_size); -- Regular B-tree for INTEGER
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_available_days ON tutor_profiles USING GIN(available_days);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_student_levels ON tutor_profiles USING GIN(student_levels);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_curriculum ON tutor_profiles USING GIN(curriculum);

-- 3. Verify the structure was restored
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tutor_profiles'
AND column_name IN ('subjects', 'class_size', 'available_days', 'student_levels', 'curriculum', 'highest_qualification', 'university', 'demo_class_fee', 'demo_available')
ORDER BY column_name;

-- 4. Check the current state
SELECT 
  COUNT(*) as total_tutors,
  COUNT(subjects) as tutors_with_subjects,
  COUNT(class_size) as tutors_with_class_size,
  COUNT(available_days) as tutors_with_available_days
FROM tutor_profiles;

-- 5. Show a sample record
SELECT 
  id,
  user_id,
  bio,
  experience_years,
  hourly_rate_min,
  teaching_mode,
  rating,
  verified,
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
LIMIT 1;
