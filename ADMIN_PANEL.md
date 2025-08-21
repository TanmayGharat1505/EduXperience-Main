# EduXperience Admin Panel

## Overview
The Admin Panel provides secure administrative access to manage user verifications and content moderation across the platform.

## Access
- **URL**: `/admin/login`
- **Username**: `admin`
- **Password**: `EduXperience2024!`

## Features

### 1. User Verification Management
- **Approve Users**: Grant access to verified tutors and students
- **Reject Users**: Deny access to users who don't meet requirements
- **Re-approve Users**: Allow previously rejected users to be approved again

### 2. Content Moderation
- **Profile Moderation**: Review and approve/reject tutor profiles
- **Review Moderation**: Manage user reviews and ratings
- **Content Moderation**: Review uploaded materials and resources
- **Status Management**: Set content status to pending, approved, or rejected

### 3. Payment Management
- **Transaction Tracking**: Monitor all financial transactions
- **Payout Management**: Process and approve tutor payouts
- **Refund Processing**: Handle refund requests and approvals
- **Fee Management**: Configure and manage platform fees
- **Financial Analytics**: Track revenue, pending payouts, and refunds

### 4. Analytics Dashboard
- **Platform Performance**: Monitor overall platform health and metrics
- **User Growth Analytics**: Track user acquisition and growth trends
- **Revenue Analytics**: Monitor financial performance and trends
- **Engagement Metrics**: Track user activity and platform usage
- **Real-time Insights**: Live data updates and trend analysis

### 5. Dashboard Statistics
- Total registered users with verification counts
- Content moderation statistics (profiles, reviews, content)
- Payment statistics (revenue, transactions, payouts, refunds)
- Analytics metrics (user growth, engagement, performance)
- Pending items count for each content type
- Real-time updates after moderation actions

### 4. Comprehensive Management Interface
- **Tabbed Interface**: Organized sections for different content types
- **Quick Actions**: Approve/reject buttons for efficient moderation
- **Content Preview**: View profiles, reviews, and uploaded files
- **Status Tracking**: Monitor approval/rejection status across all content

## Security Features

### Authentication
- Secure admin login with username/password
- Session management with 24-hour expiration
- Route protection for unauthorized access

### Data Protection
- Admin credentials stored securely
- Session validation on each request
- Automatic logout on session expiration

## Usage Instructions

### 1. Accessing the Admin Panel
1. Navigate to `/admin/login`
2. Enter admin credentials
3. Click "Access Admin Panel"

### 2. Managing User Verifications
1. Go to "User Verification" tab
2. View users with their verification status
3. For pending users:
   - Click "Approve" to grant access
   - Click "Reject" to deny access
4. For rejected users:
   - Click "Re-approve" to grant access again

### 3. Content Moderation

#### Profile Moderation
1. Go to "Profiles" tab
2. Review tutor profile information (name, bio, avatar)
3. Click "View" to see profile details
4. Use "Approve" or "Reject" buttons to moderate

#### Review Moderation
1. Go to "Reviews" tab
2. Review user feedback and ratings
3. Check reviewer and tutor information
4. Moderate reviews based on content appropriateness

#### Content Moderation
1. Go to "Content" tab
2. Review uploaded materials and resources
3. Click "View" to preview content
4. Approve or reject based on quality and appropriateness

### 4. Monitoring Statistics
- Dashboard shows real-time counts for all content types
- Statistics update automatically after moderation actions
- Color-coded status indicators for quick identification

### 5. Payment Management

#### Transaction Monitoring
1. Go to "Transactions" tab
2. View all financial transactions with status and amounts
3. Monitor payment types (payments, payouts, refunds, fees)
4. Track transaction status and completion rates

#### Payout Processing
1. Go to "Payouts" tab
2. Review pending payout requests from tutors
3. Check payout method and account details
4. Process payouts: Pending → Processing → Completed
5. Reject invalid payout requests

#### Refund Management
1. Go to "Refunds" tab
2. Review refund requests with reasons
3. Approve or reject refund requests
4. Add admin notes for rejected refunds
5. Process approved refunds

