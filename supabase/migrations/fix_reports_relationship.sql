-- Add foreign key constraint to reports table
ALTER TABLE reports
ADD CONSTRAINT reports_question_id_fkey
FOREIGN KEY (question_id)
REFERENCES questions(id)
ON DELETE CASCADE;

-- Refresh the schema cache (Supabase/PostgREST usually does this automatically on DDL, but good to be sure)
NOTIFY pgrst, 'reload config';
