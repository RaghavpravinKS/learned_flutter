-- ============================================================================
-- FIX: Grant permissions and RLS for session_attendance table
-- Teachers need to be able to view/edit attendance for their sessions
-- ============================================================================

-- 1. Grant permissions to authenticated users
GRANT ALL ON public.session_attendance TO authenticated;
GRANT ALL ON public.session_attendance TO service_role;

-- 2. Ensure RLS is enabled
ALTER TABLE public.session_attendance ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies (if any)
DROP POLICY IF EXISTS "Teachers can view attendance for their sessions" ON public.session_attendance;
DROP POLICY IF EXISTS "Teachers can mark attendance" ON public.session_attendance;
DROP POLICY IF EXISTS "Teachers can update attendance" ON public.session_attendance;
DROP POLICY IF EXISTS "Teachers can delete attendance" ON public.session_attendance;
DROP POLICY IF EXISTS "Students can view their own attendance" ON public.session_attendance;

-- 4. Create SELECT policy - Teachers can view attendance for sessions in their classrooms
CREATE POLICY "Teachers can view attendance for their sessions"
  ON public.session_attendance
  FOR SELECT
  TO authenticated
  USING (
    session_id IN (
      SELECT s.id
      FROM class_sessions s
      JOIN classrooms c ON s.classroom_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );

-- 5. Create INSERT policy - Teachers can mark attendance for their sessions
CREATE POLICY "Teachers can mark attendance"
  ON public.session_attendance
  FOR INSERT
  TO authenticated
  WITH CHECK (
    session_id IN (
      SELECT s.id
      FROM class_sessions s
      JOIN classrooms c ON s.classroom_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );

-- 6. Create UPDATE policy - Teachers can update attendance for their sessions
CREATE POLICY "Teachers can update attendance"
  ON public.session_attendance
  FOR UPDATE
  TO authenticated
  USING (
    session_id IN (
      SELECT s.id
      FROM class_sessions s
      JOIN classrooms c ON s.classroom_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );

-- 7. Create DELETE policy - Teachers can delete attendance for their sessions
CREATE POLICY "Teachers can delete attendance"
  ON public.session_attendance
  FOR DELETE
  TO authenticated
  USING (
    session_id IN (
      SELECT s.id
      FROM class_sessions s
      JOIN classrooms c ON s.classroom_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );

-- 8. Allow students to view their own attendance
CREATE POLICY "Students can view their own attendance"
  ON public.session_attendance
  FOR SELECT
  TO authenticated
  USING (
    student_id IN (
      SELECT id
      FROM students
      WHERE user_id = auth.uid()
    )
  );

-- 9. Verify setup
SELECT 'Table grants:' as info;
SELECT 
  grantee, 
  privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'session_attendance'
ORDER BY grantee, privilege_type;

SELECT 'RLS enabled:' as info;
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'session_attendance';

SELECT 'Active policies:' as info;
SELECT 
  policyname,
  cmd AS operation,
  roles
FROM pg_policies
WHERE tablename = 'session_attendance'
ORDER BY cmd;