#### Fee Configuration
1. Go to "Fees" tab
2. View all platform fees (percentage or fixed amounts)
3. Activate/deactivate fees as needed
4. Monitor fee impact on platform revenue

### 6. Analytics Dashboard

#### Platform Overview
1. Go to "Analytics" tab
2. View key metrics overview cards (Users, Revenue, Sessions, Ratings)
3. Monitor real-time platform performance indicators
4. Track growth rates and trends

#### User Growth Analysis
1. Review total user count and growth trends
2. Monitor new user acquisition (monthly/weekly)
3. Track active user percentage and verification rates
4. Analyze user growth patterns over time

#### Revenue Performance
1. Monitor total revenue and growth trends
2. Track monthly and weekly revenue performance
3. Analyze average transaction values
4. Review revenue growth rates and patterns

#### Engagement Metrics
1. Track total sessions and user activity
2. Monitor active tutors and students
3. Review content uploads and review submissions
4. Analyze platform engagement trends

#### Time Series Analysis
1. View daily trends for the last 7 days
2. Track user acquisition, revenue, and session patterns
3. Identify daily performance variations
4. Use data for trend analysis and forecasting

#### Data Refresh
1. Click "Refresh Data" button for real-time updates
2. Analytics automatically recalculate from current data
3. Monitor toast notifications for update confirmations
4. Use fresh data for accurate decision-making

## Content Types Managed

### 1. User Profiles
- **Tutor Profiles**: Full name, bio, avatar, contact information
- **Status Options**: pending, approved, rejected
- **Actions**: View details, approve, reject, re-approve

### 2. User Reviews
- **Review Content**: Rating (1-5 stars), comment text
- **User Information**: Reviewer and tutor details
- **Status Options**: pending, approved, rejected
- **Actions**: Approve, reject, re-approve

### 3. Uploaded Content
- **File Types**: Documents, images, videos, other materials
- **Content Details**: Title, description, file URL
- **Status Options**: pending, approved, rejected
- **Actions**: Preview, approve, reject, re-approve

### 4. Financial Transactions
- **Transaction Types**: Payments, payouts, refunds, fees
- **Status Options**: pending, completed, failed, cancelled
- **Details**: Amount, currency, description, user information
- **Tracking**: Creation date, completion date, status updates

### 5. Payout Requests
- **Payout Methods**: Bank transfer, PayPal, Stripe
- **Status Options**: pending, processing, completed, failed
- **Details**: Amount, account information, processing notes
- **Actions**: Process, complete, reject, add notes

### 6. Refund Requests
- **Refund Reasons**: User-provided reasons for refunds
- **Status Options**: pending, approved, processed, rejected
- **Details**: Original transaction, amount, admin notes
- **Actions**: Approve, reject, process, add notes

### 7. Platform Fees
- **Fee Types**: Percentage or fixed amounts
- **Status Options**: Active or inactive
- **Details**: Name, description, value, currency
- **Actions**: Activate, deactivate, update values

### 8. Analytics Data
- **User Growth Metrics**: Total users, new users, growth rates, active users
- **Revenue Analytics**: Total revenue, monthly/weekly trends, growth rates, average transaction values
- **Engagement Metrics**: Sessions, active tutors/students, content uploads, review submissions
- **Platform Performance**: Verification rates, content approval rates, average ratings, response times
- **Time Series Data**: Daily trends for users, revenue, and sessions over the last 7 days

## Technical Details

### Database Tables
- `users` table with `verification_status` field
- `tutor_profiles` table with `status` field
- `reviews` table with `status` field
- `tutor_content` table with `status` field
- `transactions` table for financial tracking
- `payouts` table for payout management
- `refunds` table for refund processing
- `fees` table for platform fee configuration
- Status values: `pending`, `approved`, `rejected`, `completed`, `failed`, `processing`

