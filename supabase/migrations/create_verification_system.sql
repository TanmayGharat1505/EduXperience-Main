-- Migration: Create Comprehensive Verification System
-- This migration creates the complete verification system for tutors and institutes

-- 1. Create verification_requests table (main verification workflow)
CREATE TABLE IF NOT EXISTS verification_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_type TEXT NOT NULL CHECK (user_type IN ('tutor', 'institute')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  rejection_reason TEXT,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  re_verification_due_date TIMESTAMP WITH TIME ZONE,
  last_verification_date TIMESTAMP WITH TIME ZONE
);

-- 2. Create verification_documents table for storing document metadata
CREATE TABLE IF NOT EXISTS verification_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  verification_request_id UUID NOT NULL REFERENCES verification_requests(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN (
    'government_id', 'academic_certificate', 'teaching_certificate', 'reference_letter',
    'demo_video', 'registration_certificate', 'tax_id', 'location_proof', 'accreditation_proof'
  )),
  document_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  mime_type TEXT,
  is_required BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  verification_notes TEXT,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  verified_at TIMESTAMP WITH TIME ZONE,
  verified_by UUID REFERENCES auth.users(id)
);

-- 3. Create verification_references table for reference contacts
CREATE TABLE IF NOT EXISTS verification_references (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  verification_request_id UUID NOT NULL REFERENCES verification_requests(id) ON DELETE CASCADE,
  reference_name TEXT NOT NULL,
  reference_title TEXT,
  reference_organization TEXT,
  reference_email TEXT,
  reference_phone TEXT,
  reference_relationship TEXT,
  is_contactable BOOLEAN DEFAULT true,
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'unreachable')),
  verification_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create subject_proficiency_tests table
CREATE TABLE IF NOT EXISTS subject_proficiency_tests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  subject TEXT NOT NULL,
  test_name TEXT NOT NULL,
  description TEXT,
  total_questions INTEGER NOT NULL,
  passing_score INTEGER NOT NULL,
  time_limit_minutes INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create test_questions table
CREATE TABLE IF NOT EXISTS test_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  test_id UUID NOT NULL REFERENCES subject_proficiency_tests(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_type TEXT NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'short_answer')),
  options JSONB, -- For multiple choice questions
  correct_answer TEXT NOT NULL,
  points INTEGER DEFAULT 1,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create test_attempts table for tracking test results
CREATE TABLE IF NOT EXISTS test_attempts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  verification_request_id UUID NOT NULL REFERENCES verification_requests(id) ON DELETE CASCADE,
  test_id UUID NOT NULL REFERENCES subject_proficiency_tests(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  score INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  passing_score INTEGER NOT NULL,
  passed BOOLEAN NOT NULL,
  time_taken_minutes INTEGER,
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  answers JSONB, -- Store user's answers
  admin_review_notes TEXT,
  admin_reviewed_by UUID REFERENCES auth.users(id),
  admin_reviewed_at TIMESTAMP WITH TIME ZONE
);

-- 7. Create verification_workflow_logs table for audit trail
CREATE TABLE IF NOT EXISTS verification_workflow_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  verification_request_id UUID NOT NULL REFERENCES verification_requests(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  previous_status TEXT,
  new_status TEXT,
  action_by UUID REFERENCES auth.users(id),
  action_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_verification_requests_user_id ON verification_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON verification_requests(status);
CREATE INDEX IF NOT EXISTS idx_verification_requests_user_type ON verification_requests(user_type);
CREATE INDEX IF NOT EXISTS idx_verification_documents_request_id ON verification_documents(verification_request_id);
CREATE INDEX IF NOT EXISTS idx_verification_documents_type ON verification_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_test_attempts_user_id ON test_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_test_attempts_test_id ON test_attempts(test_id);

-- 9. Add RLS policies for security
ALTER TABLE verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_references ENABLE ROW LEVEL SECURITY;
ALTER TABLE subject_proficiency_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE verification_workflow_logs ENABLE ROW LEVEL SECURITY;

-- Users can view their own verification requests
CREATE POLICY "Users can view own verification requests" ON verification_requests
  FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own verification requests
CREATE POLICY "Users can create own verification requests" ON verification_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own verification requests (for document uploads)
CREATE POLICY "Users can update own verification requests" ON verification_requests
  FOR UPDATE USING (auth.uid() = user_id);

-- Admins can view all verification requests
CREATE POLICY "Admins can view all verification requests" ON verification_requests
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Admins can update all verification requests
CREATE POLICY "Admins can update all verification requests" ON verification_requests
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Similar policies for other tables...
CREATE POLICY "Users can view own verification documents" ON verification_documents
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM verification_requests 
      WHERE verification_requests.id = verification_documents.verification_request_id
      AND verification_requests.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all verification documents" ON verification_documents
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.user_id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- 10. Create trigger for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_verification_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_verification_updated_at
  BEFORE UPDATE ON verification_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_verification_updated_at();

-- 11. Create trigger for workflow logging
CREATE OR REPLACE FUNCTION log_verification_workflow()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO verification_workflow_logs (
      verification_request_id,
      action,
      previous_status,
      new_status,
      action_by,
      action_notes
    ) VALUES (
      NEW.id,
      'status_change',
      OLD.status,
      NEW.status,
      auth.uid(),
      CASE 
        WHEN NEW.status = 'rejected' THEN NEW.rejection_reason
        ELSE 'Status updated to ' || NEW.status
      END
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_verification_workflow
  AFTER UPDATE ON verification_requests
  FOR EACH ROW
  EXECUTE FUNCTION log_verification_workflow();

-- 12. Insert some sample subject proficiency tests
INSERT INTO subject_proficiency_tests (subject, test_name, description, total_questions, passing_score, time_limit_minutes) VALUES
('Mathematics', 'Basic Math Proficiency Test', 'Test covering fundamental mathematics concepts', 20, 16, 30),
('English', 'English Language Proficiency Test', 'Test covering grammar, vocabulary, and comprehension', 25, 20, 35),
('Science', 'General Science Test', 'Test covering basic science concepts', 20, 16, 30),
('Computer Science', 'Programming Fundamentals Test', 'Test covering basic programming concepts', 15, 12, 25);

-- 13. Grant necessary permissions
GRANT ALL ON verification_requests TO authenticated;
GRANT ALL ON verification_documents TO authenticated;
GRANT ALL ON verification_references TO authenticated;
GRANT ALL ON subject_proficiency_tests TO authenticated;
GRANT ALL ON test_questions TO authenticated;
GRANT ALL ON test_attempts TO authenticated;
GRANT ALL ON verification_workflow_logs TO authenticated;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Verification system created successfully!';
  RAISE NOTICE 'Tables created: verification_requests, verification_documents, verification_references, subject_proficiency_tests, test_questions, test_attempts, verification_workflow_logs';
  RAISE NOTICE 'Sample proficiency tests added for Mathematics, English, Science, and Computer Science';
END $$;
