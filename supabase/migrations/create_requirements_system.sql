-- Create Requirements System Tables
-- This migration sets up the database structure for students to post requirements and tutors to respond

-- Requirements table to store student learning requirements
CREATE TABLE IF NOT EXISTS requirements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('academic', 'languages', 'skills', 'test_preparation', 'music', 'sports', 'technology', 'business', 'other')),
    subject TEXT NOT NULL,
    location TEXT NOT NULL,
    description TEXT NOT NULL,
    preferred_teaching_mode TEXT NOT NULL DEFAULT 'online' CHECK (preferred_teaching_mode IN ('online', 'offline', 'both', 'home_tuition')),
    preferred_time TEXT NOT NULL DEFAULT 'flexible' CHECK (preferred_time IN ('morning', 'afternoon', 'evening', 'flexible')),
    budget_range TEXT NOT NULL DEFAULT '1000-2000' CHECK (budget_range IN ('500-1000', '1000-2000', '2000-3000', '3000+')),
    urgency TEXT NOT NULL DEFAULT 'normal' CHECK (urgency IN ('low', 'normal', 'high')),
    additional_requirements TEXT,
    
    -- Category-specific fields (nullable)
    class_level TEXT CHECK (class_level IN ('primary', 'middle', 'secondary', 'higher_secondary', 'undergraduate', 'postgraduate', 'phd')),
    board TEXT CHECK (board IN ('cbse', 'icse', 'state_board', 'ib', 'igcse', 'university', 'other')),
    exam_preparation TEXT CHECK (exam_preparation IN ('beginner', 'intermediate', 'advanced', 'revision', 'mock_tests')),
    skill_level TEXT CHECK (skill_level IN ('beginner', 'elementary', 'intermediate', 'upper_intermediate', 'advanced', 'expert', 'native')),
    age_group TEXT CHECK (age_group IN ('children', 'teens', 'adults', 'seniors')),
    specific_topics TEXT,
    learning_goals TEXT,
    
    -- Status and metadata
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for efficient querying
CREATE INDEX IF NOT EXISTS idx_requirements_student_id ON requirements(student_id);
CREATE INDEX IF NOT EXISTS idx_requirements_category ON requirements(category);
CREATE INDEX IF NOT EXISTS idx_requirements_subject ON requirements(subject);
CREATE INDEX IF NOT EXISTS idx_requirements_location ON requirements(location);
CREATE INDEX IF NOT EXISTS idx_requirements_status ON requirements(status);
CREATE INDEX IF NOT EXISTS idx_requirements_created_at ON requirements(created_at);

-- Requirement-Tutor Matches table to track which tutors are interested in which requirements
CREATE TABLE IF NOT EXISTS requirement_tutor_matches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    requirement_id UUID NOT NULL REFERENCES requirements(id) ON DELETE CASCADE,
    tutor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'interested', 'not_interested', 'accepted', 'rejected')),
    response_message TEXT,
    proposed_rate DECIMAL(10,2),
    proposed_schedule TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique requirement-tutor combinations
    UNIQUE(requirement_id, tutor_id)
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_requirement_tutor_matches_requirement_id ON requirement_tutor_matches(requirement_id);
CREATE INDEX IF NOT EXISTS idx_requirement_tutor_matches_tutor_id ON requirement_tutor_matches(tutor_id);
CREATE INDEX IF NOT EXISTS idx_requirement_tutor_matches_status ON requirement_tutor_matches(status);

-- Notifications table to store system notifications for users
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('new_requirement', 'requirement_response', 'message', 'system', 'reminder')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- Flexible data storage for different notification types
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE requirement_tutor_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for requirements table
CREATE POLICY "Users can view their own requirements" ON requirements
    FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Users can insert their own requirements" ON requirements
    FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Users can update their own requirements" ON requirements
    FOR UPDATE USING (auth.uid() = student_id);

CREATE POLICY "Tutors can view active requirements" ON requirements
    FOR SELECT USING (status = 'active');

-- RLS Policies for requirement_tutor_matches table
CREATE POLICY "Users can view matches for their requirements" ON requirement_tutor_matches
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM requirements 
            WHERE requirements.id = requirement_tutor_matches.requirement_id 
            AND requirements.student_id = auth.uid()
        )
    );

