-- Create Missing Tables Migration
-- This creates the essential tables needed for the requirements system

-- 1. Create requirements table
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

-- 2. Create requirement_tutor_matches table
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

-- 3. Create basic indexes
CREATE INDEX IF NOT EXISTS idx_requirements_student_id ON requirements(student_id);
CREATE INDEX IF NOT EXISTS idx_requirements_status ON requirements(status);
CREATE INDEX IF NOT EXISTS idx_requirement_tutor_matches_requirement_id ON requirement_tutor_matches(requirement_id);
CREATE INDEX IF NOT EXISTS idx_requirement_tutor_matches_tutor_id ON requirement_tutor_matches(tutor_id);

-- 4. Enable RLS
ALTER TABLE requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE requirement_tutor_matches ENABLE ROW LEVEL SECURITY;

-- 5. Create basic RLS policies
CREATE POLICY "Requirements - Users can view their own" ON requirements
    FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Requirements - Users can insert their own" ON requirements
    FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Requirements - Users can update their own" ON requirements
    FOR UPDATE USING (auth.uid() = student_id);

CREATE POLICY "Requirements - Tutors can view active" ON requirements
    FOR SELECT USING (status = 'active');

CREATE POLICY "Requirement Matches - Users can view for their requirements" ON requirement_tutor_matches
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM requirements 
            WHERE requirements.id = requirement_tutor_matches.requirement_id 
            AND requirements.student_id = auth.uid()
        )
    );

CREATE POLICY "Requirement Matches - Tutors can view their own" ON requirement_tutor_matches
    FOR SELECT USING (auth.uid() = tutor_id);

CREATE POLICY "Requirement Matches - Tutors can insert for themselves" ON requirement_tutor_matches
    FOR INSERT WITH CHECK (auth.uid() = tutor_id);

-- 6. Grant permissions
GRANT ALL ON requirements TO authenticated;
GRANT ALL ON requirement_tutor_matches TO authenticated;

-- 7. Create simple update trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 8. Create triggers
CREATE TRIGGER update_requirements_updated_at 
    BEFORE UPDATE ON requirements 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_requirement_tutor_matches_updated_at 
    BEFORE UPDATE ON requirement_tutor_matches 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Successfully created requirements system tables!';
    RAISE NOTICE 'You can now post requirements and match with tutors.';
END $$;
