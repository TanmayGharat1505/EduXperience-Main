-- Test Data Insertion for Admin Dashboard
-- Run this after the main migration to populate tables with sample data

-- First, let's check what columns exist in our tables and add missing ones
DO $$
BEGIN
    -- Add missing columns to users table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT 'user';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'verification_status') THEN
        ALTER TABLE users ADD COLUMN verification_status VARCHAR(50) DEFAULT 'pending';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'created_at') THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add missing columns to reviews table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'status') THEN
        ALTER TABLE reviews ADD COLUMN status VARCHAR(50) DEFAULT 'pending';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'created_at') THEN
        ALTER TABLE reviews ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add missing columns to tutor_profiles table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tutor_profiles' AND column_name = 'status') THEN
        ALTER TABLE tutor_profiles ADD COLUMN status VARCHAR(50) DEFAULT 'pending';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tutor_profiles' AND column_name = 'created_at') THEN
        ALTER TABLE tutor_profiles ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add missing columns to tutor_content table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tutor_content' AND column_name = 'status') THEN
        ALTER TABLE tutor_content ADD COLUMN status VARCHAR(50) DEFAULT 'pending';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tutor_content' AND column_name = 'created_at') THEN
        ALTER TABLE tutor_content ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    RAISE NOTICE 'Table structure updated successfully';
END $$;

-- Insert test users into the users table (for foreign key constraints)
INSERT INTO users (id, email, role, verification_status, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'john.doe@example.com', 'tutor', 'approved', NOW() - INTERVAL '5 days'),
('550e8400-e29b-41d4-a716-446655440002', 'jane.smith@example.com', 'student', 'approved', NOW() - INTERVAL '3 days'),
('550e8400-e29b-41d4-a716-446655440003', 'mike.johnson@example.com', 'tutor', 'pending', NOW() - INTERVAL '2 days'),
('550e8400-e29b-41d4-a716-446655440004', 'sarah.wilson@example.com', 'student', 'approved', NOW() - INTERVAL '1 day'),
('550e8400-e29b-41d4-a716-446655440005', 'david.brown@example.com', 'tutor', 'rejected', NOW() - INTERVAL '4 days')
ON CONFLICT (id) DO NOTHING;

-- Insert test users into public_users (if not already populated by trigger)
INSERT INTO public_users (id, email, role, verification_status, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'john.doe@example.com', 'tutor', 'approved', NOW() - INTERVAL '5 days'),
('550e8400-e29b-41d4-a716-446655440002', 'jane.smith@example.com', 'student', 'approved', NOW() - INTERVAL '3 days'),
('550e8400-e29b-41d4-a716-446655440003', 'mike.johnson@example.com', 'tutor', 'pending', NOW() - INTERVAL '2 days'),
('550e8400-e29b-41d4-a716-446655440004', 'sarah.wilson@example.com', 'student', 'approved', NOW() - INTERVAL '1 day'),
('550e8400-e29b-41d4-a716-446655440005', 'david.brown@example.com', 'tutor', 'rejected', NOW() - INTERVAL '4 days')
ON CONFLICT (id) DO NOTHING;

-- Insert test tutor profiles
INSERT INTO tutor_profiles (user_id, full_name, bio, subjects, hourly_rate, experience_years, education, status) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'John Doe', 'Experienced math tutor with 5+ years of teaching experience. Specializes in algebra, calculus, and geometry.', ARRAY['Mathematics', 'Algebra', 'Calculus'], 25.00, 5, 'Masters in Mathematics from MIT', 'approved'),
('550e8400-e29b-41d4-a716-446655440003', 'Mike Johnson', 'Science enthusiast with expertise in physics and chemistry. Makes complex concepts easy to understand.', ARRAY['Physics', 'Chemistry', 'Science'], 20.00, 3, 'Bachelors in Physics from Stanford', 'pending'),
('550e8400-e29b-41d4-a716-446655440005', 'David Brown', 'English literature specialist with a passion for classic novels and modern writing.', ARRAY['English', 'Literature', 'Writing'], 22.00, 4, 'Masters in English from Harvard', 'rejected')
ON CONFLICT DO NOTHING;

-- Insert test reviews (using dynamic column detection)
DO $$
DECLARE
    has_status BOOLEAN;
    has_created_at BOOLEAN;
    has_review_text BOOLEAN;
