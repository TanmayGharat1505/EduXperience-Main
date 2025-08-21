-- Debug Requirements System
-- Run this in Supabase SQL Editor to check what's happening

-- 1. Check if tables exist
SELECT 
    table_name,
    CASE WHEN table_name IS NOT NULL THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM information_schema.tables 
WHERE table_name IN ('requirements', 'requirement_tutor_matches', 'notifications');

-- 2. Check if requirements table has data
SELECT 
    COUNT(*) as total_requirements,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_requirements
FROM requirements;

-- 3. Check sample requirement data
SELECT 
    id,
    subject,
    location,
    category,
    status,
    created_at,
    student_id
FROM requirements 
WHERE status = 'active' 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. Check tutor profiles to see what subjects they teach (simplified)
SELECT 
    tp.user_id,
    tp.subjects,
    p.full_name,
    p.city,
    p.area
FROM tutor_profiles tp
JOIN profiles p ON tp.user_id = p.user_id
LIMIT 5;

-- 5. Check if there are any requirement_tutor_matches
SELECT 
    COUNT(*) as total_matches,
    COUNT(CASE WHEN status = 'interested' THEN 1 END) as interested_matches,
    COUNT(CASE WHEN status = 'not_interested' THEN 1 END) as declined_matches
FROM requirement_tutor_matches;

-- 6. Check what columns exist in tutor_profiles table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
ORDER BY ordinal_position;

-- 7. Check what columns exist in profiles table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;

-- 8. Check notifications for new requirements
SELECT 
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN type = 'new_requirement' THEN 1 END) as requirement_notifications,
    COUNT(CASE WHEN type = 'requirement_response' THEN 1 END) as response_notifications
FROM notifications;
