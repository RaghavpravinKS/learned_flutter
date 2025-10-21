-- RLS INVESTIGATION - STEP 1: Enable RLS WITHOUT any policies
-- This tests if RLS itself causes the issue, or if it's the policies

-- First, verify current state (should be disabled)
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('assignments', 'class_sessions');

-- Enable RLS but don't add any policies yet
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;

-- Verify RLS is now enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('assignments', 'class_sessions');

-- Verify we still have the GRANT permissions (these should allow access even with RLS enabled)
SELECT 
    grantee, 
    table_name, 
    privilege_type 
FROM information_schema.table_privileges 
WHERE table_schema = 'public' 
AND table_name IN ('assignments', 'class_sessions')
AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, grantee, privilege_type;

-- EXPECTED BEHAVIOR:
-- With RLS enabled but NO policies, and with GRANT permissions:
-- - If app WORKS: RLS itself is fine, the problem was our policy logic
-- - If app FAILS: RLS + Supabase Flutter has a fundamental issue
--
-- TEST YOUR APP NOW and report back:
-- Does it still show assignments and sessions?
