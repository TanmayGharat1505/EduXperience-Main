-- Create Admin Users Table
-- This script creates the users table that the admin dashboard needs to function

-- 1. Create the users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'tutor', 'institution', 'admin')),
  verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_verification_status ON users(verification_status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- 3. Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies
CREATE POLICY "Admins can manage all users" ON users
  FOR ALL 
  USING (auth.role() = 'admin');

CREATE POLICY "Users can view own record" ON users
  FOR SELECT 
  USING (auth.uid() = user_id);

-- 5. Create a function to populate users table from existing data
CREATE OR REPLACE FUNCTION populate_users_table()
RETURNS void AS $$
DECLARE
  auth_user RECORD;
  profile_record RECORD;
  tutor_profile_record RECORD;
  institution_profile_record RECORD;
  user_role TEXT;
  verification_status TEXT;
BEGIN
  -- Clear existing data
  DELETE FROM users;
  
  -- Loop through all auth users
  FOR auth_user IN SELECT * FROM auth.users LOOP
    -- Try to find profile information
    SELECT role INTO profile_record FROM profiles WHERE user_id = auth_user.id LIMIT 1;
    
    -- Try to find tutor profile
    SELECT verified INTO tutor_profile_record FROM tutor_profiles WHERE user_id = auth_user.id LIMIT 1;
    
    -- Try to find institution profile
    SELECT verified INTO institution_profile_record FROM institution_profiles WHERE user_id = auth_user.id LIMIT 1;
    
    -- Determine role
    IF profile_record.role IS NOT NULL THEN
      user_role := profile_record.role;
    ELSE
      -- Try to infer role from existing profiles
      IF EXISTS (SELECT 1 FROM tutor_profiles WHERE user_id = auth_user.id) THEN
        user_role := 'tutor';
      ELSIF EXISTS (SELECT 1 FROM institution_profiles WHERE user_id = auth_user.id) THEN
        user_role := 'institution';
      ELSE
        user_role := 'student'; -- Default to student if no other role found
      END IF;
    END IF;
    
    -- Determine verification status
    IF user_role = 'student' THEN
      verification_status := 'approved'; -- Students are auto-approved
    ELSIF user_role = 'tutor' THEN
      IF tutor_profile_record.verified IS NOT NULL THEN
        verification_status := CASE WHEN tutor_profile_record.verified THEN 'approved' ELSE 'pending' END;
      ELSE
        verification_status := 'pending';
      END IF;
    ELSIF user_role = 'institution' THEN
      IF institution_profile_record.verified IS NOT NULL THEN
        verification_status := CASE WHEN institution_profile_record.verified THEN 'approved' ELSE 'pending' END;
      ELSE
        verification_status := 'pending';
      END IF;
    ELSE
      verification_status := 'pending';
    END IF;
    
    -- Insert user record
    INSERT INTO users (id, user_id, email, role, verification_status, created_at, updated_at)
    VALUES (
      auth_user.id,
      auth_user.id,
      COALESCE(auth_user.email, 'unknown@example.com'),
      user_role,
      verification_status,
      auth_user.created_at,
      COALESCE(auth_user.updated_at, auth_user.created_at)
    );
    
  END LOOP;
  
  RAISE NOTICE 'Users table populated with % records', (SELECT COUNT(*) FROM users);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Execute the function to populate the table
SELECT populate_users_table();

-- 7. Verify the data was created
SELECT '=== USERS TABLE POPULATED ===' as status;
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'student' THEN 1 END) as students,
  COUNT(CASE WHEN role = 'tutor' THEN 1 END) as tutors,
  COUNT(CASE WHEN role = 'institution' THEN 1 END) as institutions,
  COUNT(CASE WHEN verification_status = 'pending' THEN 1 END) as pending,
  COUNT(CASE WHEN verification_status = 'approved' THEN 1 END) as approved,
  COUNT(CASE WHEN verification_status = 'rejected' THEN 1 END) as rejected
FROM users;

-- 8. Show sample data
SELECT '=== SAMPLE USER DATA ===' as status;
SELECT 
  email,
  role,
  verification_status,
  created_at
FROM users 
ORDER BY created_at DESC 
LIMIT 5;

-- 9. Clean up the function (optional)
-- DROP FUNCTION IF EXISTS populate_users_table();
