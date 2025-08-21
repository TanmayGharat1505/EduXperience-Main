-- Create Missing Tables for Student Dashboard
-- Run this in your Supabase SQL Editor to fix the 404/400 errors

-- 1. Create search_history table for personalized tutor recommendations
CREATE TABLE IF NOT EXISTS search_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  subjects TEXT[],
  teaching_mode TEXT,
  city TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies for search_history
ALTER TABLE search_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own search history" ON search_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own search history" ON search_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own search history" ON search_history
  FOR UPDATE USING (auth.uid() = user_id);

-- 2. Create messages table for student-tutor communication
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies for messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages they sent or received" ON messages
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages they send" ON messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they received" ON messages
  FOR UPDATE USING (auth.uid() = receiver_id);

-- 3. Create notifications table for system notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT,
  message TEXT,
  data JSONB,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies for notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- 4. Create learning_records table for tracking student progress
CREATE TABLE IF NOT EXISTS learning_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  tutor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  status TEXT DEFAULT 'scheduled', -- scheduled, completed, cancelled
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  duration INTEGER, -- in minutes
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies for learning_records
ALTER TABLE learning_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students can view own learning records" ON learning_records
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Tutors can view learning records they teach" ON learning_records
  FOR SELECT USING (auth.uid() = tutor_id);

CREATE POLICY "Students can insert own learning records" ON learning_records
  FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Tutors can update learning records they teach" ON learning_records
  FOR UPDATE USING (auth.uid() = tutor_id);

-- 5. Create classes table for scheduled classes
CREATE TABLE IF NOT EXISTS classes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  tutor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  duration INTEGER NOT NULL, -- in minutes
  status TEXT DEFAULT 'scheduled', -- scheduled, in_progress, completed, cancelled
  meeting_link TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies for classes
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Students can view own classes" ON classes
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Tutors can view classes they teach" ON classes
  FOR SELECT USING (auth.uid() = tutor_id);

CREATE POLICY "Students can insert own classes" ON classes
  FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Tutors can update classes they teach" ON classes
  FOR UPDATE USING (auth.uid() = tutor_id);

-- 6. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_search_history_user_id ON search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_learning_records_student_id ON learning_records(student_id);
CREATE INDEX IF NOT EXISTS idx_learning_records_tutor_id ON learning_records(tutor_id);
CREATE INDEX IF NOT EXISTS idx_classes_student_id ON classes(student_id);
CREATE INDEX IF NOT EXISTS idx_classes_tutor_id ON classes(tutor_id);

-- 7. Insert some sample data for testing
INSERT INTO search_history (user_id, subjects, teaching_mode, city) VALUES
  (auth.uid(), ARRAY['Mathematics', 'Physics'], 'online', 'Mumbai')
ON CONFLICT DO NOTHING;

-- 8. Check if tables were created successfully
SELECT 
  table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = table_name) as exists
FROM (VALUES 
  ('search_history'),
  ('messages'),
  ('notifications'),
  ('learning_records'),
  ('classes')
) AS t(table_name);
