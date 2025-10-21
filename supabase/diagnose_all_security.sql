-- COMPREHENSIVE SECURITY DIAGNOSTIC

-- 1. Check if tables are actually in the public schema
SELECT 
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_name IN ('assignments', 'class_sessions')
ORDER BY table_schema, table_name;

-- 2. Check RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    forcerowsecurity as force_rls
FROM pg_tables
WHERE tablename IN ('assignments', 'class_sessions');

-- 3. Check for ANY policies (should be NONE)
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename IN ('assignments', 'class_sessions');

-- 4. Check table owner
SELECT 
    t.table_schema,
    t.table_name,
    t.table_type,
    c.relowner::regrole as owner
FROM information_schema.tables t
JOIN pg_class c ON c.relname = t.table_name
WHERE t.table_name IN ('assignments', 'class_sessions')
AND t.table_schema = 'public';

-- 5. Check ALL grants (not just specific roles)
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE table_name IN ('assignments', 'class_sessions')
ORDER BY table_name, grantee, privilege_type;

-- 6. Try a simple SELECT as anon (this simulates what your app does)
SET ROLE anon;
SELECT COUNT(*) as assignment_count FROM public.assignments;
SELECT COUNT(*) as session_count FROM public.class_sessions;
RESET ROLE;

-- 7. Check if there's a publication/replica identity issue
SELECT 
    schemaname,
    tablename,
    replica_identity
FROM pg_catalog.pg_tables t
LEFT JOIN pg_catalog.pg_class c ON c.relname = t.tablename
LEFT JOIN pg_catalog.pg_publication_tables pt ON pt.schemaname = t.schemaname AND pt.tablename = t.tablename
WHERE t.tablename IN ('assignments', 'class_sessions');
