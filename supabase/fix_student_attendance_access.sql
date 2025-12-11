-- ============================================================
-- FIX: Students need to see their own attendance records
-- ============================================================

-- Add policy for students to SELECT their own attendance records
DROP POLICY IF EXISTS "attendance_student_select" ON public.session_attendance;

CREATE POLICY "attendance_student_select"
ON public.session_attendance
FOR SELECT
TO authenticated
USING (
  student_id IN (
    SELECT id FROM public.students WHERE user_id = auth.uid()
  )
);

-- Verify the policy was created
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'session_attendance'
ORDER BY policyname;
