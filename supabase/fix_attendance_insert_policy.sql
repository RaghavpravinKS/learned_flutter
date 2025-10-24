-- =============================================
-- FIX SESSION_ATTENDANCE INSERT POLICY
-- The INSERT policy needs to check permissions properly
-- =============================================

-- Drop the existing INSERT policy
DROP POLICY IF EXISTS "Teachers can mark attendance for their sessions" ON public.session_attendance;

-- Recreate with a more robust policy that checks using WITH CHECK
CREATE POLICY "Teachers can mark attendance for their sessions" ON public.session_attendance
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM public.class_sessions cs
            JOIN public.classrooms c ON cs.classroom_id = c.id
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE cs.id = session_id 
            AND t.user_id = auth.uid()
        )
    );

-- Verify the policy was created
SELECT 
    policyname,
    cmd as command_type,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public' 
    AND tablename = 'session_attendance'
    AND policyname = 'Teachers can mark attendance for their sessions';

SELECT '✅ Session attendance INSERT policy fixed!' as status;
