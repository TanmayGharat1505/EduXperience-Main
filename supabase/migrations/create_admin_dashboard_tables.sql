-- Create Admin Dashboard Tables Migration
-- This migration creates all necessary tables for the admin dashboard functionality

-- 1. Add missing columns to existing users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'pending';

-- 2. Create reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tutor_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    review_text TEXT,
    subject_taught VARCHAR(255),
    class_type VARCHAR(100),
    class_date DATE,
    anonymous BOOLEAN DEFAULT false,
    verified_student BOOLEAN DEFAULT false,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create tutor_content table
CREATE TABLE IF NOT EXISTS tutor_content (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_url TEXT,
    file_type VARCHAR(100),
    file_size INTEGER,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create fees table
CREATE TABLE IF NOT EXISTS fees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('percentage', 'fixed')),
    value DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    type VARCHAR(50) NOT NULL CHECK (type IN ('payment', 'payout', 'refund', 'fee')),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    description TEXT,
    payment_method VARCHAR(100),
    transaction_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create payouts table
CREATE TABLE IF NOT EXISTS payouts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    method VARCHAR(50) NOT NULL CHECK (method IN ('bank_transfer', 'paypal', 'stripe')),
    account_details TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

-- 7. Create refunds table
CREATE TABLE IF NOT EXISTS refunds (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'processed', 'rejected')),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

-- 8. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_reviewer_id ON reviews(reviewer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_tutor_id ON reviews(tutor_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at);

CREATE INDEX IF NOT EXISTS idx_tutor_content_user_id ON tutor_content(user_id);
CREATE INDEX IF NOT EXISTS idx_tutor_content_status ON tutor_content(status);
CREATE INDEX IF NOT EXISTS idx_tutor_content_created_at ON tutor_content(created_at);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);

CREATE INDEX IF NOT EXISTS idx_payouts_user_id ON payouts(user_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts(status);
CREATE INDEX IF NOT EXISTS idx_payouts_created_at ON payouts(created_at);

CREATE INDEX IF NOT EXISTS idx_refunds_transaction_id ON refunds(transaction_id);
CREATE INDEX IF NOT EXISTS idx_refunds_status ON refunds(status);
CREATE INDEX IF NOT EXISTS idx_refunds_created_at ON refunds(created_at);

CREATE INDEX IF NOT EXISTS idx_users_verification_status ON users(verification_status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- 9. Enable Row Level Security (RLS)
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS policies
-- Reviews: Users can view their own reviews and reviews about them
CREATE POLICY "Users can view their own reviews" ON reviews
    FOR SELECT USING (auth.uid() = reviewer_id OR auth.uid() = tutor_id);

CREATE POLICY "Users can create reviews" ON reviews
    FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Users can update their own reviews" ON reviews
    FOR UPDATE USING (auth.uid() = reviewer_id);

-- Tutor Content: Users can view and manage their own content
CREATE POLICY "Users can view their own content" ON tutor_content
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create content" ON tutor_content
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own content" ON tutor_content
    FOR UPDATE USING (auth.uid() = user_id);

-- Fees: Public read access, admin write access
CREATE POLICY "Public can view fees" ON fees
    FOR SELECT USING (true);

-- Transactions: Users can view their own transactions
CREATE POLICY "Users can view their own transactions" ON transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create transactions" ON transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Payouts: Users can view and manage their own payouts
CREATE POLICY "Users can view their own payouts" ON payouts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create payouts" ON payouts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Refunds: Users can view refunds for their transactions
CREATE POLICY "Users can view refunds for their transactions" ON refunds
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM transactions 
            WHERE transactions.id = refunds.transaction_id 
            AND transactions.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create refunds" ON refunds
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM transactions 
            WHERE transactions.id = refunds.transaction_id 
            AND transactions.user_id = auth.uid()
        )
    );

-- 11. Insert sample data for testing
-- Sample fees
INSERT INTO fees (name, type, value, currency, description, is_active) VALUES
('Platform Fee', 'percentage', 5.00, 'USD', 'Standard platform fee for all transactions', true),
('Processing Fee', 'fixed', 0.30, 'USD', 'Payment processing fee per transaction', true),
('Premium Subscription', 'fixed', 9.99, 'USD', 'Monthly premium subscription fee', true)
ON CONFLICT DO NOTHING;

-- 12. Create admin role and permissions
-- Note: This requires superuser privileges in Supabase
-- You may need to run this in the Supabase dashboard SQL editor

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant permissions for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;

-- 13. Create functions for admin dashboard
CREATE OR REPLACE FUNCTION get_user_stats()
RETURNS TABLE (
    total_users BIGINT,
    verified_users BIGINT,
    pending_users BIGINT,
    new_users_this_month BIGINT,
    new_users_this_week BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT as total_users,
        COUNT(*) FILTER (WHERE verification_status = 'approved')::BIGINT as verified_users,
        COUNT(*) FILTER (WHERE verification_status = 'pending')::BIGINT as pending_users,
        COUNT(*) FILTER (WHERE created_at >= date_trunc('month', CURRENT_DATE))::BIGINT as new_users_this_month,
        COUNT(*) FILTER (WHERE created_at >= date_trunc('week', CURRENT_DATE))::BIGINT as new_users_this_week
    FROM users;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. Create view for admin dashboard overview
CREATE OR REPLACE VIEW admin_dashboard_overview AS
SELECT 
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM users WHERE verification_status = 'approved') as verified_users,
    (SELECT COUNT(*) FROM users WHERE verification_status = 'pending') as pending_users,
    (SELECT COUNT(*) FROM reviews) as total_reviews,
    (SELECT COUNT(*) FROM reviews WHERE status = 'pending') as pending_reviews,
    (SELECT COUNT(*) FROM tutor_content) as total_content,
    (SELECT COUNT(*) FROM tutor_content WHERE status = 'pending') as pending_content,
    (SELECT COUNT(*) FROM transactions) as total_transactions,
    (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE status = 'completed') as total_revenue;

-- Grant access to the view
GRANT SELECT ON admin_dashboard_overview TO authenticated;

-- 15. Create trigger functions for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at columns
CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tutor_content_updated_at BEFORE UPDATE ON tutor_content
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fees_updated_at BEFORE UPDATE ON fees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 16. Final verification
-- Check if all tables were created successfully
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('reviews', 'tutor_content', 'fees', 'transactions', 'payouts', 'refunds');
    
    IF table_count = 6 THEN
        RAISE NOTICE 'All admin dashboard tables created successfully!';
    ELSE
        RAISE NOTICE 'Some tables may not have been created. Table count: %', table_count;
    END IF;
END $$;
