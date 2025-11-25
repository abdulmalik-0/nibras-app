-- Allow Super Admins to update users (to promote/demote admins)
CREATE POLICY "Super Admins can update users"
  ON users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND is_super_admin = true
    )
  );

-- Ensure RLS is enabled on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read users (needed for the list) - if not already present
-- Note: You might already have a read policy. If this errors saying "policy exists", just ignore it.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'users' AND policyname = 'Users are viewable by everyone'
    ) THEN
        CREATE POLICY "Users are viewable by everyone" ON users FOR SELECT USING (true);
    END IF;
END
$$;
