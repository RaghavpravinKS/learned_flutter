-- RLS INVESTIGATION - STEP 5: Alternative JOIN pattern
-- Only run this if Step 4 fails
-- This tests if INNER JOIN syntax works better than subqueries

-- Drop previous policies
DROP POLICY IF EXISTS "teachers_select_own_assignments_v4a" ON public.assignments;
DROP POLICY IF EXISTS "teachers_select_own_sessions_v4a" ON public.class_sessions;

-- Version 5: Using EXISTS with INNER JOIN
CREATE POLICY "teachers_select_own_assignments_v5"
ON public.assignments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 
        FROM public.teachers t
        WHERE t.id = assignments.teacher_id
        AND t.user_id = auth.uid()
    )
);

CREATE POLICY "teachers_select_own_sessions_v5"
ON public.class_sessions
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.classrooms c
        INNER JOIN public.teachers t ON t.id = c.teacher_id
        WHERE c.id = class_sessions.classroom_id
        AND t.user_id = auth.uid()
    )
);

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
-- Uses EXISTS instead of IN with subquery
-- - If app WORKS: EXISTS pattern is better for Supabase Flutter
-- - If app FAILS: The JOIN itself might be problematic
--
-- TEST YOUR APP NOW and report back
