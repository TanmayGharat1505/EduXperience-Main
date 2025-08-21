-- Check the actual data type of qualifications field
-- Run this to see what type qualifications actually is

-- 1. Check the data type of qualifications field
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tutor_profiles'
AND column_name = 'qualifications';

-- 2. Check what's actually in the qualifications field
SELECT 
  user_id,
  qualifications,
  pg_typeof(qualifications) as actual_type,
  CASE 
    WHEN qualifications IS NULL THEN 'NULL'
    WHEN qualifications = '' THEN 'EMPTY_STRING'
    ELSE 'HAS_VALUE'
  END as status
FROM tutor_profiles 
LIMIT 5;

-- 3. Check if qualifications is actually JSONB or TEXT
SELECT 
  'qualifications_is_jsonb' as check_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tutor_profiles' 
    AND column_name = 'qualifications'
    AND data_type = 'jsonb'
  ) as is_jsonb
UNION ALL
SELECT 
  'qualifications_is_text' as check_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tutor_profiles' 
    AND column_name = 'qualifications'
    AND data_type = 'text'
  ) as is_text;
