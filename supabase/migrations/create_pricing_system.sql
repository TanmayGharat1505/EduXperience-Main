-- Create Pricing System for Tutors and Institutions
-- This system allows tiered access to students based on subscription levels
-- 
-- IMPORTANT: This script will DROP and RECREATE all pricing-related tables.
-- If you have existing data you want to preserve, please backup first.
-- 
-- To run this script:
-- 1. Go to Supabase Dashboard > SQL Editor
-- 2. Copy and paste this entire script
-- 3. Click "Run" to execute
-- 4. Check the output for any errors

-- 0. Drop existing tables if they exist (to avoid conflicts)
DROP TABLE IF EXISTS student_access_logs CASCADE;
DROP TABLE IF EXISTS subscription_payments CASCADE;
DROP TABLE IF EXISTS user_subscriptions CASCADE;
DROP TABLE IF EXISTS pricing_config CASCADE;
DROP TABLE IF EXISTS pricing_tiers CASCADE;

-- 1. Create pricing tiers table
CREATE TABLE IF NOT EXISTS pricing_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_name TEXT NOT NULL UNIQUE,
  min_students INTEGER NOT NULL,
  max_students INTEGER NOT NULL,
  price_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create base pricing configuration table
CREATE TABLE IF NOT EXISTS pricing_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  base_price DECIMAL(10,2) NOT NULL DEFAULT 20.00,
  currency TEXT NOT NULL DEFAULT 'USD',
  billing_cycle TEXT NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly')),
  annual_discount_percent DECIMAL(5,2) DEFAULT 20.00,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create user subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tier_id UUID NOT NULL REFERENCES pricing_tiers(id),
  current_student_count INTEGER NOT NULL DEFAULT 0,
  max_students_allowed INTEGER NOT NULL,
  subscription_status TEXT NOT NULL DEFAULT 'active' CHECK (subscription_status IN ('active', 'expired', 'cancelled', 'suspended')),
  current_period_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  current_period_end TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '1 month'),
  auto_renew BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create payment history table
