# Tutor & Institute Verification System

A comprehensive verification system for tutors and institutes on the EduXperience platform, built with React, TypeScript, and Supabase.

## 🚀 Features

### Core Verification Features
- **Document Upload**: Secure storage of government IDs, academic certificates, and teaching credentials
- **Reference Management**: Professional references with contact verification
- **Subject Proficiency Tests**: Optional assessment tests for subject mastery
- **Admin Review Panel**: Comprehensive admin interface for verification review
- **Status Workflow**: Pending → Verified → Rejected with detailed feedback
- **Re-verification Support**: Periodic re-verification triggered by admins

### Document Types

#### For Tutors:
- ✅ Government ID (Aadhar, PAN, Passport)
- ✅ Academic Certificates (Degrees, Transcripts)
- ✅ Teaching Certificates
- ✅ Professional References
- ✅ Demo Class Video (Optional)

#### For Institutes:
- ✅ Government ID
- ✅ Academic Certificates
- ✅ Registration Certificate
- ✅ Tax ID / GST Number
- ✅ Location Proof
- ✅ Accreditation Proof
- ✅ Professional References

## 🏗️ Architecture

### Database Schema

#### Core Tables
1. **`verification_requests`** - Main verification workflow
2. **`verification_documents`** - Document metadata and storage
3. **`verification_references`** - Professional reference contacts
4. **`subject_proficiency_tests`** - Available assessment tests
5. **`test_questions`** - Test question bank
6. **`test_attempts`** - User test results and scores
7. **`verification_workflow_logs`** - Audit trail and history

#### Key Relationships
- `verification_requests.user_id` → `auth.users.id`
- `verification_documents.verification_request_id` → `verification_requests.id`
- `verification_references.verification_request_id` → `verification_requests.id`

### Security Features
- **Row Level Security (RLS)** enabled on all verification tables
- **Secure file storage** in Supabase Storage with access controls
- **Admin-only access** to verification documents and admin panel
- **Audit logging** for all verification status changes

## 🛠️ Implementation

### Backend Services

#### VerificationService Class
```typescript
// Core verification operations
- createVerificationRequest()
- uploadDocument()
- addReference()
- updateVerificationStatus()
- getAllVerificationRequests()
- getUserVerificationRequest()
- submitTestAttempt()
- triggerReVerification()
```

#### File Upload Security
- Unique filename generation with timestamps
- Organized storage structure: `verification-documents/{requestId}/{filename}`
- MIME type validation and file size tracking
- Public URL generation for admin review

### Frontend Components

#### 1. VerificationForm
- **Multi-step form** for document upload and reference collection
- **Progress tracking** with visual indicators
- **File validation** and upload progress
- **Responsive design** for mobile and desktop

#### 2. AdminVerificationReview
- **Comprehensive review interface** for admins
- **Document viewer** with download capabilities
- **Reference verification** status tracking
- **One-click approval/rejection** with reason capture

#### 3. VerificationStatus
- **Real-time status display** for users
- **Progress indicators** for pending verifications
- **Action buttons** based on current status
- **Next steps guidance** for each status

### Admin Dashboard Integration
- **New verification tab** in admin dashboard
- **Real-time updates** of verification requests
- **Status filtering** and search capabilities
- **Bulk operations** for multiple requests

## 📱 User Experience

### Verification Flow

#### Step 1: Create Request
1. User clicks "Start Verification"
2. System creates verification request record
3. User proceeds to document upload

#### Step 2: Document Upload
1. Upload required documents (government ID, certificates)
2. Upload optional documents (demo video, additional credentials)
3. Real-time upload progress and validation

#### Step 3: References
1. Add professional references with contact details
2. Specify relationship and contactability
3. Save reference information

#### Step 4: Submit & Review
1. Review all uploaded documents and references
2. Submit verification request
3. Receive confirmation and estimated timeline

### Status Updates
- **Email notifications** for status changes
- **Dashboard updates** in real-time
- **Progress tracking** for pending verifications
- **Clear next steps** for each status

## 🔧 Setup & Configuration

### Prerequisites
- Supabase project with authentication enabled
- Storage bucket for verification documents
- Admin user with appropriate permissions

### Database Migration
```bash
# Run the verification system migration
psql -h your-supabase-host -U postgres -d postgres -f supabase/migrations/create_verification_system.sql
```

### Environment Variables
```env
# Supabase configuration
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### Storage Bucket Setup
```sql
-- Create verification documents bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('verification-documents', 'verification-documents', true);

-- Set up storage policies
CREATE POLICY "Admins can upload verification documents" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'verification-documents' AND auth.role() = 'admin');

