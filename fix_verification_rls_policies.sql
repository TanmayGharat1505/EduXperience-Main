-- Fix RLS Policies for Verification System
-- Run this in your Supabase SQL Editor

-- 1. Enable RLS on verification tables (if not already enabled)
ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_references ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_proficiency_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_workflow_logs ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies (if any) to recreate them properly
DROP POLICY IF EXISTS "Users can view own verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Users can create own verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Users can update own verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Admins can view all verification requests" ON verification_requests;
DROP POLICY IF EXISTS "Admins can update all verification requests" ON verification_requests;

DROP POLICY IF EXISTS "Users can view own verification documents" ON verification_documents;
DROP POLICY IF EXISTS "Users can create own verification documents" ON verification_documents;
DROP POLICY IF EXISTS "Users can update own verification documents" ON verification_documents;
DROP POLICY IF EXISTS "Admins can view all verification documents" ON verification_documents;
DROP POLICY IF EXISTS "Admins can update all verification documents" ON verification_documents;

DROP POLICY IF EXISTS "Users can view own verification references" ON verification_references;
DROP POLICY IF EXISTS "Users can create own verification references" ON verification_references;
DROP POLICY IF EXISTS "Users can update own verification references" ON verification_references;
DROP POLICY IF EXISTS "Admins can view all verification references" ON verification_references;
DROP POLICY IF EXISTS "Admins can update all verification references" ON verification_references;

DROP POLICY IF EXISTS "Users can view proficiency tests" ON subject_proficiency_tests;
DROP POLICY IF EXISTS "Admins can manage proficiency tests" ON subject_proficiency_tests;

DROP POLICY IF EXISTS "Users can view test questions" ON test_questions;
DROP POLICY IF EXISTS "Admins can manage test questions" ON test_questions;

DROP POLICY IF EXISTS "Users can view own test attempts" ON test_attempts;
DROP POLICY IF EXISTS "Users can create own test attempts" ON test_attempts;
DROP POLICY IF EXISTS "Admins can view all test attempts" ON test_attempts;
DROP POLICY IF EXISTS "Admins can update test attempts" ON test_attempts;

DROP POLICY IF EXISTS "Users can view own workflow logs" ON verification_workflow_logs;
DROP POLICY IF EXISTS "Admins can view all workflow logs" ON verification_workflow_logs;

-- 3. Create proper RLS policies for verification_requests
CREATE POLICY "Users can view own verification requests" ON verification_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own verification requests" ON verification_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own verification requests" ON verification_requests
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all verification requests" ON verification_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can update all verification requests" ON verification_requests
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 4. Create proper RLS policies for verification_documents
CREATE POLICY "Users can view own verification documents" ON verification_documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = verification_documents.verification_request_id 
            AND verification_requests.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create own verification documents" ON verification_documents
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = verification_documents.verification_request_id 
            AND verification_requests.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own verification documents" ON verification_documents
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = verification_documents.verification_request_id 
            AND verification_requests.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all verification documents" ON verification_documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can update all verification documents" ON verification_documents
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 5. Create proper RLS policies for verification_references
CREATE POLICY "Users can view own verification references" ON verification_references
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = verification_references.verification_request_id 
            AND verification_requests.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create own verification references" ON verification_references
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = verification_references.verification_request_id 
            AND verification_requests.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own verification references" ON verification_references
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = verification_references.verification_request_id 
            AND verification_requests.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all verification references" ON verification_references
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can update all verification references" ON verification_references
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 6. Create policies for subject_proficiency_tests
CREATE POLICY "Users can view proficiency tests" ON subject_proficiency_tests
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage proficiency tests" ON subject_proficiency_tests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 7. Create policies for test_questions
CREATE POLICY "Users can view test questions" ON test_questions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM subject_proficiency_tests 
            WHERE subject_proficiency_tests.id = test_questions.test_id 
            AND subject_proficiency_tests.is_active = true
        )
    );

CREATE POLICY "Admins can manage test questions" ON test_questions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 8. Create policies for test_attempts
CREATE POLICY "Users can view own test attempts" ON test_attempts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own test attempts" ON test_attempts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all test attempts" ON test_attempts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

CREATE POLICY "Admins can update test attempts" ON test_attempts
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 9. Create policies for verification_workflow_logs
CREATE POLICY "Users can view own workflow logs" ON verification_workflow_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = verification_workflow_logs.verification_request_id 
            AND verification_requests.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all workflow logs" ON verification_workflow_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.user_id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 10. Create storage bucket policies for verification-documents
-- First, create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('verification-documents', 'verification-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Create storage policies for verification-documents bucket
CREATE POLICY "Users can upload own verification documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'verification-documents' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view own verification documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'verification-documents' 
        AND (
            auth.uid()::text = (storage.foldername(name))[1]
            OR EXISTS (
                SELECT 1 FROM profiles 
                WHERE profiles.user_id = auth.uid() 
                AND profiles.role = 'admin'
            )
        )
    );

CREATE POLICY "Users can update own verification documents" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'verification-documents' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete own verification documents" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'verification-documents' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- 11. Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON verification_requests TO authenticated;
GRANT ALL ON verification_documents TO authenticated;
GRANT ALL ON verification_references TO authenticated;
GRANT ALL ON subject_proficiency_tests TO authenticated;
GRANT ALL ON test_questions TO authenticated;
GRANT ALL ON test_attempts TO authenticated;
GRANT ALL ON verification_workflow_logs TO authenticated;

-- 12. Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 13. Test the policies
-- You can test by running these queries as different users:
-- SELECT * FROM verification_requests LIMIT 1;
-- SELECT * FROM verification_documents LIMIT 1;
