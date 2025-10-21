-- RLS INVESTIGATION - STEP 3: Add simple auth-based policy
-- Only run this AFTER Step 2 works
-- This tests if auth.uid() function works in policies

-- First, drop the "allow all" policies from Step 2
DROP POLICY IF EXISTS "allow_all_assignments" ON public.assignments;
DROP POLICY IF EXISTS "allow_all_sessions" ON public.class_sessions;

-- Add policy that requires authentication but doesn't check specific permissions
CREATE POLICY "authenticated_can_select_assignments"
ON public.assignments
FOR SELECT
TO authenticated
USING (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated_can_select_sessions"
ON public.class_sessions
FOR SELECT
TO authenticated
USING (auth.uid() IS NOT NULL);

-- Verify policies
SELECT 
    tablename,
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('assignments', 'class_sessions');

-- EXPECTED BEHAVIOR:
-- These policies allow any authenticated user to SELECT
-- - If app WORKS: auth.uid() is being evaluated correctly
-- - If app FAILS: auth.uid() might not be available in the policy context
--
-- TEST YOUR APP NOW and report back