BEGIN
    -- Check what columns exist
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'status') INTO has_status;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'created_at') INTO has_created_at;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'review_text') INTO has_review_text;
    
    -- Insert reviews with available columns
    IF has_review_text AND has_status AND has_created_at THEN
        INSERT INTO reviews (reviewer_id, tutor_id, rating, review_text, status, created_at) VALUES
        ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 5, 'Excellent tutor! John made calculus so much easier to understand.', 'approved', NOW() - INTERVAL '2 days'),
        ('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 4, 'Great teaching style and very patient with explanations.', 'approved', NOW() - INTERVAL '1 day'),
        ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 3, 'Good tutor but sometimes moves too fast through concepts.', 'pending', NOW() - INTERVAL '12 hours')
        ON CONFLICT DO NOTHING;
    ELSIF has_review_text AND has_status THEN
        INSERT INTO reviews (reviewer_id, tutor_id, rating, review_text, status) VALUES
        ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 5, 'Excellent tutor! John made calculus so much easier to understand.', 'approved'),
        ('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 4, 'Great teaching style and very patient with explanations.', 'approved'),
        ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 3, 'Good tutor but sometimes moves too fast through concepts.', 'pending')
        ON CONFLICT DO NOTHING;
    ELSIF has_review_text THEN
        INSERT INTO reviews (reviewer_id, tutor_id, rating, review_text) VALUES
        ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 5, 'Excellent tutor! John made calculus so much easier to understand.'),
        ('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 4, 'Great teaching style and very patient with explanations.'),
        ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 3, 'Good tutor but sometimes moves too fast through concepts.')
        ON CONFLICT DO NOTHING;
    ELSE
        INSERT INTO reviews (reviewer_id, tutor_id, rating) VALUES
        ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 5),
        ('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 4),
        ('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 3)
        ON CONFLICT DO NOTHING;
    END IF;
    
    RAISE NOTICE 'Reviews inserted successfully';
END $$;

-- Insert test content
INSERT INTO tutor_content (user_id, title, description, file_url, file_type, status, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Calculus Fundamentals', 'Comprehensive guide to calculus basics including limits, derivatives, and integrals.', 'https://example.com/calculus-guide.pdf', 'pdf', 'approved', NOW() - INTERVAL '3 days'),
('550e8400-e29b-41d4-a716-446655440003', 'Physics Lab Report Template', 'Template for writing clear and structured physics lab reports.', 'https://example.com/physics-template.docx', 'docx', 'pending', NOW() - INTERVAL '1 day'),
('550e8400-e29b-41d4-a716-446655440001', 'Algebra Practice Problems', 'Collection of algebra problems with step-by-step solutions.', 'https://example.com/algebra-problems.pdf', 'pdf', 'approved', NOW() - INTERVAL '5 days')
ON CONFLICT DO NOTHING;

-- Insert test transactions
INSERT INTO transactions (user_id, amount, currency, type, status, description, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440002', 50.00, 'USD', 'payment', 'completed', 'Payment for math tutoring session', NOW() - INTERVAL '2 days'),
('550e8400-e29b-41d4-a716-446655440004', 45.00, 'USD', 'payment', 'completed', 'Payment for physics tutoring session', NOW() - INTERVAL '1 day'),
('550e8400-e29b-41d4-a716-446655440002', 25.00, 'USD', 'payment', 'pending', 'Payment for English tutoring session', NOW() - INTERVAL '6 hours')
ON CONFLICT DO NOTHING;

-- Insert test payouts
INSERT INTO payouts (user_id, amount, currency, status, method, account_details, created_at) VALUES
('550e8400-e29b-41d4-a716-446655440001', 100.00, 'USD', 'pending', 'bank_transfer', 'Bank: Chase, Account: ****1234', NOW() - INTERVAL '1 day'),
('550e8400-e29b-41d4-a716-446655440003', 75.00, 'USD', 'processing', 'paypal', 'PayPal: mike.johnson@example.com', NOW() - INTERVAL '12 hours')
ON CONFLICT DO NOTHING;

-- Insert test refunds
INSERT INTO refunds (transaction_id, amount, currency, reason, status, created_at) VALUES
((SELECT id FROM transactions WHERE description = 'Payment for English tutoring session' LIMIT 1), 25.00, 'USD', 'Student cancelled session', 'pending', NOW() - INTERVAL '4 hours')
ON CONFLICT DO NOTHING;

-- Verify data was inserted
SELECT 'public_users' as table_name, COUNT(*) as row_count FROM public_users
UNION ALL
SELECT 'tutor_profiles', COUNT(*) FROM tutor_profiles
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'tutor_content', COUNT(*) FROM tutor_content
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'payouts', COUNT(*) FROM payouts
UNION ALL
SELECT 'refunds', COUNT(*) FROM refunds
ORDER BY table_name;
