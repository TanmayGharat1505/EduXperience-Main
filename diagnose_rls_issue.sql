-- Diagnose RLS Issue - Check Current State
-- This script will show us exactly what's happening with RLS policies

-- 1. Check if profiles table exists and has RLS enabled
SELECT '=== TABLE STATUS ===' as section;
SELECT 
  tablename,
  schemaname,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity = true THEN 'RLS ACTIVE - This is blocking us!'
    ELSE 'RLS Disabled - This should allow access'
  END as rls_status
FROM pg_tables 
WHERE tablename = 'profiles';

-- 2. Check ALL existing RLS policies on profiles table
SELECT '=== CURRENT RLS POLICIES ON PROFILES ===' as section;
SELECT 
  policyname,
  cmd,
  permissive,
  qual,
  with_check,
  CASE 
    WHEN cmd = 'INSERT' THEN 'INSERT Policy - This controls new user creation'
    WHEN cmd = 'SELECT' THEN 'SELECT Policy - This controls viewing'
    WHEN cmd = 'UPDATE' THEN 'UPDATE Policy - This controls editing'
    WHEN cmd = 'DELETE' THEN 'DELETE Policy - This controls deletion'
    ELSE 'Other Policy'
  END as policy_purpose
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY cmd;

-- 3. Check if there are any policies at all
SELECT '=== POLICY COUNT ===' as section;
SELECT 
  COUNT(*) as total_policies,
  CASE 
    WHEN COUNT(*) = 0 THEN 'NO POLICIES - This means RLS is blocking everything!'
    ELSE 'Has policies - Check if they are restrictive'
  END as policy_status
FROM pg_policies 
WHERE tablename = 'profiles';

-- 4. Check if auth.uid() function exists and works
SELECT '=== AUTH FUNCTION CHECK ===' as section;
SELECT 
  'auth.uid() function exists:' as test,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'uid' 
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'auth')
  ) THEN 'YES' ELSE 'NO - This is a problem!' END as result;

-- 5. Check if we can see the auth schema
SELECT '=== AUTH SCHEMA CHECK ===' as section;
SELECT 
  nspname as schema_name,
  CASE 
    WHEN nspname = 'auth' THEN 'Auth schema exists'
    ELSE 'Other schema'
  END as schema_status
FROM pg_namespace 
WHERE nspname = 'auth';

-- 6. Check if profiles table has the right columns
SELECT '=== PROFILES TABLE STRUCTURE ===' as section;
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- 7. Check if there are any triggers or constraints blocking insertion
SELECT '=== TRIGGERS AND CONSTRAINTS ===' as section;
SELECT 
  'Triggers on profiles:' as check_type,
  COUNT(*) as count
FROM pg_trigger 
WHERE tgrelid = (SELECT oid FROM pg_class WHERE relname = 'profiles');

-- 8. Check if there are any foreign key constraints
SELECT '=== FOREIGN KEY CONSTRAINTS ===' as section;
SELECT 
  conname as constraint_name,
  confrelid::regclass as referenced_table
FROM pg_constraint 
WHERE conrelid = (SELECT oid FROM pg_class WHERE relname = 'profiles')
AND contype = 'f';

-- 9. Show the exact error we're getting
SELECT '=== EXPECTED ERROR ANALYSIS ===' as section;
SELECT 
  'Current Error: new row violates row-level security policy for table "profiles"' as error_message,
  'This means:' as analysis,
  '1. RLS is enabled on profiles table' as cause_1,
  '2. No INSERT policy exists OR policy is too restrictive' as cause_2,
  '3. User cannot insert into profiles table' as result;

-- 10. Show what we need to do
SELECT '=== SOLUTION STEPS ===' as section;
SELECT 
  'Step 1: Disable RLS temporarily to test' as action_1,
  'Step 2: Create proper INSERT policy' as action_2,
  'Step 3: Test insertion works' as action_3,
  'Step 4: Re-enable RLS with correct policies' as action_4;
