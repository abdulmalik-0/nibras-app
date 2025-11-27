-- Enable Row Level Security on the categories table
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- POLICY 1: Allow everyone to read categories (so the app can display them)
DROP POLICY IF EXISTS "Enable read access for all users" ON public.categories;
CREATE POLICY "Enable read access for all users" ON public.categories
FOR SELECT USING (true);

-- POLICY 2: Allow Super Admins to update categories
-- This checks if the current user is a super_admin in the users table
DROP POLICY IF EXISTS "Enable update for super admins" ON public.categories;
CREATE POLICY "Enable update for super admins" ON public.categories
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.is_super_admin = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.users
    WHERE users.id = auth.uid()
    AND users.is_super_admin = true
  )
);

-- ALTERNATIVE (If the above is too complex or fails):
-- Allow ANY authenticated user to update categories (Use with caution, easier for testing)
-- To use this, uncomment the lines below and run them:
/*
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.categories;
CREATE POLICY "Enable update for authenticated users" ON public.categories
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);
*/
