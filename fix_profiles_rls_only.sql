-- Fix ONLY the profiles table RLS policies for new user registration
-- This script focuses on fixing the profiles table access issue

-- 1. Check current RLS policies on profiles table
SELECT 'Current RLS Policies on Profiles Table:' as info;
SELECT 
  policyname,
  cmd,
  permissive,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 2. Drop ALL existing policies on profiles table to start fresh
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Allow new user profile creation" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON profiles;
DROP POLICY IF EXISTS "Public can view basic profile info" ON profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON profiles;

-- 3. Create new, working RLS policies for profiles table

-- Policy 1: Allow users to insert their own profile (CRITICAL for new user registration)
CREATE POLICY "profiles_insert_policy" ON profiles
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Policy 2: Allow users to view their own profile
CREATE POLICY "profiles_select_own_policy" ON profiles
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Policy 3: Allow users to update their own profile
CREATE POLICY "profiles_update_own_policy" ON profiles
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- Policy 4: Allow users to delete their own profile
CREATE POLICY "profiles_delete_own_policy" ON profiles
  FOR DELETE 
  USING (auth.uid() = user_id);

-- Policy 5: Allow public viewing of basic profile information (for search/discovery)
CREATE POLICY "profiles_select_public_policy" ON profiles
  FOR SELECT 
  USING (true);

-- Policy 6: Allow admins to manage all profiles
CREATE POLICY "profiles_admin_policy" ON profiles
  FOR ALL 
  USING (auth.role() = 'admin');

-- 4. Verify the new policies are in place
SELECT 'Updated RLS Policies on Profiles Table:' as info;
SELECT 
  policyname,
  cmd,
  permissive,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 5. Test if RLS is working correctly
SELECT 'RLS Status Check:' as info;
SELECT 
  'Profiles table RLS enabled:' as test,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'profiles' 
    AND rowsecurity = true
  ) THEN 'YES' ELSE 'NO' END as result;

-- 6. Show summary of what we fixed
SELECT 'Summary of Profiles RLS Fixes:' as info;
SELECT 
  '1. Dropped all existing restrictive policies' as fix UNION ALL
  SELECT '2. Created new INSERT policy for new user registration' UNION ALL
  SELECT '3. Created SELECT policy for users to view own profiles' UNION ALL
  SELECT '4. Created UPDATE policy for users to update own profiles' UNION ALL
  SELECT '5. Created DELETE policy for users to delete own profiles' UNION ALL
  SELECT '6. Created public SELECT policy for search/discovery' UNION ALL
  SELECT '7. Created admin policy for full access';
