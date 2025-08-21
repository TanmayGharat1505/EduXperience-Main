-- Fix Admin Dashboard Tables and Foreign Keys
-- This script creates missing tables and fixes relationships

-- 1. First, let's see what tables actually exist
SELECT 'Existing Tables:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'public_users', 'tutor_profiles', 'profiles', 'reviews', 'tutor_content', 'transactions', 'payouts', 'refunds', 'fees')
ORDER BY table_name;

-- 2. Check existing table structures and add missing columns
-- Reviews table
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reviewer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  tutor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns to existing reviews table if needed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'status') THEN
        ALTER TABLE reviews ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'updated_at') THEN
        ALTER TABLE reviews ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Tutor content table - check if exists and add missing columns
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tutor_content') THEN
        CREATE TABLE tutor_content (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          description TEXT,
          content_type TEXT DEFAULT 'lesson' CHECK (content_type IN ('lesson', 'material', 'video')),
          file_url TEXT,
          status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    ELSE
        -- Add missing columns to existing table
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tutor_content' AND column_name = 'content_type') THEN
            ALTER TABLE tutor_content ADD COLUMN content_type TEXT DEFAULT 'lesson';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tutor_content' AND column_name = 'status') THEN
            ALTER TABLE tutor_content ADD COLUMN status TEXT DEFAULT 'pending';
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tutor_content' AND column_name = 'updated_at') THEN
            ALTER TABLE tutor_content ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        END IF;
    END IF;
END $$;

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  type TEXT DEFAULT 'payment' CHECK (type IN ('payment', 'refund', 'withdrawal')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  payment_method TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns to existing transactions table if needed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transactions' AND column_name = 'status') THEN
        ALTER TABLE transactions ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transactions' AND column_name = 'updated_at') THEN
        ALTER TABLE transactions ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Payouts table
CREATE TABLE IF NOT EXISTS payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  method TEXT DEFAULT 'bank_transfer' CHECK (method IN ('bank_transfer', 'paypal', 'stripe')),
  account_details TEXT DEFAULT 'Account details pending',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'processed', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  user_email TEXT,
  notes TEXT
);

-- Add missing columns to existing payouts table if needed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payouts' AND column_name = 'status') THEN
        ALTER TABLE payouts ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payouts' AND column_name = 'user_email') THEN
        ALTER TABLE payouts ADD COLUMN user_email TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payouts' AND column_name = 'notes') THEN
        ALTER TABLE payouts ADD COLUMN notes TEXT;
    END IF;
    
    -- Check if account_details has NOT NULL constraint and add default if needed
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payouts' 
        AND column_name = 'account_details' 
        AND is_nullable = 'NO'
    ) THEN
        -- Try to update existing NULL values to have a default
        UPDATE payouts SET account_details = 'Account details pending' WHERE account_details IS NULL;
        
        -- If the column doesn't have a default, try to add one
        BEGIN
            ALTER TABLE payouts ALTER COLUMN account_details SET DEFAULT 'Account details pending';
        EXCEPTION WHEN OTHERS THEN
            -- Column might already have a default, ignore error
            NULL;
        END;
    END IF;
END $$;

-- Refunds table
CREATE TABLE IF NOT EXISTS refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  reason TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'processed', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  admin_notes TEXT
);

-- Add missing columns to existing refunds table if needed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'refunds' AND column_name = 'status') THEN
        ALTER TABLE refunds ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'refunds' AND column_name = 'admin_notes') THEN
        ALTER TABLE refunds ADD COLUMN admin_notes TEXT;
    END IF;
END $$;

-- Fees table
CREATE TABLE IF NOT EXISTS fees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT DEFAULT 'percentage' CHECK (type IN ('percentage', 'fixed')),
  value DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns to existing fees table if needed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fees' AND column_name = 'is_active') THEN
        ALTER TABLE fees ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fees' AND column_name = 'updated_at') THEN
        ALTER TABLE fees ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer_id ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_tutor_id ON reviews(tutor_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);
CREATE INDEX IF NOT EXISTS idx_tutor_content_user_id ON tutor_content(user_id);
CREATE INDEX IF NOT EXISTS idx_tutor_content_status ON tutor_content(status);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_payouts_user_id ON payouts(user_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status);
CREATE INDEX IF NOT EXISTS idx_refunds_transaction_id ON refunds(transaction_id);
CREATE INDEX IF NOT EXISTS idx_refunds_status ON refunds(status);

-- 4. Fix any existing NOT NULL constraint issues before inserting data
-- Check and fix payouts table constraints
DO $$
BEGIN
    -- If payouts table exists and has NOT NULL constraint on account_details
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payouts' 
        AND column_name = 'account_details' 
        AND is_nullable = 'NO'
    ) THEN
        -- Update any existing NULL values to have a default value
        UPDATE payouts SET account_details = 'Account details pending' WHERE account_details IS NULL;
        
        -- Try to add a default value to the column
        BEGIN
            ALTER TABLE payouts ALTER COLUMN account_details SET DEFAULT 'Account details pending';
        EXCEPTION WHEN OTHERS THEN
            -- Column might already have a default, ignore error
            NULL;
        END;
    END IF;
END $$;

-- 5. Insert sample data for testing (only if tables are empty)
-- Sample reviews
INSERT INTO reviews (reviewer_id, tutor_id, rating, review_text, status) 
SELECT 
  (SELECT id FROM auth.users LIMIT 1), 
  (SELECT id FROM auth.users LIMIT 1), 
  5, 'Great tutor!', 'approved'
