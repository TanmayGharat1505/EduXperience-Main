-- Add profile_completion_percentage field to tutor_profiles table
ALTER TABLE tutor_profiles 
ADD COLUMN IF NOT EXISTS profile_completion_percentage INTEGER DEFAULT 0;

-- Update existing records to have a default value
UPDATE tutor_profiles 
SET profile_completion_percentage = 0 
WHERE profile_completion_percentage IS NULL;

-- Add a check constraint to ensure the percentage is between 0 and 100
ALTER TABLE tutor_profiles 
ADD CONSTRAINT tutor_profiles_profile_completion_check 
CHECK (profile_completion_percentage >= 0 AND profile_completion_percentage <= 100);
