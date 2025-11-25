-- Re-enable RLS after data migration is complete
-- Run this in Supabase SQL Editor AFTER the Dart migration script finishes

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
