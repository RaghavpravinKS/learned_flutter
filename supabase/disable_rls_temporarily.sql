-- TEMPORARY: Disable RLS on assignments and class_sessions
-- This will allow us to confirm the app works without RLS
-- We'll re-enable it once we figure out the auth header issue

ALTER TABLE public.assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions DISABLE ROW LEVEL SECURITY;

-- Verify
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('assignments', 'class_sessions');

-- NOTE: This is temporary and INSECURE!
-- Anyone can access all assignments and sessions now
-- We need to fix the auth token issue and re-enable RLS ASAP
