-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_receiver_id_idx ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON messages(created_at);

-- Create a view for conversations (unique pairs of users who have messaged each other)
CREATE OR REPLACE VIEW conversations AS
SELECT DISTINCT
  LEAST(sender_id, receiver_id) as user1_id,
  GREATEST(sender_id, receiver_id) as user2_id
FROM messages;

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view messages they sent or received" ON messages
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages they send" ON messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they sent or received" ON messages
  FOR UPDATE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Function to get conversation messages
CREATE OR REPLACE FUNCTION get_conversation_messages(
  p_user1_id UUID,
  p_user2_id UUID,
  p_limit INTEGER DEFAULT 50
) RETURNS SETOF messages AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM messages
  WHERE (sender_id = p_user1_id AND receiver_id = p_user2_id) OR
        (sender_id = p_user2_id AND receiver_id = p_user1_id)
  ORDER BY created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
  p_sender_id UUID,
  p_receiver_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE messages
  SET read = TRUE
  WHERE sender_id = p_sender_id AND receiver_id = p_receiver_id AND read = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;