### API Endpoints
- `GET /users` - Fetch all users
- `PUT /users/:id` - Update user verification status
- `GET /tutor_profiles` - Fetch tutor profiles
- `PUT /tutor_profiles/:id` - Update profile status
- `GET /reviews` - Fetch user reviews
- `PUT /reviews/:id` - Update review status
- `GET /tutor_content` - Fetch uploaded content
- `PUT /tutor_content/:id` - Update content status
- `GET /transactions` - Fetch financial transactions
- `GET /payouts` - Fetch payout requests
- `PUT /payouts/:id` - Update payout status
- `GET /refunds` - Fetch refund requests
- `PUT /refunds/:id` - Update refund status
- `GET /fees` - Fetch platform fees
- `PUT /fees/:id` - Update fee configuration

### Session Management
- Local storage for admin session
- Automatic validation and cleanup
- Secure logout functionality

## Moderation Workflow

### 1. Content Submission
- Users submit profiles, reviews, or content
- Items automatically set to "pending" status
- Admin dashboard shows pending items count

### 2. Review Process
- Admin reviews content in respective tabs
- Uses preview/view functions to examine content
- Makes decision: approve, reject, or request changes

### 3. Status Updates
- Content status updated in real-time
- Users notified of approval/rejection
- Statistics automatically updated

### 4. Quality Control
- Consistent moderation standards applied
- Content quality maintained across platform
- Inappropriate content filtered out

## Payment Management Workflow

### 1. Transaction Monitoring
- All financial activities tracked automatically
- Real-time status updates and notifications
- Comprehensive audit trail maintained

### 2. Payout Processing
- Tutors request payouts for completed sessions
- Admin reviews and approves valid requests
- Multi-step process: Pending → Processing → Completed

### 3. Refund Management
- Users submit refund requests with reasons
- Admin reviews and approves/rejects requests
- Processed refunds tracked and documented

### 4. Fee Configuration
- Platform fees configured by administrators
- Percentage or fixed amount options
- Active/inactive status management

## Analytics Workflow

### 1. Data Collection
- Real-time data collection from all platform activities
- Automatic metric calculations and updates
- Historical data tracking for trend analysis

### 2. Performance Monitoring
- Continuous monitoring of platform health
- Real-time alerting for critical metrics
- Automated data refresh and updates

### 3. Trend Analysis
- Historical data analysis for pattern recognition
- Growth rate calculations and projections
- Performance benchmarking and optimization

## Important Notes

⚠️ **Security Warning**: 
- Admin credentials are hardcoded for development
- In production, use environment variables and secure authentication
- Change default password immediately after deployment

🔒 **Access Control**:
- Only authenticated admins can access the dashboard
- Sessions expire after 24 hours
- Unauthorized access attempts are logged

📋 **Moderation Guidelines**:
- Review content for appropriateness and quality
- Maintain consistent standards across all content types
- Document moderation decisions for audit purposes

💰 **Payment Security**:
- Financial data handled with strict security measures
- All transactions logged and auditable
- Payout and refund processes require admin approval

📊 **Analytics Accuracy**:
- Metrics calculated from real-time data
- Regular data refresh for accuracy
- Use analytics for informed decision-making

## Future Enhancements

- [ ] User activity logging
- [ ] Bulk content operations
- [ ] Advanced filtering and search
- [ ] User profile management
- [ ] System analytics and reports
- [ ] Email notifications for status changes
- [ ] Audit trail for admin actions
- [ ] Content quality scoring
- [ ] Automated content filtering
- [ ] Moderation queue prioritization
- [ ] Content appeal process
- [ ] Moderation team management
- [ ] Advanced financial reporting
- [ ] Automated payout processing
- [ ] Refund automation workflows
- [ ] Fee calculation engines
- [ ] Payment gateway integrations
- [ ] Financial compliance tools
- [ ] Advanced analytics and reporting
- [ ] Predictive analytics and forecasting
- [ ] Custom dashboard widgets
- [ ] Export and reporting tools
- [ ] Real-time notifications
- [ ] Performance optimization tools

## Support

For technical support or questions about the admin panel, contact the development team.