CREATE POLICY "Admins can view verification documents" ON storage.objects
FOR SELECT USING (bucket_id = 'verification-documents' AND auth.role() = 'admin');
```

## 🚀 Usage

### For Tutors/Institutes

#### Starting Verification
```typescript
import VerificationForm from '@/components/verification/VerificationForm';

<VerificationForm 
  userType="tutor" 
  onComplete={() => console.log('Verification submitted!')} 
/>
```

#### Checking Status
```typescript
import VerificationStatus from '@/components/verification/VerificationStatus';

<VerificationStatus 
  userType="tutor" 
  onStartVerification={() => navigate('/verification')} 
/>
```

### For Admins

#### Review Interface
```typescript
import AdminVerificationReview from '@/components/verification/AdminVerificationReview';

<AdminVerificationReview />
```

#### API Integration
```typescript
import { VerificationService } from '@/lib/verification-service';

// Get all verification requests
const requests = await VerificationService.getAllVerificationRequests();

// Approve a request
await VerificationService.updateVerificationStatus(requestId, 'verified');

// Reject with reason
await VerificationService.updateVerificationStatus(requestId, 'rejected', 'Invalid documents');
```

## 🔒 Security Considerations

### Data Protection
- **Encrypted storage** of sensitive documents
- **Access control** based on user roles
- **Audit logging** for compliance
- **Secure file URLs** with expiration

### Privacy Compliance
- **GDPR compliance** with data deletion capabilities
- **User consent** for document processing
- **Data retention** policies for verification documents
- **Secure disposal** of rejected documents

## 📊 Monitoring & Analytics

### Verification Metrics
- **Request volume** by user type and status
- **Processing time** from submission to decision
- **Approval rates** by document type and category
- **Rejection reasons** analysis for process improvement

### Admin Dashboard Stats
- **Pending requests** count with urgency indicators
- **Document upload** completion rates
- **Reference verification** status tracking
- **Test completion** and pass rates

## 🚧 Future Enhancements

### Planned Features
- **Automated document verification** using AI/ML
- **Background check integration** with third-party services
- **Video interview scheduling** for complex verifications
- **Multi-language support** for international users
- **Mobile app integration** for document capture

### Scalability Improvements
- **Queue management** for high-volume verification processing
- **Batch processing** for multiple document reviews
- **Performance optimization** for large document storage
- **CDN integration** for global document access

## 🐛 Troubleshooting

### Common Issues

#### Document Upload Failures
- Check file size limits (default: 10MB)
- Verify supported file types (PDF, JPG, PNG, DOC)
- Ensure storage bucket permissions are correct

#### Verification Status Not Updating
- Check RLS policies on verification tables
- Verify admin user has correct role permissions
- Review database triggers for workflow logging

#### Reference Verification Issues
- Ensure reference contact information is valid
- Check email/phone format validation
- Verify reference relationship descriptions

### Debug Mode
```typescript
// Enable debug logging
localStorage.setItem('verification_debug', 'true');

// Check verification service logs
console.log('Verification requests:', await VerificationService.getAllVerificationRequests());
```

## 📚 API Reference

### Verification Endpoints

#### Create Verification Request
```typescript
POST /api/verification/request
{
  "userType": "tutor" | "institute",
  "userId": "uuid"
}
```

#### Upload Document
```typescript
POST /api/verification/document
{
  "requestId": "uuid",
  "documentType": "government_id" | "academic_certificate" | ...,
  "file": File,
  "isRequired": boolean
}
```

#### Update Status
```typescript
PUT /api/verification/status
{
  "requestId": "uuid",
  "status": "verified" | "rejected",
  "rejectionReason": "string" // optional
}
```

## 🤝 Contributing

### Development Setup
1. Clone the repository
2. Install dependencies: `npm install`
3. Set up Supabase project and environment variables
4. Run database migrations
5. Start development server: `npm run dev`

### Code Standards
- **TypeScript** for type safety
- **ESLint** for code quality
- **Prettier** for code formatting
- **Component testing** with React Testing Library

### Testing
```bash
# Run unit tests
npm run test

# Run integration tests
npm run test:integration

# Run e2e tests
npm run test:e2e
```

## 📄 License

This verification system is part of the EduXperience platform and is licensed under the MIT License.

## 🆘 Support

For technical support or questions about the verification system:
- **Documentation**: Check this README and inline code comments
- **Issues**: Create a GitHub issue with detailed error information
- **Community**: Join our developer community for discussions

---

**Built with ❤️ for the EduXperience platform**
