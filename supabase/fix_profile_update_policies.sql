-- Fix RLS policies for profile updates
-- This allows teachers to update their own profile data

-- First, check current policies
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'teachers')
ORDER BY tablename, policyname;

-- Drop ALL existing policies on users and teachers tables
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'users'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.users';
    END LOOP;
    
    FOR r IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'teachers'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.teachers';
    END LOOP;
END $$;

-- Disable RLS temporarily to clean up
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.teachers TO authenticated;

-- Create simple policies for users table
-- Allow authenticated users full access to users table
CREATE POLICY "Allow all for authenticated users" ON public.users
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create simple policies for teachers table  
-- Allow authenticated users full access to teachers table
CREATE POLICY "Allow all for authenticated users" ON public.teachers
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Verify the new policies
SELECT tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'teachers')
ORDER BY tablename, policyname;
