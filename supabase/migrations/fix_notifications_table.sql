-- Fix Notifications Table Migration
-- This migration adds the missing is_read column to the notifications table if it doesn't exist

-- Check if notifications table exists and add missing column if needed
DO $$
BEGIN
    -- Check if the notifications table exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'notifications') THEN
        -- Check if is_read column exists
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'is_read') THEN
            -- Add the missing is_read column
            ALTER TABLE notifications ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
            RAISE NOTICE 'Added missing is_read column to notifications table';
        ELSE
            RAISE NOTICE 'is_read column already exists in notifications table';
        END IF;
    ELSE
        RAISE NOTICE 'notifications table does not exist - run create_requirements_system.sql first';
    END IF;
END $$;

-- Also check and fix the requirements and requirement_tutor_matches tables if they don't exist
DO $$
BEGIN
    -- Check if requirements table exists
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'requirements') THEN
        RAISE NOTICE 'requirements table does not exist - run create_requirements_system.sql first';
    END IF;
    
    -- Check if requirement_tutor_matches table exists
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'requirement_tutor_matches') THEN
        RAISE NOTICE 'requirement_tutor_matches table does not exist - run create_requirements_system.sql first';
    END IF;
END $$;