CREATE POLICY "Tutors can view their own matches" ON requirement_tutor_matches
    FOR SELECT USING (auth.uid() = tutor_id);

CREATE POLICY "Tutors can insert matches for themselves" ON requirement_tutor_matches
    FOR INSERT WITH CHECK (auth.uid() = tutor_id);

CREATE POLICY "Tutors can update their own matches" ON requirement_tutor_matches
    FOR UPDATE USING (auth.uid() = tutor_id);

-- RLS Policies for notifications table
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert notifications for themselves" ON notifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_requirements_updated_at 
    BEFORE UPDATE ON requirements 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_requirement_tutor_matches_updated_at 
    BEFORE UPDATE ON requirement_tutor_matches 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data for testing (optional)
-- INSERT INTO requirements (student_id, category, subject, location, description, preferred_teaching_mode, budget_range) 
-- VALUES (
--     '00000000-0000-0000-0000-000000000000', -- Replace with actual user ID
--     'academic',
--     'mathematics',
--     'mumbai',
--     'Need help with calculus and algebra for 12th grade CBSE',
--     'online',
--     '1000-2000'
-- );

-- Grant necessary permissions
GRANT ALL ON requirements TO authenticated;
GRANT ALL ON requirement_tutor_matches TO authenticated;
GRANT ALL ON notifications TO authenticated;

-- Create a view for tutors to see requirements with student info (anonymized)
CREATE OR REPLACE VIEW tutor_requirements_view AS
SELECT 
    r.id,
    r.category,
    r.subject,
    r.location,
    r.description,
    r.preferred_teaching_mode,
    r.preferred_time,
    r.budget_range,
    r.urgency,
    r.class_level,
    r.board,
    r.exam_preparation,
    r.skill_level,
    r.age_group,
    r.specific_topics,
    r.learning_goals,
    r.status,
    r.created_at,
    -- Student info (anonymized for privacy)
    CONCAT(LEFT(p.full_name, 1), '***') as student_initials,
    p.city as student_city,
    p.area as student_area
FROM requirements r
JOIN profiles p ON r.student_id = p.user_id
WHERE r.status = 'active';

-- Grant access to the view
GRANT SELECT ON tutor_requirements_view TO authenticated;

-- Create a function to get matching tutors for a requirement
CREATE OR REPLACE FUNCTION get_matching_tutors_for_requirement(req_id UUID)
RETURNS TABLE (
    tutor_id UUID,
    full_name TEXT,
    city TEXT,
    area TEXT,
    profile_photo_url TEXT,
    hourly_rate_min DECIMAL(10,2),
    hourly_rate_max DECIMAL(10,2),
    teaching_mode TEXT,
    subjects TEXT[],
    specializations TEXT[],
    experience_years INTEGER,
    match_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tp.user_id,
        p.full_name,
        p.city,
        p.area,
        p.profile_photo_url,
        tp.hourly_rate_min,
        tp.hourly_rate_max,
        tp.teaching_mode,
        tp.subjects,
        tp.specializations,
        tp.experience_years,
        -- Calculate match score based on various criteria
        CASE 
            WHEN tp.subjects @> ARRAY[r.subject] THEN 10
            ELSE 0
        END +
        CASE 
            WHEN p.city = r.location OR p.area = r.location THEN 8
            ELSE 0
        END +
        CASE 
            WHEN tp.teaching_mode = r.preferred_teaching_mode THEN 5
            ELSE 0
        END +
        CASE 
            WHEN tp.hourly_rate_min <= 
                CASE 
                    WHEN r.budget_range = '500-1000' THEN 1000
                    WHEN r.budget_range = '1000-2000' THEN 2000
                    WHEN r.budget_range = '2000-3000' THEN 3000
                    ELSE 999999
                END THEN 3
            ELSE 0
        END as match_score
    FROM requirements r
    CROSS JOIN tutor_profiles tp
    JOIN profiles p ON tp.user_id = p.user_id
    WHERE r.id = req_id
    AND r.status = 'active'
    AND tp.is_verified = true
    AND tp.is_active = true
    AND p.role = 'tutor'
    ORDER BY match_score DESC, tp.experience_years DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_matching_tutors_for_requirement(UUID) TO authenticated;
