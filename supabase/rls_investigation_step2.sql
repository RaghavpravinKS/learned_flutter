-- RLS INVESTIGATION - STEP 2: Add SIMPLEST possible policy
-- Only run this AFTER testing Step 1
-- This tests if a basic permissive policy works

-- Add the most permissive policy possible (allows everything)
CREATE POLICY "allow_all_assignments"
ON public.assignments
FOR ALL
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "allow_all_sessions"
ON public.class_sessions
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- Verify policies were created
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('assignments', 'class_sessions');

-- EXPECTED BEHAVIOR:
-- These policies allow EVERYTHING (super insecure but good for testing)
-- - If app WORKS: Basic policies work, we can add more restrictive ones
-- - If app FAILS: There's something wrong with how Supabase evaluates ANY policy
--
-- TEST YOUR APP NOW and report back
