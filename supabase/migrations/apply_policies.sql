-- Restore RLS Policies for Questions Table
-- Run this in Supabase SQL Editor

-- 1. Allow everyone to view questions (Public Access)
CREATE POLICY "Questions are viewable by everyone" 
  ON questions FOR SELECT 
  USING (true);

-- 2. Allow Admins to Insert
CREATE POLICY "Admins can insert questions" 
  ON questions FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND (is_admin = true OR is_super_admin = true)
    )
  );

-- 3. Allow Admins to Update
CREATE POLICY "Admins can update questions" 
  ON questions FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND (is_admin = true OR is_super_admin = true)
    )
  );

-- 4. Allow Admins to Delete
CREATE POLICY "Admins can delete questions" 
  ON questions FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND (is_admin = true OR is_super_admin = true)
    )
  );
