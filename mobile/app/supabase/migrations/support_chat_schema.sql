-- Support Chat System
-- Real-time chat between users and support staff

-- Support Chat Rooms Table
CREATE TABLE IF NOT EXISTS support_chat_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed', 'waiting')),
  assigned_support_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_at TIMESTAMPTZ
);

-- Support Messages Table
CREATE TABLE IF NOT EXISTS support_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_room_id UUID NOT NULL REFERENCES support_chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_support BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_support_chat_rooms_user_id ON support_chat_rooms(user_id);
CREATE INDEX IF NOT EXISTS idx_support_chat_rooms_status ON support_chat_rooms(status);
CREATE INDEX IF NOT EXISTS idx_support_messages_chat_room_id ON support_messages(chat_room_id);
CREATE INDEX IF NOT EXISTS idx_support_messages_created_at ON support_messages(created_at);

-- Enable Row Level Security
ALTER TABLE support_chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for support_chat_rooms

-- Users can view their own chat rooms
CREATE POLICY "Users can view their own chat rooms"
  ON support_chat_rooms
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own chat rooms
CREATE POLICY "Users can create their own chat rooms"
  ON support_chat_rooms
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own chat rooms
CREATE POLICY "Users can update their own chat rooms"
  ON support_chat_rooms
  FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for support_messages

-- Users can view messages in their chat rooms
CREATE POLICY "Users can view messages in their chat rooms"
  ON support_messages
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM support_chat_rooms
      WHERE id = support_messages.chat_room_id
      AND user_id = auth.uid()
    )
  );

-- Users can create messages in their chat rooms
CREATE POLICY "Users can create messages in their chat rooms"
  ON support_messages
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM support_chat_rooms
      WHERE id = support_messages.chat_room_id
      AND user_id = auth.uid()
    )
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_support_chat_room_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE support_chat_rooms
  SET updated_at = NOW()
  WHERE id = NEW.chat_room_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update chat room timestamp when new message is added
CREATE TRIGGER update_chat_room_timestamp
AFTER INSERT ON support_messages
FOR EACH ROW
EXECUTE FUNCTION update_support_chat_room_timestamp();

-- Enable real-time for support_messages
ALTER PUBLICATION supabase_realtime ADD TABLE support_messages;
