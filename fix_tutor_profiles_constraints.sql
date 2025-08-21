-- Fix: Add missing unique constraint on user_id for tutor_profiles table
-- This resolves the "ON CONFLICT specification" error

-- First, check if the constraint already exists
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'tutor_profiles' 
AND constraint_type = 'UNIQUE';

-- Add unique constraint on user_id if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'tutor_profiles' 
        AND constraint_name = 'tutor_profiles_user_id_unique'
        AND constraint_type = 'UNIQUE'
    ) THEN
        ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_user_id_unique UNIQUE (user_id);
        RAISE NOTICE 'Added unique constraint on user_id';
    ELSE
        RAISE NOTICE 'Unique constraint on user_id already exists';
    END IF;
END $$;

-- Verify the constraint was added
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'tutor_profiles' 
AND constraint_type = 'UNIQUE';

-- Also check if we need to add a primary key constraint
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'tutor_profiles' 
AND constraint_type = 'PRIMARY KEY';

-- If no primary key exists, add one on user_id
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'tutor_profiles' 
        AND constraint_type = 'PRIMARY KEY'
    ) THEN
        -- First drop the unique constraint if it exists
        ALTER TABLE tutor_profiles DROP CONSTRAINT IF EXISTS tutor_profiles_user_id_unique;
        -- Then add primary key constraint
        ALTER TABLE tutor_profiles ADD CONSTRAINT tutor_profiles_pkey PRIMARY KEY (user_id);
        RAISE NOTICE 'Added primary key constraint on user_id';
    ELSE
        RAISE NOTICE 'Primary key constraint already exists';
    END IF;
END $$;

-- Final verification
SELECT 'Tutor profiles table constraints fixed successfully!' as status;
