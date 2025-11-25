-- Update Schema for Data Migration
-- Run this in Supabase SQL Editor

-- 1. Drop Foreign Key Constraint temporarily
ALTER TABLE questions DROP CONSTRAINT questions_category_id_fkey;

-- 2. Modify Categories Table
-- Change ID to TEXT to support string IDs like 'tech', 'sports'
ALTER TABLE categories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE categories ALTER COLUMN id TYPE TEXT;

-- Add missing columns
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS icon_name TEXT;

-- Remove old 'name' column if it exists (we use name_ar/name_en now)
-- Or we can keep it and make it nullable, but let's just make name_ar the main one.
-- For safety, let's just add the new ones and leave 'name' for now, making it nullable.
ALTER TABLE categories ALTER COLUMN name DROP NOT NULL;

-- 3. Modify Questions Table
-- Change category_id to TEXT
ALTER TABLE questions ALTER COLUMN category_id TYPE TEXT;

-- 4. Re-add Foreign Key Constraint
ALTER TABLE questions 
  ADD CONSTRAINT questions_category_id_fkey 
  FOREIGN KEY (category_id) 
  REFERENCES categories(id) 
  ON DELETE CASCADE;

-- 5. Clean up any existing data that might conflict (Optional but recommended for clean slate)
TRUNCATE TABLE questions CASCADE;
TRUNCATE TABLE categories CASCADE;