CREATE TABLE IF NOT EXISTS subscription_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES user_subscriptions(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  payment_method TEXT,
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
  transaction_id TEXT,
  payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create student access tracking table
CREATE TABLE IF NOT EXISTS student_access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tutor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  access_type TEXT NOT NULL DEFAULT 'view' CHECK (access_type IN ('view', 'contact', 'book')),
  access_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  subscription_tier_at_time TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Insert default pricing tiers
INSERT INTO pricing_tiers (tier_name, min_students, max_students, price_multiplier, description) VALUES
('Basic', 1, 5, 1.00, 'Base access for new tutors and institutions'),
('Standard', 6, 15, 2.00, 'Growing practice tier'),
('Professional', 16, 30, 3.00, 'Established practice tier'),
('Enterprise', 31, 50, 4.00, 'Large practice tier'),
('Unlimited', 51, 999999, 5.00, 'Maximum access tier')
ON CONFLICT (tier_name) DO NOTHING;

-- 7. Insert default pricing configuration
INSERT INTO pricing_config (base_price, currency, billing_cycle, annual_discount_percent) VALUES
(1500.00, 'INR', 'monthly', 20.00)
ON CONFLICT (id) DO NOTHING;

-- 8. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(subscription_status);
CREATE INDEX IF NOT EXISTS idx_subscription_payments_subscription_id ON subscription_payments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_student_access_logs_tutor_id ON student_access_logs(tutor_id);
CREATE INDEX IF NOT EXISTS idx_student_access_logs_student_id ON student_access_logs(student_id);

-- 9. Enable Row Level Security
ALTER TABLE pricing_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE pricing_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_access_logs ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS policies
-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Public can view pricing tiers" ON pricing_tiers;
DROP POLICY IF EXISTS "Public can view pricing config" ON pricing_config;
DROP POLICY IF EXISTS "Users can view own subscriptions" ON user_subscriptions;
DROP POLICY IF EXISTS "Admins can manage all subscriptions" ON user_subscriptions;
DROP POLICY IF EXISTS "Users can view own payments" ON subscription_payments;
DROP POLICY IF EXISTS "Admins can manage all payments" ON subscription_payments;
DROP POLICY IF EXISTS "Users can view own access logs" ON student_access_logs;
DROP POLICY IF EXISTS "Admins can view all access logs" ON student_access_logs;

-- Pricing tiers: Public read access
CREATE POLICY "Public can view pricing tiers" ON pricing_tiers
  FOR SELECT USING (true);

-- Pricing config: Public read access
CREATE POLICY "Public can view pricing config" ON pricing_config
  FOR SELECT USING (true);

-- User subscriptions: Users can view own, admins can view all
CREATE POLICY "Users can view own subscriptions" ON user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all subscriptions" ON user_subscriptions
  FOR ALL USING (auth.role() = 'admin');

-- Subscription payments: Users can view own, admins can view all
CREATE POLICY "Users can view own payments" ON subscription_payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_subscriptions 
      WHERE user_subscriptions.id = subscription_payments.subscription_id 
      AND user_subscriptions.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all payments" ON subscription_payments
  FOR ALL USING (auth.role() = 'admin');

-- Student access logs: Users can view own, admins can view all
CREATE POLICY "Users can view own access logs" ON student_access_logs
  FOR SELECT USING (auth.uid() = tutor_id);

CREATE POLICY "Admins can view all access logs" ON student_access_logs
  FOR SELECT USING (auth.role() = 'admin');

-- 11. Create functions for pricing calculations
-- Drop existing functions if they exist (to avoid conflicts)
DROP FUNCTION IF EXISTS calculate_subscription_price(UUID, TEXT);
DROP FUNCTION IF EXISTS can_access_more_students(UUID, INTEGER);
DROP FUNCTION IF EXISTS log_student_access(UUID, UUID, TEXT);

CREATE OR REPLACE FUNCTION calculate_subscription_price(
  p_tier_id UUID,
  p_billing_cycle TEXT DEFAULT 'monthly'
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
  v_base_price DECIMAL(10,2);
  v_multiplier DECIMAL(5,2);
  v_annual_discount DECIMAL(5,2);
  v_final_price DECIMAL(10,2);
BEGIN
  -- Get base price and multiplier
  SELECT pc.base_price, pt.price_multiplier, pc.annual_discount_percent
  INTO v_base_price, v_multiplier, v_annual_discount
  FROM pricing_config pc
  CROSS JOIN pricing_tiers pt
  WHERE pt.id = p_tier_id
  AND pc.is_active = true
  LIMIT 1;
  
  IF v_base_price IS NULL OR v_multiplier IS NULL THEN
    RETURN 0;
  END IF;
  
  -- Calculate base price with multiplier
  v_final_price := v_base_price * v_multiplier;
  
  -- Apply annual discount if yearly billing
  IF p_billing_cycle = 'yearly' THEN
    v_final_price := v_final_price * 12 * (1 - v_annual_discount / 100);
  ELSIF p_billing_cycle = 'monthly' THEN
    v_final_price := v_final_price;
  END IF;
  
  RETURN ROUND(v_final_price, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Create function to check if user can access more students
CREATE OR REPLACE FUNCTION can_access_more_students(
  p_user_id UUID,
  p_required_students INTEGER DEFAULT 1
)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_count INTEGER;
  v_max_allowed INTEGER;
  v_subscription_status TEXT;
BEGIN
  -- Get current subscription info
  SELECT us.current_student_count, us.max_students_allowed, us.subscription_status
  INTO v_current_count, v_max_allowed, v_subscription_status
  FROM user_subscriptions us
  WHERE us.user_id = p_user_id
  AND us.subscription_status = 'active'
  ORDER BY us.created_at DESC
  LIMIT 1;
  
  -- If no active subscription, check if they're within basic tier (free)
  IF v_subscription_status IS NULL THEN
    -- Basic tier allows 5 students for free
    RETURN (v_current_count + p_required_students) <= 5;
  END IF;
  
  -- Check if adding required students would exceed limit
  RETURN (v_current_count + p_required_students) <= v_max_allowed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Create function to log student access
CREATE OR REPLACE FUNCTION log_student_access(
  p_tutor_id UUID,
  p_student_id UUID,
  p_access_type TEXT DEFAULT 'view'
)
RETURNS BOOLEAN AS $$
DECLARE
  v_can_access BOOLEAN;
  v_tier_name TEXT;
BEGIN
  -- Check if tutor can access more students
  v_can_access := can_access_more_students(p_tutor_id, 1);
  
  IF NOT v_can_access THEN
    RETURN false;
  END IF;
  
  -- Get current tier name
  SELECT pt.tier_name INTO v_tier_name
  FROM user_subscriptions us
  JOIN pricing_tiers pt ON us.tier_id = pt.id
  WHERE us.user_id = p_tutor_id
  AND us.subscription_status = 'active'
  ORDER BY us.created_at DESC
  LIMIT 1;
  
  -- Log the access
  INSERT INTO student_access_logs (tutor_id, student_id, access_type, subscription_tier_at_time)
  VALUES (p_tutor_id, p_student_id, p_access_type, COALESCE(v_tier_name, 'Basic'));
  
  -- Update current student count if this is a new student
  IF NOT EXISTS (
    SELECT 1 FROM student_access_logs 
    WHERE tutor_id = p_tutor_id 
    AND student_id = p_student_id 
    AND access_type = 'view'
    AND access_timestamp < NOW() - INTERVAL '1 day'
  ) THEN
    UPDATE user_subscriptions 
    SET current_student_count = current_student_count + 1,
        updated_at = NOW()
    WHERE user_id = p_tutor_id
    AND subscription_status = 'active';
  END IF;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. Create trigger to update updated_at timestamp
-- Drop existing triggers if they exist (to avoid conflicts)
DROP TRIGGER IF EXISTS update_pricing_tiers_updated_at ON pricing_tiers;
DROP TRIGGER IF EXISTS update_pricing_config_updated_at ON pricing_config;
DROP TRIGGER IF EXISTS update_user_subscriptions_updated_at ON user_subscriptions;

-- SAFETY: Create a unique function for pricing system (won't affect existing tables)
-- This prevents conflicts with the existing update_updated_at_column() function
-- used by profiles, student_profiles, institution_profiles, reviews, etc.
CREATE OR REPLACE FUNCTION update_pricing_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_pricing_tiers_updated_at 
  BEFORE UPDATE ON pricing_tiers 
  FOR EACH ROW EXECUTE FUNCTION update_pricing_updated_at_column();

CREATE TRIGGER update_pricing_config_updated_at 
  BEFORE UPDATE ON pricing_config 
  FOR EACH ROW EXECUTE FUNCTION update_pricing_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at 
  BEFORE UPDATE ON user_subscriptions 
  FOR EACH ROW EXECUTE FUNCTION update_pricing_updated_at_column();

-- 15. Insert sample data for testing
INSERT INTO user_subscriptions (user_id, tier_id, current_student_count, max_students_allowed, subscription_status, current_period_start, current_period_end, auto_renew)
SELECT 
  u.id,
  (SELECT id FROM pricing_tiers WHERE tier_name = 'Basic' LIMIT 1),
  0,
  5,
  'active',
  NOW(),
  NOW() + INTERVAL '1 month',
  true
FROM auth.users u
JOIN profiles p ON u.id = p.user_id
WHERE p.role IN ('tutor', 'institution')
AND NOT EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = u.id)
LIMIT 10;

-- Insert sample subscriptions for institutions with Standard tier
INSERT INTO user_subscriptions (user_id, tier_id, current_student_count, max_students_allowed, subscription_status, current_period_start, current_period_end, auto_renew)
SELECT 
  u.id,
  (SELECT id FROM pricing_tiers WHERE tier_name = 'Standard' LIMIT 1),
  0,
  15,
  'active',
  NOW(),
  NOW() + INTERVAL '1 month',
  true
FROM auth.users u
JOIN profiles p ON u.id = p.user_id
WHERE p.role = 'institution'
AND NOT EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = u.id)
LIMIT 5;

-- 16. Verify the setup
SELECT '=== PRICING SYSTEM CREATED ===' as status;
SELECT 
  COUNT(*) as total_tiers,
  'pricing_tiers' as table_name
FROM pricing_tiers
UNION ALL
SELECT 
  COUNT(*) as total_configs,
  'pricing_config' as table_name
FROM pricing_config
UNION ALL
SELECT 
  COUNT(*) as total_subscriptions,
  'user_subscriptions' as table_name
FROM user_subscriptions;
