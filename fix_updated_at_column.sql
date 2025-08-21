-- Quick fix: Add missing updated_at column to tutor_profiles
-- Run this in your Supabase SQL Editor to fix the schema cache error

-- Add the missing updated_at column
ALTER TABLE tutor_profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Verify the column was added
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
AND column_name = 'updated_at';

-- Update existing records to have a current timestamp
UPDATE tutor_profiles 
SET updated_at = NOW() 
WHERE updated_at IS NULL;

-- Verify the trigger function can now work properly
SELECT 'updated_at column added successfully!' as status;
