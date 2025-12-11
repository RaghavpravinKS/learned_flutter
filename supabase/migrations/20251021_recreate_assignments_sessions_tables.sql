-- ============================================================
-- COMPLETE RECREATION OF ASSIGNMENTS AND CLASS_SESSIONS TABLES
-- This will drop everything and recreate from scratch
-- ============================================================

-- STEP 1: Drop existing tables (this also drops all policies)
-- ============================================================
DROP TABLE IF EXISTS public.assignments CASCADE;
DROP TABLE IF EXISTS public.class_sessions CASCADE;

-- STEP 2: Recreate ASSIGNMENTS table
-- ============================================================
CREATE TABLE public.assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  classroom_id uuid NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
  teacher_id uuid NOT NULL REFERENCES public.teachers(id) ON DELETE CASCADE,
  title varchar(255) NOT NULL,
  description text,
  assignment_type varchar(50) NOT NULL CHECK (
    assignment_type IN ('quiz', 'test', 'assignment', 'project')
  ),
  total_points integer NOT NULL DEFAULT 100,
  due_date timestamp with time zone,
  submission_type varchar(50),
  is_published boolean DEFAULT false,
  attachments jsonb,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

-- STEP 3: Recreate CLASS_SESSIONS table
-- ============================================================
CREATE TABLE public.class_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  classroom_id uuid NOT NULL REFERENCES public.classrooms(id) ON DELETE CASCADE,
  title varchar(255) NOT NULL,
  description text,
  session_date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  status varchar(50) DEFAULT 'scheduled' CHECK (
    status IN ('scheduled', 'in_progress', 'completed', 'cancelled')
  ),
  topic varchar(255),
  materials jsonb,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

-- STEP 4: Create indexes for performance
-- ============================================================
CREATE INDEX idx_assignments_classroom ON public.assignments(classroom_id);
CREATE INDEX idx_assignments_teacher ON public.assignments(teacher_id);
CREATE INDEX idx_assignments_due_date ON public.assignments(due_date);
CREATE INDEX idx_class_sessions_classroom ON public.class_sessions(classroom_id);
CREATE INDEX idx_class_sessions_date ON public.class_sessions(session_date);

-- STEP 5: Enable RLS
-- ============================================================
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;

-- STEP 6: Create RLS Policies for ASSIGNMENTS
-- ============================================================

-- Teachers can view all assignments in their classrooms
CREATE POLICY "teachers_select_assignments"
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

-- Teachers can insert assignments in their classrooms
CREATE POLICY "teachers_insert_assignments"
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
CREATE POLICY "teachers_update_assignments"
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
CREATE POLICY "teachers_delete_assignments"
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
CREATE POLICY "students_select_assignments"
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

-- STEP 7: Create RLS Policies for CLASS_SESSIONS
-- ============================================================

-- Teachers can view all sessions in their classrooms
CREATE POLICY "teachers_select_sessions"
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

-- Teachers can insert sessions in their classrooms
CREATE POLICY "teachers_insert_sessions"
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
CREATE POLICY "teachers_update_sessions"
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
CREATE POLICY "teachers_delete_sessions"
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
CREATE POLICY "students_select_sessions"
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

-- STEP 8: Re-insert test data
-- ============================================================

-- Get teacher_id for the Physics classroom
DO $$
DECLARE
  v_teacher_id uuid;
BEGIN
  SELECT teacher_id INTO v_teacher_id
  FROM public.classrooms
  WHERE id = 'PHYSICS_11_CBSE';

  -- Insert test assignment
  INSERT INTO public.assignments (
    id,
    classroom_id,
    teacher_id,
    title,
    description,
    assignment_type,
    total_points,
    due_date,
    is_published,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'PHYSICS_11_CBSE',
    v_teacher_id,
    'Test Assignment - Newton''s Laws',
    'Complete problems 1-10 from chapter 5',
    'assignment',
    100,
    (CURRENT_DATE + INTERVAL '7 days')::timestamp,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  );

  -- Insert test class session
  INSERT INTO public.class_sessions (
    id,
    classroom_id,
    title,
    description,
    session_date,
    start_time,
    end_time,
    status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'PHYSICS_11_CBSE',
    'Introduction to Mechanics',
    'First session covering basic concepts',
    (CURRENT_DATE + INTERVAL '2 days')::date,
    '10:00:00'::time,
    '11:30:00'::time,
    'scheduled',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  );

  RAISE NOTICE 'Tables recreated and test data inserted successfully!';
END $$;

-- STEP 9: Verification
-- ============================================================

-- Show created policies
SELECT 
  'ASSIGNMENTS POLICIES' as info,
  policyname,
  cmd as operation
FROM pg_policies
WHERE tablename = 'assignments'
ORDER BY policyname;

SELECT 
  'CLASS_SESSIONS POLICIES' as info,
  policyname,
  cmd as operation
FROM pg_policies
WHERE tablename = 'class_sessions'
ORDER BY policyname;

-- Show test data
SELECT 'TEST ASSIGNMENT' as info, id, title, classroom_id, is_published FROM public.assignments;
SELECT 'TEST SESSION' as info, id, title, classroom_id, session_date FROM public.class_sessions;

RAISE NOTICE '✓ Complete! Tables and policies recreated successfully.';