WHERE NOT EXISTS (SELECT 1 FROM reviews LIMIT 1);

INSERT INTO reviews (reviewer_id, tutor_id, rating, review_text, status) 
SELECT 
  (SELECT id FROM auth.users LIMIT 1), 
  (SELECT id FROM auth.users LIMIT 1), 
  4, 'Very helpful', 'approved'
WHERE NOT EXISTS (SELECT 1 FROM reviews LIMIT 1);

-- Sample content (check if content_type column exists first)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tutor_content' AND column_name = 'content_type') THEN
        INSERT INTO tutor_content (user_id, title, description, content_type, status) 
        SELECT 
          (SELECT id FROM auth.users LIMIT 1), 
          'Math Lesson 1', 
          'Basic algebra introduction', 
          'lesson', 
          'approved'
        WHERE NOT EXISTS (SELECT 1 FROM tutor_content LIMIT 1);
        
        INSERT INTO tutor_content (user_id, title, description, content_type, status) 
        SELECT 
          (SELECT id FROM auth.users LIMIT 1), 
          'Science Material', 
          'Chemistry notes', 
          'material', 
          'pending'
        WHERE NOT EXISTS (SELECT 1 FROM tutor_content LIMIT 1);
    ELSE
        -- Insert without content_type if column doesn't exist
        INSERT INTO tutor_content (user_id, title, description, status) 
        SELECT 
          (SELECT id FROM auth.users LIMIT 1), 
          'Math Lesson 1', 
          'Basic algebra introduction', 
          'approved'
        WHERE NOT EXISTS (SELECT 1 FROM tutor_content LIMIT 1);
        
        INSERT INTO tutor_content (user_id, title, description, status) 
        SELECT 
          (SELECT id FROM auth.users LIMIT 1), 
          'Science Material', 
          'Chemistry notes', 
          'pending'
        WHERE NOT EXISTS (SELECT 1 FROM tutor_content LIMIT 1);
    END IF;
END $$;

-- Sample transactions
INSERT INTO transactions (user_id, amount, type, status, payment_method) 
SELECT 
  (SELECT id FROM auth.users LIMIT 1), 
  50.00, 
  'payment', 
  'completed', 
  'stripe'
WHERE NOT EXISTS (SELECT 1 FROM transactions LIMIT 1);

INSERT INTO transactions (user_id, amount, type, status, payment_method) 
SELECT 
  (SELECT id FROM auth.users LIMIT 1), 
  75.00, 
  'payment', 
  'pending', 
  'paypal'
WHERE NOT EXISTS (SELECT 1 FROM transactions LIMIT 1);

-- Sample payouts
INSERT INTO payouts (user_id, amount, method, status, user_email, account_details) 
SELECT 
  (SELECT id FROM auth.users LIMIT 1), 
  100.00, 
  'bank_transfer', 
  'pending', 
  'tutor@example.com',
  'Bank: Chase, Account: ****1234'
WHERE NOT EXISTS (SELECT 1 FROM payouts LIMIT 1);

INSERT INTO payouts (user_id, amount, method, status, user_email, account_details) 
SELECT 
  (SELECT id FROM auth.users LIMIT 1), 
  150.00, 
  'paypal', 
  'approved', 
  'tutor2@example.com',
  'PayPal: tutor2@example.com'
WHERE NOT EXISTS (SELECT 1 FROM payouts LIMIT 1);

-- Sample fees
INSERT INTO fees (name, type, value, description) 
SELECT 
  'Platform Fee', 
  'percentage', 
  5.00, 
  'Standard platform commission'
WHERE NOT EXISTS (SELECT 1 FROM fees LIMIT 1);

INSERT INTO fees (name, type, value, description) 
SELECT 
  'Processing Fee', 
  'fixed', 
  0.30, 
  'Payment processing fee'
WHERE NOT EXISTS (SELECT 1 FROM fees LIMIT 1);

-- 6. Check the results
SELECT 'Table Creation Results:' as info;
SELECT 
  'reviews' as table_name,
  COUNT(*) as record_count
FROM reviews
UNION ALL
SELECT 
  'tutor_content' as table_name,
  COUNT(*) as record_count
FROM tutor_content
UNION ALL
SELECT 
  'transactions' as table_name,
  COUNT(*) as record_count
FROM transactions
UNION ALL
SELECT 
  'payouts' as table_name,
  COUNT(*) as record_count
FROM payouts
UNION ALL
SELECT 
  'fees' as table_name,
  COUNT(*) as record_count
FROM fees;

-- 7. Verify foreign key relationships work
SELECT 'Foreign Key Test:' as info;
SELECT 
  'reviews' as table_name,
  COUNT(*) as total_reviews,
  COUNT(CASE WHEN reviewer_id IS NOT NULL THEN 1 END) as valid_reviewer_ids,
  COUNT(CASE WHEN tutor_id IS NOT NULL THEN 1 END) as valid_tutor_ids
FROM reviews
UNION ALL
SELECT 
  'tutor_content' as table_name,
  COUNT(*) as total_content,
  COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as valid_user_ids,
  0 as placeholder
FROM tutor_content;

-- 8. Show table structures
SELECT 'Table Structures:' as info;
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('reviews', 'tutor_content', 'transactions', 'payouts', 'refunds', 'fees')
ORDER BY table_name, ordinal_position;
