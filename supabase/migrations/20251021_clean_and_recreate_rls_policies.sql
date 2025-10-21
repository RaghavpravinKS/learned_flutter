-- Clean slate migration for RLS policies on assignments and class_sessions
-- This script drops ALL existing policies and recreates them properly

-- ============================================================
-- STEP 1: Drop ALL existing policies (clean slate)
-- ============================================================

-- Drop all policies from assignments table
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'assignments' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.assignments';
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
END
$$;

-- Drop all policies from class_sessions table
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'class_sessions' AND schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.class_sessions';
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
END
$$;

-- ============================================================
-- STEP 2: Ensure RLS is enabled
-- ============================================================

ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 3: Create fresh policies for ASSIGNMENTS
-- ============================================================

-- Teachers can view assignments in their classrooms
CREATE POLICY "Teachers can view assignments in their classrooms"
ON public.assignments
FOR SELECT
TO public
USING (
  classroom_id IN (
    SELECT c.id 
    FROM public.classrooms c
    INNER JOIN public.teachers t ON t.id = c.teacher_id
    WHERE t.user_id = auth.uid()
  )
);

-- Teachers can create assignments in their classrooms
CREATE POLICY "Teachers can create assignments in their classrooms"
ON public.assignments
FOR INSERT
TO public
WITH CHECK (
  classroom_id IN (
    SELECT c.id 
    FROM public.classrooms c
    INNER JOIN public.teachers t ON t.id = c.teacher_id
    WHERE t.user_id = auth.uid()
  )
);

-- Teachers can update assignments in their classrooms
CREATE POLICY "Teachers can update assignments in their classrooms"
ON public.assignments
FOR UPDATE
TO public
USING (
  classroom_id IN (
    SELECT c.id 
    FROM public.classrooms c
    INNER JOIN public.teachers t ON t.id = c.teacher_id
    WHERE t.user_id = auth.uid()
  )
);

-- Teachers can delete assignments in their classrooms
CREATE POLICY "Teachers can delete assignments in their classrooms"
ON public.assignments
FOR DELETE
TO public
USING (
  classroom_id IN (
    SELECT c.id 
    FROM public.classrooms c
    INNER JOIN public.teachers t ON t.id = c.teacher_id
    WHERE t.user_id = auth.uid()
  )
);

-- Students can view published assignments in enrolled classrooms
CREATE POLICY "Students can view assignments in enrolled classrooms"
ON public.assignments
FOR SELECT
TO public
USING (
  is_published = true
  AND classroom_id IN (
    SELECT se.classroom_id 
    FROM public.student_enrollments se
    INNER JOIN public.students s ON s.id = se.student_id
    WHERE s.user_id = auth.uid()
    AND se.status = 'active'
  )
);

-- ============================================================
-- STEP 4: Create fresh policies for CLASS_SESSIONS
-- ============================================================

-- Teachers can view sessions in their classrooms
CREATE POLICY "Teachers can view sessions in their classrooms"
ON public.class_sessions
FOR SELECT
TO public
USING (
  classroom_id IN (
    SELECT c.id 
    FROM public.classrooms c
    INNER JOIN public.teachers t ON t.id = c.teacher_id
    WHERE t.user_id = auth.uid()
  )
);

-- Teachers can create sessions in their classrooms
CREATE POLICY "Teachers can create sessions in their classrooms"
ON public.class_sessions
FOR INSERT
TO public
WITH CHECK (
  classroom_id IN (
    SELECT c.id 
    FROM public.classrooms c
    INNER JOIN public.teachers t ON t.id = c.teacher_id
    WHERE t.user_id = auth.uid()
  )
);

-- Teachers can update sessions in their classrooms
CREATE POLICY "Teachers can update sessions in their classrooms"
ON public.class_sessions
FOR UPDATE
TO public
USING (
  classroom_id IN (
    SELECT c.id 
    FROM public.classrooms c
    INNER JOIN public.teachers t ON t.id = c.teacher_id
    WHERE t.user_id = auth.uid()
  )
);

-- Teachers can delete sessions in their classrooms
CREATE POLICY "Teachers can delete sessions in their classrooms"
ON public.class_sessions
FOR DELETE
TO public
USING (
  classroom_id IN (
    SELECT c.id 
    FROM public.classrooms c
    INNER JOIN public.teachers t ON t.id = c.teacher_id
    WHERE t.user_id = auth.uid()
  )
);

-- Students can view sessions in enrolled classrooms
CREATE POLICY "Students can view sessions in enrolled classrooms"
ON public.class_sessions
FOR SELECT
TO public
USING (
  classroom_id IN (
    SELECT se.classroom_id 
    FROM public.student_enrollments se
    INNER JOIN public.students s ON s.id = se.student_id
    WHERE s.user_id = auth.uid()
    AND se.status = 'active'
  )
);

-- ============================================================
-- STEP 5: Verification - List all created policies
-- ============================================================

-- Show assignments policies
SELECT 
    'assignments' as table_name,
    policyname,
    cmd as operation
FROM pg_policies
WHERE tablename = 'assignments'
ORDER BY policyname;

-- Show class_sessions policies
SELECT 
    'class_sessions' as table_name,
    policyname,
    cmd as operation
FROM pg_policies
WHERE tablename = 'class_sessions'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✓ All RLS policies have been dropped and recreated successfully!';
    RAISE NOTICE '✓ Assignments table: 5 policies created';
    RAISE NOTICE '✓ Class_sessions table: 5 policies created';
END
$$;
