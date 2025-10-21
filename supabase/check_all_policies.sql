-- Check ALL policies on assignments and class_sessions
-- Looking for any that might be blocking access

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,  -- Should be PERMISSIVE not RESTRICTIVE
  roles,
  cmd,
  qual as using_clause,
  with_check
FROM pg_policies
WHERE tablename IN ('assignments', 'class_sessions')
ORDER BY tablename, cmd, policyname;

-- Check if RLS is enabled
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('assignments', 'class_sessions');

-- Check for any RESTRICTIVE policies (these could block access)
SELECT 
  tablename,
  policyname,
  'RESTRICTIVE - This could be blocking!' as warning
FROM pg_policies
WHERE tablename IN ('assignments', 'class_sessions')
AND permissive = 'RESTRICTIVE';
