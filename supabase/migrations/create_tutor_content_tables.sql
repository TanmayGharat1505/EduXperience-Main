-- Create tables for tutor content management to replace dummy data
-- This migration adds support for real tutor content, certificates, and reviews

-- 1. Create tutor_content table for videos, materials, and student work examples
CREATE TABLE IF NOT EXISTS tutor_content (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tutor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('video', 'material', 'student_work')),
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT, -- URL to uploaded file
  thumbnail_url TEXT, -- URL to thumbnail image
  duration TEXT, -- For videos: "15:30"
  file_size TEXT, -- For materials: "2.3 MB"
  views INTEGER DEFAULT 0,
  downloads INTEGER DEFAULT 0,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create tutor_certificates table for verified certificates and achievements
CREATE TABLE IF NOT EXISTS tutor_certificates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tutor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  certificate_type TEXT NOT NULL CHECK (certificate_type IN ('teaching', 'subject_mastery', 'professional_development', 'academic', 'other')),
  issuing_organization TEXT,
  issue_date DATE,
  expiry_date DATE,
  certificate_url TEXT, -- URL to view the certificate
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create tutor_verifications table for comprehensive verification status
CREATE TABLE IF NOT EXISTS tutor_verifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tutor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  verification_type TEXT NOT NULL CHECK (verification_type IN ('profile', 'id', 'background_check', 'experience', 'qualifications', 'certificates')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  verification_notes TEXT,
  document_url TEXT, -- URL to verification document
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create tutor_achievements table for awards and recognition
CREATE TABLE IF NOT EXISTS tutor_achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tutor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  achievement_type TEXT NOT NULL CHECK (achievement_type IN ('award', 'recognition', 'publication', 'research', 'competition', 'other')),
  year INTEGER,
  organization TEXT,
  achievement_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  verified_by UUID REFERENCES auth.users(id),
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS tutor_content_tutor_id_idx ON tutor_content(tutor_id);
CREATE INDEX IF NOT EXISTS tutor_content_type_idx ON tutor_content(content_type);
CREATE INDEX IF NOT EXISTS tutor_certificates_tutor_id_idx ON tutor_certificates(tutor_id);
CREATE INDEX IF NOT EXISTS tutor_certificates_type_idx ON tutor_certificates(certificate_type);
CREATE INDEX IF NOT EXISTS tutor_verifications_tutor_id_idx ON tutor_verifications(tutor_id);
CREATE INDEX IF NOT EXISTS tutor_verifications_type_idx ON tutor_verifications(verification_type);
CREATE INDEX IF NOT EXISTS tutor_achievements_tutor_id_idx ON tutor_achievements(tutor_id);
CREATE INDEX IF NOT EXISTS tutor_achievements_type_idx ON tutor_achievements(achievement_type);

-- 6. Enable RLS
ALTER TABLE tutor_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_achievements ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies for tutor_content
CREATE POLICY "Anyone can view public tutor content" ON tutor_content
  FOR SELECT USING (is_public = true);

CREATE POLICY "Tutors can manage their own content" ON tutor_content
  FOR ALL USING (auth.uid() = tutor_id);

-- 8. RLS Policies for tutor_certificates
CREATE POLICY "Anyone can view verified tutor certificates" ON tutor_certificates
  FOR SELECT USING (verification_status = 'verified');

CREATE POLICY "Tutors can manage their own certificates" ON tutor_certificates
  FOR ALL USING (auth.uid() = tutor_id);

CREATE POLICY "Admins can verify certificates" ON tutor_certificates
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- 9. RLS Policies for tutor_verifications
CREATE POLICY "Anyone can view verification status" ON tutor_verifications
  FOR SELECT USING (true);

CREATE POLICY "Tutors can view their own verifications" ON tutor_verifications
  FOR SELECT USING (auth.uid() = tutor_id);

CREATE POLICY "Admins can manage verifications" ON tutor_verifications
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- 10. RLS Policies for tutor_achievements
CREATE POLICY "Anyone can view verified tutor achievements" ON tutor_achievements
  FOR SELECT USING (is_verified = true);

CREATE POLICY "Tutors can manage their own achievements" ON tutor_achievements
  FOR ALL USING (auth.uid() = tutor_id);

CREATE POLICY "Admins can verify achievements" ON tutor_achievements
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- 11. Functions for content management
CREATE OR REPLACE FUNCTION get_tutor_content_summary(p_tutor_id UUID)
RETURNS TABLE (
  content_type TEXT,
  count BIGINT,
  total_views BIGINT,
  total_downloads BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    tc.content_type,
    COUNT(*) as count,
    SUM(tc.views) as total_views,
    SUM(tc.downloads) as total_downloads
  FROM tutor_content tc
  WHERE tc.tutor_id = p_tutor_id AND tc.is_public = true
  GROUP BY tc.content_type
  ORDER BY tc.content_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Function to get tutor verification summary
CREATE OR REPLACE FUNCTION get_tutor_verification_summary(p_tutor_id UUID)
RETURNS TABLE (
  verification_type TEXT,
  status TEXT,
  verified_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    tv.verification_type,
    tv.status,
    tv.verified_at
  FROM tutor_verifications tv
  WHERE tv.tutor_id = p_tutor_id
  ORDER BY tv.verification_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Function to get tutor achievements summary
CREATE OR REPLACE FUNCTION get_tutor_achievements_summary(p_tutor_id UUID)
RETURNS TABLE (
  achievement_type TEXT,
  count BIGINT,
  verified_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ta.achievement_type,
    COUNT(*) as count,
    COUNT(CASE WHEN ta.is_verified = true THEN 1 END) as verified_count
  FROM tutor_achievements ta
  WHERE ta.tutor_id = p_tutor_id
  GROUP BY ta.achievement_type
  ORDER BY ta.achievement_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. Grant necessary permissions
GRANT ALL ON tutor_content TO authenticated;
GRANT ALL ON tutor_certificates TO authenticated;
GRANT ALL ON tutor_verifications TO authenticated;
GRANT ALL ON tutor_achievements TO authenticated;
GRANT EXECUTE ON FUNCTION get_tutor_content_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_tutor_verification_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_tutor_achievements_summary TO authenticated;

-- 15. Add comments for documentation
COMMENT ON TABLE tutor_content IS 'Tutor content including videos, study materials, and student work examples';
COMMENT ON TABLE tutor_certificates IS 'Tutor certificates and qualifications with verification status';
COMMENT ON TABLE tutor_verifications IS 'Comprehensive verification status for tutor profiles';
COMMENT ON TABLE tutor_achievements IS 'Tutor achievements, awards, and recognition';

-- 16. Insert sample data for testing (optional - can be removed in production)
-- This provides initial data to replace dummy content
INSERT INTO tutor_content (tutor_id, content_type, title, description, duration, file_size, views, downloads) VALUES
  ('00000000-0000-0000-0000-000000000001', 'video', 'Introduction to Calculus', 'Basic concepts and fundamental principles', '15:30', NULL, 1200, 0),
  ('00000000-0000-0000-0000-000000000001', 'video', 'Physics Problem Solving', 'Step-by-step approach to mechanics', '22:15', NULL, 856, 0),
  ('00000000-0000-0000-0000-000000000001', 'material', 'Calculus Notes', 'Comprehensive notes covering differentiation and integration', NULL, '2.3 MB', 0, 45),
  ('00000000-0000-0000-0000-000000000001', 'material', 'Practice Problems', '50+ solved problems with detailed explanations', NULL, '1.8 MB', 0, 32),
  ('00000000-0000-0000-0000-000000000001', 'material', 'Formula Sheet', 'Quick reference for all important formulas', NULL, '0.9 MB', 0, 67),
  ('00000000-0000-0000-0000-000000000001', 'student_work', 'Calculus Project - Optimization', 'Student successfully solved complex optimization problems', NULL, NULL, 0, 0),
  ('00000000-0000-0000-0000-000000000001', 'student_work', 'Physics Lab Report', 'Comprehensive analysis of motion experiments', NULL, NULL, 0, 0),
  ('00000000-0000-0000-0000-000000000001', 'student_work', 'Chemistry Problem Set', 'Excellent problem-solving approach to stoichiometry', NULL, NULL, 0, 0);

INSERT INTO tutor_certificates (tutor_id, title, description, certificate_type, issuing_organization, issue_date, verification_status) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Teaching Certification', 'Professional Development', 'teaching', 'National Teaching Board', '2023-01-15', 'verified'),
  ('00000000-0000-0000-0000-000000000001', 'Subject Mastery', 'Advanced Level', 'subject_mastery', 'Mathematics Association', '2022-06-20', 'verified');

INSERT INTO tutor_verifications (tutor_id, verification_type, status, verified_at) VALUES
  ('00000000-0000-0000-0000-000000000001', 'profile', 'verified', NOW()),
  ('00000000-0000-0000-0000-000000000001', 'id', 'verified', NOW()),
  ('00000000-0000-0000-0000-000000000001', 'background_check', 'verified', NOW()),
  ('00000000-0000-0000-0000-000000000001', 'experience', 'verified', NOW()),
  ('00000000-0000-0000-0000-000000000001', 'qualifications', 'verified', NOW());

INSERT INTO tutor_achievements (tutor_id, title, description, achievement_type, year, organization, is_verified) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Excellence in Teaching', 'Recognized for outstanding teaching methodology', 'award', 2023, 'Education Department', true),
  ('00000000-0000-0000-0000-000000000001', 'Research Publication', 'Published paper on innovative teaching methods', 'publication', 2022, 'Journal of Education', true);
