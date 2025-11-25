-- Disable RLS temporarily for data migration
-- Run this in Supabase SQL Editor BEFORE running the Dart migration script

ALTER TABLE categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE questions DISABLE ROW LEVEL SECURITY;
