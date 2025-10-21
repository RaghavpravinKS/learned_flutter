-- RLS INVESTIGATION - STEP 4: Add teacher-specific policy (simple version)
-- Only run this AFTER Step 3 works
-- This tests if joining with teachers table works

-- Drop previous policies
DROP POLICY IF EXISTS "authenticated_can_select_assignments" ON public.assignments;
DROP POLICY IF EXISTS "authenticated_can_select_sessions" ON public.class_sessions;

-- Version 4A: Using teacher_id directly (if assignment has teacher_id column)
-- Check if assignments table has teacher_id column
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'assignments' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- If teacher_id exists in assignments, this should work:
CREATE POLICY "teachers_select_own_assignments_v4a"
ON public.assignments
FOR SELECT
TO authenticated
USING (
    teacher_id IN (
        SELECT id FROM public.teachers WHERE user_id = auth.uid()
    )
);

-- For class_sessions, we need to go through classrooms
CREATE POLICY "teachers_select_own_sessions_v4a"
ON public.class_sessions
FOR SELECT
TO authenticated
USING (
    classroom_id IN (
        SELECT id FROM public.classrooms WHERE teacher_id IN (
            SELECT id FROM public.teachers WHERE user_id = auth.uid()
        )
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
-- These policies restrict to teacher's own data
-- - If app WORKS: Subquery pattern works fine
-- - If app FAILS: The subquery might be the issue
--
-- TEST YOUR APP NOW and report back
