-- Test script for tutor profile migration
-- Run this after running the main migration to verify it worked

-- Check if all the missing columns were added
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles' 
AND column_name IN (
    'currently_teaching',
    'demo_class',
    'demo_class_fee',
    'current_teaching_place',
    'title',
    'mobile_number',
    'date_of_birth',
    'gender',
    'pin_code',
    'highest_qualification',
    'university_name',
    'year_of_passing',
    'percentage',
    'teaching_experience',
    'subjects',
    'student_levels',
    'curriculum',
    'class_type',
    'max_travel_distance',
    'class_size',
    'available_days',
    'individual_fee',
    'group_fee',
    'home_tuition_fee',
    'assignment_help',
    'test_preparation',
    'homework_support',
    'weekend_classes',
    'profile_headline',
    'teaching_methodology',
    'why_choose_me',
    'languages',
    'profile_photo_url'
)
ORDER BY column_name;

-- Check if the table structure looks correct
SELECT 
    COUNT(*) as total_columns
FROM information_schema.columns 
WHERE table_name = 'tutor_profiles';

-- Check what users exist in public_users table
SELECT 
    id,
    email,
    role,
    created_at
FROM public_users 
LIMIT 5;

-- Check if there are any existing tutor profiles
SELECT 
    COUNT(*) as existing_tutor_profiles
FROM tutor_profiles;

-- If we have existing users, use the first one for testing
-- Otherwise, we'll just test the column structure without inserting data
DO $$
DECLARE
    test_user_id UUID;
    user_count INTEGER;
BEGIN
    -- Check if we have any users
    SELECT COUNT(*) INTO user_count FROM public_users;
    
    IF user_count > 0 THEN
        -- Get the first available user ID
        SELECT id INTO test_user_id FROM public_users LIMIT 1;
        
        RAISE NOTICE 'Found existing user with ID: %', test_user_id;
        
        -- Test inserting a sample tutor profile with the new columns
        INSERT INTO tutor_profiles (
            user_id,
            title,
            mobile_number,
            bio,
            experience_years,
            hourly_rate_min,
            hourly_rate_max,
            currently_teaching,
            demo_class,
            demo_class_fee,
            current_teaching_place,
            subjects,
            class_type,
            verified
        ) VALUES (
            test_user_id,
            'Experienced Math Tutor',
            '+91-9876543210',
            'I am an experienced mathematics tutor with 5 years of teaching experience.',
            5,
            500.00,
            800.00,
            'Yes',
            'Yes',
            200.00,
            'Home and Online',
            ARRAY['Mathematics', 'Physics'],
            'Both',
            false
        );
        
        RAISE NOTICE 'Test tutor profile inserted successfully!';
        
        -- Clean up test data
        DELETE FROM tutor_profiles WHERE title = 'Experienced Math Tutor';
        RAISE NOTICE 'Test data cleaned up successfully!';
        
    ELSE
        RAISE NOTICE 'No users found in public_users table. Skipping insert test.';
    END IF;
END $$;

-- Final verification
SELECT 'Migration test completed successfully!' as status;
