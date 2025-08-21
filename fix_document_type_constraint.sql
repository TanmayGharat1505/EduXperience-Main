-- Fix Document Type Constraint Issue
-- Run this in your Supabase SQL Editor

-- 1. First, let's see what the current constraint looks like
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'verification_documents'::regclass 
AND conname = 'verification_documents_document_type_check';

-- 2. Let's see what document types are currently being sent
-- Check the console logs in your browser to see what documentType values are being sent

-- 3. Let's see the current table structure
\d verification_documents

-- 4. Drop the existing constraint if it's too restrictive
ALTER TABLE verification_documents DROP CONSTRAINT IF EXISTS verification_documents_document_type_check;

-- 5. Create a more flexible constraint that allows common document types
ALTER TABLE verification_documents ADD CONSTRAINT verification_documents_document_type_check 
CHECK (document_type IN (
    'governmentId',
    'academicCertificates', 
    'teachingCertificates',
    'registrationCertificate',
    'taxId',
    'locationProof',
    'accreditationProof',
    'demoVideo',
    'other'
));

-- 6. Alternative: If you want to allow any string, you can remove the constraint entirely
-- ALTER TABLE verification_documents DROP CONSTRAINT IF EXISTS verification_documents_document_type_check;

-- 7. Test the constraint
-- Try inserting a test record to see if it works
-- INSERT INTO verification_documents (
--     verification_request_id, 
--     document_type, 
--     document_name, 
--     file_url, 
--     file_size, 
--     mime_type, 
--     is_required
-- ) VALUES (
--     '00000000-0000-0000-0000-000000000000', -- dummy UUID
--     'governmentId',
--     'test.pdf',
--     'https://example.com/test.pdf',
--     1024,
--     'application/pdf',
--     true
-- );

-- 8. Check what document types are being sent from the frontend
-- Look at your browser console to see the console.log output from verification-service.ts
