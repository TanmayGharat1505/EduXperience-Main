-- Test RLS Policies After Fix
-- This script tests if the RLS policies are working correctly

-- 1. Check if profiles table has the correct RLS policies
SELECT 'Profiles Table RLS Policies Check:' as info;
SELECT 
  policyname,
  cmd,
  permissive,
  CASE 
    WHEN cmd = 'INSERT' AND with_check IS NOT NULL THEN 'INSERT Policy OK'
    WHEN cmd = 'SELECT' AND qual IS NOT NULL THEN 'SELECT Policy OK'
    WHEN cmd = 'UPDATE' AND qual IS NOT NULL THEN 'UPDATE Policy OK'
    WHEN cmd = 'DELETE' AND qual IS NOT NULL THEN 'DELETE Policy OK'
    ELSE 'Policy Check Needed'
  END as status
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY cmd;

-- 2. Check if institution_profiles table has RLS policies
SELECT 'Institution Profiles Table RLS Policies Check:' as info;
SELECT 
  policyname,
  cmd,
  permissive,
  CASE 
    WHEN cmd = 'INSERT' AND with_check IS NOT NULL THEN 'INSERT Policy OK'
    WHEN cmd = 'SELECT' AND qual IS NOT NULL THEN 'SELECT Policy OK'
    WHEN cmd = 'UPDATE' AND qual IS NOT NULL THEN 'UPDATE Policy OK'
    WHEN cmd = 'DELETE' AND qual IS NOT NULL THEN 'DELETE Policy OK'
    ELSE 'Policy Check Needed'
  END as status
FROM pg_policies 
WHERE tablename = 'institution_profiles'
ORDER BY cmd;

-- 3. Check table structure
SELECT 'Table Structure Check:' as info;
SELECT 
  table_name,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity = true THEN 'RLS Active'
    ELSE 'RLS Disabled'
  END as rls_status
FROM pg_tables 
WHERE table_name IN ('profiles', 'institution_profiles')
ORDER BY table_name;

-- 4. Check if auth.uid() function is available
SELECT 'Auth Function Check:' as info;
SELECT 
  'auth.uid() function available:' as test,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'uid' 
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth')
  ) THEN 'YES' ELSE 'NO' END as result;

-- 5. Summary of what should work now
SELECT 'Expected Results After Fix:' as info;
SELECT 
  '1. New users can create profiles during signup' as expected UNION ALL
  SELECT '2. Users can view and update their own profiles' UNION ALL
  SELECT '3. Public can view basic profile information' UNION ALL
  SELECT '4. Institution signup should work without RLS errors' UNION ALL
  SELECT '5. Both profiles and institution_profiles tables accessible';
