-- ============================================================
-- SAFE FIX: Teachers can see students in their classrooms
-- This version avoids infinite recursion by using a simpler approach
-- ============================================================

-- STEP 1: Create a SECURITY DEFINER function to bypass RLS recursion
-- This function runs with elevated privileges and returns student IDs
CREATE OR REPLACE FUNCTION get_teacher_student_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT DISTINCT se.student_id
  FROM student_enrollments se
  INNER JOIN classrooms c ON se.classroom_id = c.id
  INNER JOIN teachers t ON c.teacher_id = t.id
  WHERE t.user_id = auth.uid()
  AND se.status = 'active';
$$;

-- STEP 2: Create a function to get user IDs of students for a teacher
CREATE OR REPLACE FUNCTION get_teacher_student_user_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT DISTINCT s.user_id
  FROM students s
  INNER JOIN student_enrollments se ON s.id = se.student_id
  INNER JOIN classrooms c ON se.classroom_id = c.id
  INNER JOIN teachers t ON c.teacher_id = t.id
  WHERE t.user_id = auth.uid()
  AND se.status = 'active';
$$;

-- STEP 3: Add safe policy for teachers to SELECT students
DROP POLICY IF EXISTS "students_teacher_select" ON public.students;

CREATE POLICY "students_teacher_select"
ON public.students
FOR SELECT
TO authenticated
USING (
  id IN (SELECT get_teacher_student_ids())
);

-- STEP 4: Add safe policy for teachers to see student user profiles
DROP POLICY IF EXISTS "users_teacher_view_students" ON public.users;

CREATE POLICY "users_teacher_view_students"
ON public.users
FOR SELECT
TO authenticated
USING (
  id IN (SELECT get_teacher_student_user_ids())
);

-- STEP 5: Verify
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
AND policyname IN ('students_teacher_select', 'users_teacher_view_students');
