-- =============================================
-- RLS POLICIES FOR FLUTTER APP
-- Created: December 5, 2025
-- 
-- These policies fix the student/teacher access for the Flutter app
-- Run these step by step and verify after each step
-- =============================================


-- =============================================
-- STEP 1: Fix students table RLS policies
-- Problem: Current policies use id = auth.uid() but should use user_id = auth.uid()
-- =============================================

DROP POLICY IF EXISTS "students_own_select" ON public.students;
DROP POLICY IF EXISTS "students_own_update" ON public.students;

CREATE POLICY "students_own_select" ON public.students
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());
-- ENABLES: Students can view their own student profile record

CREATE POLICY "students_own_update" ON public.students
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
-- ENABLES: Students can update their own student profile record


-- =============================================
-- STEP 2: Fix student_enrollments policies
-- Problem: enrollments_teacher_select queries classrooms causing loops
--          enrollments_student_select uses student_id = auth.uid() (wrong)
-- =============================================

DROP POLICY IF EXISTS "enrollments_teacher_select" ON public.student_enrollments;
DROP POLICY IF EXISTS "enrollments_student_select" ON public.student_enrollments;

CREATE POLICY "enrollments_teacher_select" ON public.student_enrollments
  FOR SELECT TO authenticated
  USING (
    classroom_id IN (
      SELECT c.id FROM public.classrooms c
      JOIN public.teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );
-- ENABLES: Teachers can view enrollments for classrooms they teach

CREATE POLICY "enrollments_student_select" ON public.student_enrollments
  FOR SELECT TO authenticated
  USING (
    student_id IN (
      SELECT s.id FROM public.students s WHERE s.user_id = auth.uid()
    )
  );
-- ENABLES: Students can view their own enrollments


-- =============================================
-- STEP 3: Fix teachers table RLS policies
-- Problem: Current policies use id = auth.uid() but should use user_id = auth.uid()
-- =============================================

DROP POLICY IF EXISTS "teachers_own_select" ON public.teachers;
DROP POLICY IF EXISTS "teachers_own_update" ON public.teachers;

CREATE POLICY "teachers_own_select" ON public.teachers
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());
-- ENABLES: Teachers can view their own teacher profile record

CREATE POLICY "teachers_own_update" ON public.teachers
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
-- ENABLES: Teachers can update their own teacher profile record


-- =============================================
-- STEP 5: Fix class_sessions student policy
-- Problem: student_enrollments.student_id = auth.uid() is wrong
-- =============================================

DROP POLICY IF EXISTS "sessions_student_select" ON public.class_sessions;

CREATE POLICY "sessions_student_select" ON public.class_sessions
  FOR SELECT TO authenticated
  USING (
    classroom_id IN (
      SELECT se.classroom_id 
      FROM public.student_enrollments se
      JOIN public.students s ON se.student_id = s.id
      WHERE s.user_id = auth.uid()
      AND se.status = 'active'
    )
  );
-- ENABLES: Students can view class sessions for their actively enrolled classrooms


-- =============================================
-- STEP 6: Fix learning_materials student policy
-- Problem: student_enrollments.student_id = auth.uid() is wrong
-- =============================================

DROP POLICY IF EXISTS "materials_student_select" ON public.learning_materials;

CREATE POLICY "materials_student_select" ON public.learning_materials
  FOR SELECT TO authenticated
  USING (
    classroom_id IN (
      SELECT se.classroom_id 
      FROM public.student_enrollments se
      JOIN public.students s ON se.student_id = s.id
      WHERE s.user_id = auth.uid()
      AND se.status = 'active'
    )
  );
-- ENABLES: Students can view learning materials for their actively enrolled classrooms


-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Verify students policies
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'students'
ORDER BY policyname;

-- Verify student_enrollments policies
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'student_enrollments'
ORDER BY policyname;

-- Verify teachers policies
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'teachers'
ORDER BY policyname;

-- Verify class_sessions policies
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'class_sessions'
ORDER BY policyname;

-- Verify learning_materials policies
SELECT policyname, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'learning_materials'
ORDER BY policyname;


-- =============================================
-- TODO: REMAINING STEPS (To be added)
-- =============================================

-- STEP 7: Fix assignments student policy
-- STEP 8: Add session_attendance student policy
