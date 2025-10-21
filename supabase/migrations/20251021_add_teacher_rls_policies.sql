-- Migration: Add RLS policies for teachers to access classroom-related data
-- Date: 2025-10-21
-- Purpose: Allow teachers to read assignments, learning materials, and class sessions for their classrooms

-- Enable RLS on tables (if not already enabled)
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to allow re-running this migration)
DROP POLICY IF EXISTS "Teachers can view assignments in their classrooms" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can create assignments in their classrooms" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can update assignments in their classrooms" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can delete assignments in their classrooms" ON public.assignments;

DROP POLICY IF EXISTS "Teachers can view materials in their classrooms" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can create materials in their classrooms" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can update materials in their classrooms" ON public.learning_materials;
DROP POLICY IF EXISTS "Teachers can delete materials in their classrooms" ON public.learning_materials;

DROP POLICY IF EXISTS "Teachers can view sessions in their classrooms" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can create sessions in their classrooms" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can update sessions in their classrooms" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can delete sessions in their classrooms" ON public.class_sessions;

-- ============================================================
-- ASSIGNMENTS POLICIES
-- ============================================================

-- Teachers can view assignments in their classrooms
CREATE POLICY "Teachers can view assignments in their classrooms" ON public.assignments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = assignments.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can create assignments in their classrooms
CREATE POLICY "Teachers can create assignments in their classrooms" ON public.assignments
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = assignments.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can update assignments in their classrooms
CREATE POLICY "Teachers can update assignments in their classrooms" ON public.assignments
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = assignments.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can delete assignments in their classrooms
CREATE POLICY "Teachers can delete assignments in their classrooms" ON public.assignments
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = assignments.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Students can view assignments in their enrolled classrooms
CREATE POLICY "Students can view assignments in enrolled classrooms" ON public.assignments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.student_enrollments se
      JOIN public.students s ON s.user_id = auth.uid()
      WHERE se.student_id = s.id
      AND se.classroom_id = assignments.classroom_id
      AND se.status = 'active'
    )
  );

-- ============================================================
-- LEARNING MATERIALS POLICIES
-- ============================================================

-- Teachers can view materials in their classrooms
CREATE POLICY "Teachers can view materials in their classrooms" ON public.learning_materials
  FOR SELECT
  USING (
    teacher_id IN (
      SELECT id FROM public.teachers
      WHERE user_id = auth.uid()
    )
    OR
    classroom_id IN (
      SELECT id FROM public.classrooms
      WHERE teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can create materials
CREATE POLICY "Teachers can create materials in their classrooms" ON public.learning_materials
  FOR INSERT
  WITH CHECK (
    teacher_id IN (
      SELECT id FROM public.teachers
      WHERE user_id = auth.uid()
    )
  );

-- Teachers can update their materials
CREATE POLICY "Teachers can update materials in their classrooms" ON public.learning_materials
  FOR UPDATE
  USING (
    teacher_id IN (
      SELECT id FROM public.teachers
      WHERE user_id = auth.uid()
    )
  );

-- Teachers can delete their materials
CREATE POLICY "Teachers can delete materials in their classrooms" ON public.learning_materials
  FOR DELETE
  USING (
    teacher_id IN (
      SELECT id FROM public.teachers
      WHERE user_id = auth.uid()
    )
  );

-- Students can view materials in their enrolled classrooms
CREATE POLICY "Students can view materials in enrolled classrooms" ON public.learning_materials
  FOR SELECT
  USING (
    classroom_id IN (
      SELECT se.classroom_id 
      FROM public.student_enrollments se
      JOIN public.students s ON s.user_id = auth.uid()
      WHERE se.student_id = s.id
      AND se.status = 'active'
    )
    OR classroom_id IS NULL -- Global materials (not classroom-specific)
  );

-- ============================================================
-- CLASS SESSIONS POLICIES
-- ============================================================

-- Teachers can view sessions in their classrooms
CREATE POLICY "Teachers can view sessions in their classrooms" ON public.class_sessions
  FOR SELECT
  USING (
    classroom_id IN (
      SELECT id FROM public.classrooms
      WHERE teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can create sessions in their classrooms
CREATE POLICY "Teachers can create sessions in their classrooms" ON public.class_sessions
  FOR INSERT
  WITH CHECK (
    classroom_id IN (
      SELECT id FROM public.classrooms
      WHERE teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can update sessions in their classrooms
CREATE POLICY "Teachers can update sessions in their classrooms" ON public.class_sessions
  FOR UPDATE
  USING (
    classroom_id IN (
      SELECT id FROM public.classrooms
      WHERE teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Teachers can delete sessions in their classrooms
CREATE POLICY "Teachers can delete sessions in their classrooms" ON public.class_sessions
  FOR DELETE
  USING (
    classroom_id IN (
      SELECT id FROM public.classrooms
      WHERE teacher_id IN (
        SELECT id FROM public.teachers
        WHERE user_id = auth.uid()
      )
    )
  );

-- Students can view sessions in their enrolled classrooms
CREATE POLICY "Students can view sessions in enrolled classrooms" ON public.class_sessions
  FOR SELECT
  USING (
    classroom_id IN (
      SELECT se.classroom_id 
      FROM public.student_enrollments se
      JOIN public.students s ON s.user_id = auth.uid()
      WHERE se.student_id = s.id
      AND se.status = 'active'
    )
  );

-- ============================================================
-- ADDITIONAL POLICIES FOR CLASSROOM ACCESS
-- ============================================================

-- Teachers can view their own classrooms
DROP POLICY IF EXISTS "Teachers can view their own classrooms" ON public.classrooms;
CREATE POLICY "Teachers can view their own classrooms" ON public.classrooms
  FOR SELECT
  USING (
    teacher_id IN (
      SELECT id FROM public.teachers
      WHERE user_id = auth.uid()
    )
    OR
    is_active = true -- Anyone can view active classrooms (for browsing)
  );

-- Teachers can update their own classrooms
DROP POLICY IF EXISTS "Teachers can update their own classrooms" ON public.classrooms;
CREATE POLICY "Teachers can update their own classrooms" ON public.classrooms
  FOR UPDATE
  USING (
    teacher_id IN (
      SELECT id FROM public.teachers
      WHERE user_id = auth.uid()
    )
  );

-- ============================================================
-- VERIFY POLICIES
-- ============================================================

-- Log successful migration
DO $$
BEGIN
  RAISE NOTICE 'RLS policies for teachers successfully created!';
  RAISE NOTICE 'Teachers can now:';
  RAISE NOTICE '  - Read/Write assignments in their classrooms';
  RAISE NOTICE '  - Read/Write learning materials';
  RAISE NOTICE '  - Read/Write class sessions';
  RAISE NOTICE '  - View and update their classrooms';
END $$;
