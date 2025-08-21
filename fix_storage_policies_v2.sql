-- Fix Storage Bucket Policies for Verification System - V2
-- This version works with the actual folder structure: {requestId}/{fileName}
-- Run this in your Supabase SQL Editor

-- 1. First, let's check if the bucket exists and create it properly
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'verification-documents', 
    'verification-documents', 
    false, 
    52428800, -- 50MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
)
ON CONFLICT (id) DO UPDATE SET
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Drop existing storage policies
DROP POLICY IF EXISTS "Users can upload own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all verification documents" ON storage.objects;

-- 3. Create storage policies that work with the requestId folder structure
-- Users can upload to any folder that corresponds to their verification request
CREATE POLICY "Users can upload own verification documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'verification-documents' 
        AND EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = (storage.foldername(name))[1]::uuid
            AND verification_requests.user_id = auth.uid()
        )
    );

-- Users can view documents from their own verification requests
CREATE POLICY "Users can view own verification documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'verification-documents' 
        AND (
            -- Allow viewing own verification request documents
            EXISTS (
                SELECT 1 FROM verification_requests 
                WHERE verification_requests.id = (storage.foldername(name))[1]::uuid
                AND verification_requests.user_id = auth.uid()
            )
            OR
            -- Allow admins to view everything
            EXISTS (
                SELECT 1 FROM profiles 
                WHERE profiles.user_id = auth.uid() 
                AND profiles.role = 'admin'
            )
        )
    );

-- Users can update documents from their own verification requests
CREATE POLICY "Users can update own verification documents" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'verification-documents' 
        AND EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = (storage.foldername(name))[1]::uuid
            AND verification_requests.user_id = auth.uid()
        )
    );

-- Users can delete documents from their own verification requests
CREATE POLICY "Users can delete own verification documents" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'verification-documents' 
        AND EXISTS (
            SELECT 1 FROM verification_requests 
            WHERE verification_requests.id = (storage.foldername(name))[1]::uuid
            AND verification_requests.user_id = auth.uid()
        )
    );

-- 4. Alternative: Create a simpler policy that allows authenticated users to upload
-- This is less secure but easier to debug
-- Uncomment the lines below if the above policies still don't work

/*
-- Simple policy for testing - allows any authenticated user to upload
CREATE POLICY "Allow authenticated uploads" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'verification-documents' 
        AND auth.role() = 'authenticated'
    );

-- Simple policy for viewing - allows users to see their own files
CREATE POLICY "Allow authenticated viewing" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'verification-documents' 
        AND auth.role() = 'authenticated'
    );
*/

-- 5. Test the storage policies
-- You can test by running these queries to see the bucket configuration:
-- SELECT * FROM storage.buckets WHERE id = 'verification-documents';

-- 6. Check if there are any existing objects that might conflict
-- SELECT * FROM storage.objects WHERE bucket_id = 'verification-documents' LIMIT 5;

-- 7. Check the verification_requests table to ensure it exists and has data
-- SELECT COUNT(*) FROM verification_requests;
-- SELECT * FROM verification_requests LIMIT 3;
