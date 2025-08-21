-- Fix Storage Bucket Policies for Verification System
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

-- 3. Create simplified storage policies for the new folder structure
CREATE POLICY "Users can upload own verification documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'verification-documents' 
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can view own verification documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'verification-documents' 
        AND (
            (storage.foldername(name))[1] = auth.uid()::text
            OR
            -- Allow admins to view everything
            EXISTS (
                SELECT 1 FROM profiles 
                WHERE profiles.user_id = auth.uid() 
                AND profiles.role = 'admin'
            )
        )
    );

CREATE POLICY "Users can update own verification documents" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'verification-documents' 
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Users can delete own verification documents" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'verification-documents' 
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- 4. Test the storage policies
-- You can test by running this query to see the bucket configuration:
-- SELECT * FROM storage.buckets WHERE id = 'verification-documents';

-- 5. Check if there are any existing objects that might conflict
-- SELECT * FROM storage.objects WHERE bucket_id = 'verification-documents' LIMIT 5;
