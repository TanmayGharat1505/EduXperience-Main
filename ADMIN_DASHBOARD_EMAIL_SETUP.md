# Admin Dashboard Email Setup Guide

## Overview
This guide explains how to set up the admin dashboard to display actual user emails instead of UUIDs. The solution involves creating a `public_users` table that mirrors the `auth.users` table and automatically syncs with it.

## What Was Changed

### 1. Database Migration Updates
- **File**: `supabase/migrations/create_essential_admin_tables.sql`
- **Added**: `public_users` table creation
- **Added**: Automatic sync function and trigger between `auth.users` and `public_users`

### 2. Admin Dashboard Updates
- **File**: `src/pages/AdminDashboard.tsx`
- **Updated**: All data loading functions to join with `public_users` table
- **Updated**: User verification function to work with both tables
- **Result**: Real email addresses will now be displayed instead of UUIDs

## Setup Instructions

### Step 1: Run the Updated Migration
1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the entire content from `supabase/migrations/create_essential_admin_tables.sql`
4. Click "Run" to execute the migration

### Step 2: Insert Test Data (Optional)
1. In the same SQL Editor session
2. Copy and paste the content from `supabase/migrations/test_data_insertion.sql`
3. Click "Run" to populate tables with sample data

### Step 3: Verify Setup
Run this query to confirm all tables are working:
```sql
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
```

## How It Works

### 1. Public Users Table
- **Purpose**: Provides admin dashboard access to user information
- **Structure**: Mirrors essential fields from `auth.users`
- **Access**: Public schema, accessible by admin dashboard

### 2. Automatic Sync
- **Trigger**: Automatically syncs when users are created/updated/deleted
- **Function**: `sync_public_users()` handles all sync operations
- **Real-time**: Changes in `auth.users` immediately reflect in `public_users`

### 3. Data Loading
- **Joins**: All admin dashboard queries now join with `public_users`
- **Emails**: Real email addresses are fetched and displayed
- **Fallback**: If join fails, UUID is shown as fallback

## Table Relationships

```
auth.users (protected)
    ↓ (trigger sync)
public_users (accessible)
    ↓ (foreign key)
tutor_profiles, reviews, content, transactions, payouts, refunds
```

## Benefits

✅ **Real Email Display**: Users see actual email addresses instead of UUIDs
✅ **Automatic Sync**: No manual maintenance required
✅ **Secure**: Admin dashboard can't access protected `auth.users` directly
✅ **Performance**: Efficient joins with indexed foreign keys
✅ **Scalable**: Works with any number of users

## Troubleshooting

### Issue: "Table public_users does not exist"
**Solution**: Run the updated migration file

### Issue: "Foreign key constraint failed"
**Solution**: Ensure the migration ran completely and all tables were created

### Issue: Emails still showing as UUIDs
**Solution**: Check that the `public_users` table has data and foreign key relationships are correct

### Issue: Sync not working
**Solution**: Verify the trigger was created and the function has proper permissions

## Security Considerations

- `public_users` table is in public schema but only contains non-sensitive data
- No passwords or authentication tokens are exposed
- RLS policies can be added if additional security is needed
- Admin dashboard only reads data, doesn't modify user authentication

## Next Steps

After setup is complete:
1. Test the admin dashboard login
2. Verify all tabs show real email addresses
3. Test user verification functionality
4. Check analytics calculations with real data
5. Monitor performance and adjust indexes if needed

## Support

If you encounter issues:
1. Check the browser console for error messages
2. Verify all migration steps completed successfully
3. Ensure Supabase project has proper permissions
4. Check that all foreign key relationships are established correctly
