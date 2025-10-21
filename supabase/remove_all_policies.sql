-- REMOVE ALL RLS POLICIES from assignments and class_sessions
-- This is the nuclear option to confirm the issue is RLS-related

-- Drop ALL policies on assignments table
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'assignments' AND schemaname = 'public') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.assignments';
    END LOOP;
END $$;

-- Drop ALL policies on class_sessions table
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'class_sessions' AND schemaname = 'public') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.class_sessions';
    END LOOP;
END $$;

-- Disable RLS as well
ALTER TABLE public.assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions DISABLE ROW LEVEL SECURITY;

-- Grant explicit permissions to public role (anon users)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assignments TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.class_sessions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assignments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.class_sessions TO authenticated;

-- Verify - should show NO policies
SELECT 
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('assignments', 'class_sessions');

-- Verify RLS status
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('assignments', 'class_sessions');

-- Verify permissions
SELECT 
    grantee, 
    table_name, 
    privilege_type 
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name IN ('assignments', 'class_sessions')
AND grantee IN ('anon', 'authenticated', 'public');
