-- 1. Recreate the table if it was accidentally dropped
-- We use IF NOT EXISTS so it's safe to run even if the table exists
CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id TEXT REFERENCES categories(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  options TEXT[] NOT NULL,
  difficulty TEXT DEFAULT 'medium',
  language TEXT DEFAULT 'ar',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  report_count INTEGER DEFAULT 0
);

-- 2. Ensure indexes exist
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category_id);

-- 3. IMPORTANT: Reload the Schema Cache
-- This fixes the "Could not find the table" error
NOTIFY pgrst, 'reload config';
