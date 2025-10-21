-- Alternative RLS policies for assignments and class_sessions
-- These use a simpler approach that might work better

-- First, drop the existing policies
DROP POLICY IF EXISTS "Teachers can view assignments in their classrooms" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can create assignments in their classrooms" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can update assignments in their classrooms" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can delete assignments in their classrooms" ON public.assignments;

DROP POLICY IF EXISTS "Teachers can view sessions in their classrooms" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can create sessions in their classrooms" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can update sessions in their classrooms" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can delete sessions in their classrooms" ON public.class_sessions;

-- ASSIGNMENTS - Simplified policies
CREATE POLICY "Teachers can view assignments in their classrooms" ON public.assignments
  FOR SELECT
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      INNER JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can create assignments in their classrooms" ON public.assignments
  FOR INSERT
  WITH CHECK (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      INNER JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can update assignments in their classrooms" ON public.assignments
  FOR UPDATE
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      INNER JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can delete assignments in their classrooms" ON public.assignments
  FOR DELETE
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      INNER JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

-- CLASS SESSIONS - Simplified policies
CREATE POLICY "Teachers can view sessions in their classrooms" ON public.class_sessions
  FOR SELECT
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      INNER JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can create sessions in their classrooms" ON public.class_sessions
  FOR INSERT
  WITH CHECK (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      INNER JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can update sessions in their classrooms" ON public.class_sessions
  FOR UPDATE
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      INNER JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

CREATE POLICY "Teachers can delete sessions in their classrooms" ON public.class_sessions
  FOR DELETE
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      INNER JOIN teachers t ON t.id = c.teacher_id
      WHERE t.user_id = auth.uid()
    )
  );

-- Students can view assignments in enrolled classrooms
DROP POLICY IF EXISTS "Students can view assignments in enrolled classrooms" ON public.assignments;
CREATE POLICY "Students can view assignments in enrolled classrooms" ON public.assignments
  FOR SELECT
  USING (
    is_published = true
    AND classroom_id IN (
      SELECT classroom_id 
      FROM student_enrollments se
      INNER JOIN students s ON s.id = se.student_id
      WHERE s.user_id = auth.uid()
      AND se.status = 'active'
    )
  );

-- Students can view sessions in enrolled classrooms
DROP POLICY IF EXISTS "Students can view sessions in enrolled classrooms" ON public.class_sessions;
CREATE POLICY "Students can view sessions in enrolled classrooms" ON public.class_sessions
  FOR SELECT
  USING (
    classroom_id IN (
      SELECT classroom_id 
      FROM student_enrollments se
      INNER JOIN students s ON s.id = se.student_id
      WHERE s.user_id = auth.uid()
      AND se.status = 'active'
    )
  );
