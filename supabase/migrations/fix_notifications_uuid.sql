-- Fix UUID generation issue in notifications table

-- First, let's check if the gen_random_uuid() function is available
DO $$
BEGIN
    -- Check if gen_random_uuid function exists
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'gen_random_uuid') THEN
        -- Create the gen_random_uuid function if it doesn't exist
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    END IF;
END $$;

-- Update the notifications table to ensure proper UUID generation
ALTER TABLE notifications 
ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Ensure the id column is properly configured
ALTER TABLE notifications 
ALTER COLUMN id SET NOT NULL;

-- Add a trigger to ensure UUID generation if needed
CREATE OR REPLACE FUNCTION ensure_notification_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id IS NULL THEN
        NEW.id := gen_random_uuid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop the trigger if it exists
DROP TRIGGER IF EXISTS ensure_notification_id_trigger ON notifications;

-- Create the trigger
CREATE TRIGGER ensure_notification_id_trigger
    BEFORE INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION ensure_notification_id();

-- Also ensure the RLS policies don't interfere with UUID generation
-- Update the insert policy to be more permissive
DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON notifications;
CREATE POLICY "Authenticated users can insert notifications" ON notifications
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON notifications TO authenticated; 