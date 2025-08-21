-- Migration: Create essential admin dashboard tables
-- This migration creates the core tables needed for the admin dashboard functionality

-- 1. Create users table (if not exists)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    verification_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 1.5. Create a public users table for admin dashboard access
-- This table will be populated manually or through application logic
CREATE TABLE IF NOT EXISTS public_users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    verification_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create tutor_profiles table
CREATE TABLE IF NOT EXISTS tutor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    bio TEXT,
    subjects TEXT[],
    hourly_rate DECIMAL(10,2),
    experience_years INTEGER,
    education TEXT,
    profile_completion BOOLEAN DEFAULT FALSE,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 3. Create reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,
    tutor_id UUID NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (student_id) REFERENCES public_users(id) ON DELETE CASCADE,
    FOREIGN KEY (tutor_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 4. Create tutor_content table
CREATE TABLE IF NOT EXISTS tutor_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_type VARCHAR(50),
    file_url TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (tutor_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 5. Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL,
    tutor_id UUID NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    payment_method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (student_id) REFERENCES public_users(id) ON DELETE CASCADE,
    FOREIGN KEY (tutor_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 6. Create payouts table
CREATE TABLE IF NOT EXISTS payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tutor_id UUID NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    payment_method VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (tutor_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 7. Create refunds table
CREATE TABLE IF NOT EXISTS refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
);

-- 8. Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL,
    receiver_id UUID NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (sender_id) REFERENCES public_users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 9. Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 10. Create admin_logs table
CREATE TABLE IF NOT EXISTS admin_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL,
    action VARCHAR(255) NOT NULL,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (admin_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 11. Create content_moderation table
CREATE TABLE IF NOT EXISTS content_moderation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    moderator_id UUID,
    status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (moderator_id) REFERENCES public_users(id) ON DELETE SET NULL
);

-- 12. Create payment_settings table
CREATE TABLE IF NOT EXISTS payment_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform_fee_percentage DECIMAL(5,2) DEFAULT 10.00,
    minimum_payout_amount DECIMAL(10,2) DEFAULT 50.00,
    payout_schedule VARCHAR(50) DEFAULT 'weekly',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. Create user_verification table
CREATE TABLE IF NOT EXISTS user_verification (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    document_type VARCHAR(50),
    document_url TEXT,
    verification_status VARCHAR(50) DEFAULT 'pending',
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES public_users(id) ON DELETE CASCADE
);

-- 14. Create support_tickets table
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(50) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'open',
    assigned_admin_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES public_users(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_admin_id) REFERENCES public_users(id) ON DELETE SET NULL
);

-- 15. Create analytics_events table
CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES public_users(id) ON DELETE SET NULL
);

-- 16. Create system_settings table
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 17. Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('maintenance_mode', 'false', 'Whether the system is in maintenance mode'),
('registration_enabled', 'true', 'Whether new user registration is enabled'),
('content_moderation_enabled', 'true', 'Whether content moderation is enabled'),
('payment_processing_enabled', 'true', 'Whether payment processing is enabled')
ON CONFLICT (setting_key) DO NOTHING;

-- 18. Insert default payment settings
INSERT INTO payment_settings (platform_fee_percentage, minimum_payout_amount, payout_schedule) VALUES
(10.00, 50.00, 'weekly')
ON CONFLICT DO NOTHING;

-- 19. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_user_id ON tutor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_tutor_id ON reviews(tutor_id);
CREATE INDEX IF NOT EXISTS idx_reviews_student_id ON reviews(student_id);
CREATE INDEX IF NOT EXISTS idx_tutor_content_tutor_id ON tutor_content(tutor_id);
CREATE INDEX IF NOT EXISTS idx_transactions_student_id ON transactions(student_id);
CREATE INDEX IF NOT EXISTS idx_transactions_tutor_id ON transactions(tutor_id);
CREATE INDEX IF NOT EXISTS idx_payouts_tutor_id ON payouts(tutor_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_admin_id ON admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_content_moderation_content_id ON content_moderation(content_id);
CREATE INDEX IF NOT EXISTS idx_user_verification_user_id ON user_verification(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_event_type ON analytics_events(event_type);

-- 20. Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_verification ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- 21. Create RLS policies for admin access
-- Admin can read all data
CREATE POLICY "Admin can read all data" ON users FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON public_users FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON tutor_profiles FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON reviews FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON tutor_content FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON transactions FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON payouts FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON refunds FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON messages FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON notifications FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON admin_logs FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON content_moderation FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON payment_settings FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON user_verification FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON support_tickets FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON analytics_events FOR SELECT USING (true);
CREATE POLICY "Admin can read all data" ON system_settings FOR SELECT USING (true);

-- Admin can update all data
CREATE POLICY "Admin can update all data" ON users FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON public_users FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON tutor_profiles FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON reviews FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON tutor_content FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON transactions FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON payouts FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON refunds FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON messages FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON notifications FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON admin_logs FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON content_moderation FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON payment_settings FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON user_verification FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON support_tickets FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON analytics_events FOR UPDATE USING (true);
CREATE POLICY "Admin can update all data" ON system_settings FOR UPDATE USING (true);

-- Admin can insert all data
CREATE POLICY "Admin can insert all data" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON public_users FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON tutor_profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON reviews FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON tutor_content FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON transactions FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON payouts FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON refunds FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON messages FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON admin_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON content_moderation FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON payment_settings FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON user_verification FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON support_tickets FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON analytics_events FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can insert all data" ON system_settings FOR INSERT WITH CHECK (true);

-- Admin can delete all data
CREATE POLICY "Admin can delete all data" ON users FOR DELETE USING (true);
CREATE POLICY "Admin can insert all data" ON public_users FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON tutor_profiles FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON reviews FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON tutor_content FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON transactions FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON payouts FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON refunds FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON messages FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON notifications FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON admin_logs FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON content_moderation FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON payment_settings FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON user_verification FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON support_tickets FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON analytics_events FOR DELETE USING (true);
CREATE POLICY "Admin can delete all data" ON system_settings FOR DELETE USING (true);

-- 22. Grant necessary permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres;

-- 23. Create function to sync public_users when needed
-- This function will be called manually or through application logic
CREATE OR REPLACE FUNCTION sync_user_to_public_users(user_uuid UUID, user_email VARCHAR, user_role VARCHAR DEFAULT 'user')
RETURNS VOID AS $$
BEGIN
    INSERT INTO public_users (id, email, role, verification_status, created_at)
    VALUES (user_uuid, user_email, user_role, 'pending', NOW())
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
