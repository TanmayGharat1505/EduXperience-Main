# Database Setup Guide for Admin Dashboard

## 🚨 **Current Issue**
The admin dashboard is failing because it's trying to access database tables that don't exist yet. You're getting 404 errors for tables like `reviews`, `tutor_content`, `fees`, `transactions`, `payouts`, and `refunds`.

## 🗄️ **Required Database Tables**

The admin dashboard needs these tables to function:

1. **`reviews`** - User reviews and ratings
2. **`tutor_profiles`** - Tutor profile information and verification
3. **`tutor_content`** - Educational content uploaded by tutors  
4. **`fees`** - Platform fee configuration
5. **`transactions`** - Financial transactions
6. **`payouts`** - Tutor payout requests
7. **`refunds`** - Refund requests
8. **`users`** - Needs `created_at` and `verification_status` columns

---

## 🚀 **Quick Setup (Recommended)**

### **Step 1: Access Supabase Dashboard**
1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Select your EduXperience project
4. Go to **SQL Editor** in the left sidebar

### **Step 2: Run the Migration**
1. Copy the entire content from `supabase/migrations/create_essential_admin_tables.sql`
2. Paste it into the SQL Editor
3. Click **Run** button
4. Wait for the execution to complete

### **Step 3: Verify Tables Created**
1. Go to **Table Editor** in the left sidebar
2. You should see these new tables:
   - `reviews`
   - `tutor_profiles`
   - `tutor_content` 
   - `fees`
   - `transactions`
   - `payouts`
   - `refunds`

---

## 🔧 **Alternative Setup Methods**

### **Method 1: Individual Table Creation**
If you prefer to create tables one by one, run these commands separately:

```sql
-- 1. Add missing columns to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'pending';

-- 2. Create reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tutor_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    comment TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create tutor_profiles table
CREATE TABLE IF NOT EXISTS tutor_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(255),
    bio TEXT,
    avatar_url TEXT,
    subjects TEXT[],
    hourly_rate DECIMAL(10,2),
    experience_years INTEGER,
    education TEXT,
    certifications TEXT[],
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create tutor_content table
CREATE TABLE IF NOT EXISTS tutor_content (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_url TEXT,
    file_type VARCHAR(100),
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create fees table
CREATE TABLE IF NOT EXISTS fees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('percentage', 'fixed')),
    value DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### **Method 2: Using Supabase CLI**
If you have Supabase CLI installed:

```bash
# Navigate to your project directory
cd your-project-directory

# Run the migration
supabase db push

# Or apply specific migration
supabase migration up
```

---

## ✅ **Verification Steps**

### **Step 1: Check Tables Exist**
Run this query in SQL Editor to verify all tables were created:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('reviews', 'tutor_content', 'fees', 'transactions', 'payouts', 'refunds')
ORDER BY table_name;
```

**Expected Result:** 6 rows showing all table names

### **Step 2: Check Table Structure**
Verify each table has the correct columns:

```sql
-- Check reviews table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'reviews' 
ORDER BY ordinal_position;

-- Check fees table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'fees' 
ORDER BY ordinal_position;
```

### **Step 3: Test Sample Data**
Check if sample data was inserted:

```sql
SELECT * FROM fees;
```

**Expected Result:** 2 rows with platform fee and processing fee

---

## 🧪 **Testing the Admin Dashboard**

### **After Database Setup:**
1. **Refresh your admin dashboard** in the browser
2. **Check browser console** - should see no more 404 errors
3. **Navigate through all tabs** - should load without errors
4. **Verify data displays** - may show empty states initially (which is normal)

### **Expected Behavior:**
- ✅ No more 404 errors in console
- ✅ All tabs load successfully
- ✅ Analytics dashboard shows real data (or empty states)
- ✅ No "table not found" errors

---

## 🚨 **Common Issues & Solutions**

### **Issue 1: "Permission Denied"**
**Solution:** Run this in SQL Editor:
```sql
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
```

### **Issue 2: "Column Already Exists"**
**Solution:** The `IF NOT EXISTS` clause should handle this, but if you get errors, run:
```sql
-- Check what columns exist
SELECT column_name FROM information_schema.columns WHERE table_name = 'users';

-- Add only missing columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'pending';
```

### **Issue 3: "Foreign Key Constraint Failed"**
**Solution:** Ensure your `users` table exists and has data:
```sql
-- Check users table
SELECT COUNT(*) FROM users;

-- If empty, create a test user
INSERT INTO users (id, email, role) VALUES 
(gen_random_uuid(), 'test@example.com', 'student');
```

---

## 📊 **Sample Data for Testing**

### **Add Test Users (if needed):**
```sql
INSERT INTO users (id, email, role, verification_status, created_at) VALUES 
(gen_random_uuid(), 'tutor1@example.com', 'tutor', 'approved', NOW()),
(gen_random_uuid(), 'student1@example.com', 'student', 'approved', NOW()),
(gen_random_uuid(), 'pending@example.com', 'tutor', 'pending', NOW());
```

### **Add Test Reviews:**
```sql
INSERT INTO reviews (reviewer_id, tutor_id, rating, comment, status) VALUES 
((SELECT id FROM users WHERE email = 'student1@example.com' LIMIT 1),
 (SELECT id FROM users WHERE email = 'tutor1@example.com' LIMIT 1), 5, 'Great tutor!', 'approved');
```

### **Add Test Content:**
```sql
INSERT INTO tutor_content (user_id, title, description, file_type, status) VALUES 
((SELECT id FROM users WHERE email = 'tutor1@example.com' LIMIT 1), 
 'Math Tutorial', 'Basic algebra concepts', 'pdf', 'approved');
```

---

## 🔄 **Next Steps After Setup**

1. **Test Admin Dashboard** - Verify all tabs work
2. **Add Real Data** - Create actual users, content, etc.
3. **Test Features** - Try moderation actions, analytics
4. **Monitor Performance** - Check for any remaining errors

---

## 📞 **Need Help?**

If you encounter issues:

1. **Check Supabase Logs** - Go to Logs in Supabase dashboard
2. **Verify SQL Execution** - Ensure migration ran without errors
3. **Check Table Structure** - Use the verification queries above
4. **Review Error Messages** - Look for specific error details

The admin dashboard should work perfectly once these database tables are created! 🚀
