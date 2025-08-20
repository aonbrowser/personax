-- Create table for storing lifecoaching notes from AI analysis
CREATE TABLE IF NOT EXISTS user_lifecoaching_notes (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  notes JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_lifecoaching_notes_user_id ON user_lifecoaching_notes(user_id);

-- Add comment
COMMENT ON TABLE user_lifecoaching_notes IS 'Stores AI-generated lifecoaching context notes for each user';
COMMENT ON COLUMN user_lifecoaching_notes.notes IS 'JSON data containing user insights for coaching: values, boundaries, triggers, communication style, etc.';