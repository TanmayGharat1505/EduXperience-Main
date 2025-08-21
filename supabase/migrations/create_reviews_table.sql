-- Create reviews table for comprehensive tutor rating system
CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tutor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  subject_taught TEXT,
  class_type TEXT, -- online, offline, hybrid
  class_date DATE,
  anonymous BOOLEAN DEFAULT false,
  verified_student BOOLEAN DEFAULT false, -- student has actually taken classes
  helpful_votes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS reviews_tutor_id_idx ON reviews(tutor_id);
CREATE INDEX IF NOT EXISTS reviews_student_id_idx ON reviews(student_id);
CREATE INDEX IF NOT EXISTS reviews_rating_idx ON reviews(rating);
CREATE INDEX IF NOT EXISTS reviews_created_at_idx ON reviews(created_at);
CREATE INDEX IF NOT EXISTS reviews_subject_taught_idx ON reviews(subject_taught);

-- Enable RLS
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can view reviews" ON reviews
  FOR SELECT USING (true);

CREATE POLICY "Students can create reviews for tutors" ON reviews
  FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Students can update their own reviews" ON reviews
  FOR UPDATE USING (auth.uid() = student_id);

CREATE POLICY "Students can delete their own reviews" ON reviews
  FOR DELETE USING (auth.uid() = student_id);

-- Function to calculate average rating and total reviews for a tutor
CREATE OR REPLACE FUNCTION update_tutor_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update tutor_profiles table with new rating stats
  UPDATE tutor_profiles 
  SET 
    rating = (
      SELECT ROUND(AVG(rating)::numeric, 1)
      FROM reviews 
      WHERE tutor_id = COALESCE(NEW.tutor_id, OLD.tutor_id)
    ),
    total_reviews = (
      SELECT COUNT(*)
      FROM reviews 
      WHERE tutor_id = COALESCE(NEW.tutor_id, OLD.tutor_id)
    )
  WHERE user_id = COALESCE(NEW.tutor_id, OLD.tutor_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically update tutor rating stats
DROP TRIGGER IF EXISTS trigger_update_tutor_rating_stats ON reviews;
CREATE TRIGGER trigger_update_tutor_rating_stats
  AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_tutor_rating_stats();

-- Function to get rating breakdown for a tutor
CREATE OR REPLACE FUNCTION get_tutor_rating_breakdown(p_tutor_id UUID)
RETURNS TABLE (
  rating INTEGER,
  count BIGINT,
  percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.rating,
    COUNT(*) as count,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM reviews WHERE tutor_id = p_tutor_id))::numeric, 1) as percentage
  FROM reviews r
  WHERE r.tutor_id = p_tutor_id
  GROUP BY r.rating
  ORDER BY r.rating DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recent reviews for a tutor with pagination
CREATE OR REPLACE FUNCTION get_tutor_reviews(
  p_tutor_id UUID,
  p_limit INTEGER DEFAULT 10,
  p_offset INTEGER DEFAULT 0,
  p_min_rating INTEGER DEFAULT 0,
  p_max_rating INTEGER DEFAULT 5
)
RETURNS TABLE (
  id UUID,
  student_id UUID,
  rating INTEGER,
  review_text TEXT,
  subject_taught TEXT,
  class_type TEXT,
  class_date DATE,
  anonymous BOOLEAN,
  verified_student BOOLEAN,
  helpful_votes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE,
  student_name TEXT,
  student_avatar TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.student_id,
    r.rating,
    r.review_text,
    r.subject_taught,
    r.class_type,
    r.class_date,
    r.anonymous,
    r.verified_student,
    r.helpful_votes,
    r.created_at,
    CASE 
      WHEN r.anonymous THEN 'Anonymous Student'
      ELSE p.full_name
    END as student_name,
    CASE 
      WHEN r.anonymous THEN NULL
      ELSE p.profile_photo_url
    END as student_avatar
  FROM reviews r
  LEFT JOIN profiles p ON r.student_id = p.user_id
  WHERE r.tutor_id = p_tutor_id
    AND r.rating >= p_min_rating
    AND r.rating <= p_max_rating
  ORDER BY r.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT ALL ON reviews TO authenticated;
GRANT EXECUTE ON FUNCTION update_tutor_rating_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_tutor_rating_breakdown TO authenticated;
GRANT EXECUTE ON FUNCTION get_tutor_reviews TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE reviews IS 'Comprehensive reviews and ratings for tutors from students';
COMMENT ON COLUMN reviews.rating IS 'Rating from 1-5 stars';
COMMENT ON COLUMN reviews.review_text IS 'Detailed review text from student';
COMMENT ON COLUMN reviews.subject_taught IS 'Subject that was taught in the class';
COMMENT ON COLUMN reviews.class_type IS 'Type of class: online, offline, or hybrid';
COMMENT ON COLUMN reviews.anonymous IS 'Whether the student wants to remain anonymous';
COMMENT ON COLUMN reviews.verified_student IS 'Whether the student has actually taken classes with the tutor';
COMMENT ON COLUMN reviews.helpful_votes IS 'Number of helpful votes from other users';
