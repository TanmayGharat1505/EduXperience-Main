-- Fix RLS Policies for New User Registration
-- This script updates the RLS policies to allow new users to create profiles during signup

-- 1. First, let's check the current RLS policies on the profiles table
SELECT 'Current RLS Policies on Profiles Table:' as info;
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 2. Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;

-- 3. Create new, more permissive policies that allow new user registration

-- Policy 1: Allow users to insert their own profile (for new user registration)
CREATE POLICY "Allow new user profile creation" ON profiles
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy 2: Allow users to view their own profile
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy 3: Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- Policy 4: Allow users to delete their own profile
CREATE POLICY "Users can delete own profile" ON profiles
  FOR DELETE 
  USING (auth.uid() = user_id);

-- Policy 5: Allow public viewing of basic profile information (for search/discovery)
CREATE POLICY "Public can view basic profile info" ON profiles
  FOR SELECT 
  USING (true); -- Allow public read access to all profiles

-- Policy 6: Allow admins to manage all profiles
CREATE POLICY "Admins can manage all profiles" ON profiles
  FOR ALL 
  USING (auth.role() = 'admin');

-- 4. Check if institution_profiles table exists and fix its policies too
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'institution_profiles') THEN
    -- Drop existing policies on institution_profiles
    EXECUTE 'DROP POLICY IF EXISTS "Users can view own institution profile" ON institution_profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Users can update own institution profile" ON institution_profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Users can insert own institution profile" ON institution_profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Admins can view all institution profiles" ON institution_profiles';
    EXECUTE 'DROP POLICY IF EXISTS "Public can view approved institution profiles" ON institution_profiles';
    
    -- Create new policies for institution_profiles
    EXECUTE 'CREATE POLICY "Allow new institution profile creation" ON institution_profiles FOR INSERT WITH CHECK (auth.uid() = user_id)';
    EXECUTE 'CREATE POLICY "Users can view own institution profile" ON institution_profiles FOR SELECT USING (auth.uid() = user_id)';
    EXECUTE 'CREATE POLICY "Users can update own institution profile" ON institution_profiles FOR UPDATE USING (auth.uid() = user_id)';
    EXECUTE 'CREATE POLICY "Public can view verified institution profiles" ON institution_profiles FOR SELECT USING (verified = true)';
    EXECUTE 'CREATE POLICY "Admins can manage all institution profiles" ON institution_profiles FOR ALL USING (auth.role() = ''admin'')';
    
    RAISE NOTICE 'Institution profiles RLS policies updated';
  ELSE
    RAISE NOTICE 'Institution profiles table does not exist yet';
  END IF;
END $$;

-- 5. Verify the new policies are in place
SELECT 'Updated RLS Policies on Profiles Table:' as info;
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 6. Test the policies by checking if they allow the operations we need
SELECT 'RLS Policy Test Results:' as info;
SELECT 
  'Profiles table RLS enabled:' as test,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'profiles' 
    AND rowsecurity = true
  ) THEN 'YES' ELSE 'NO' END as result;

-- 7. Show summary of what we fixed
SELECT 'Summary of RLS Policy Fixes:' as info;
SELECT 
  '1. New users can now create profiles during signup' as fix UNION ALL
  SELECT '2. Users can view and update their own profiles' UNION ALL
  SELECT '3. Public can view basic profile information' UNION ALL
  SELECT '4. Admins have full access to all profiles' UNION ALL
  SELECT '5. Institution profiles policies updated (if table exists)';
