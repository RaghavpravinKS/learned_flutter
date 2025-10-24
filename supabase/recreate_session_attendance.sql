-- =============================================
-- RECREATE SESSION_ATTENDANCE TABLE WITH POLICIES
-- This will drop and recreate the session_attendance table with all required columns and policies
-- =============================================

-- Drop existing policies first
DROP POLICY IF EXISTS "Students can view their own attendance" ON public.session_attendance;
DROP POLICY IF EXISTS "Teachers can delete attendance for their sessions" ON public.session_attendance;
DROP POLICY IF EXISTS "Teachers can mark attendance for their sessions" ON public.session_attendance;
DROP POLICY IF EXISTS "Teachers can update attendance for their sessions" ON public.session_attendance;
DROP POLICY IF EXISTS "Teachers can view attendance for their sessions" ON public.session_attendance;

-- Drop the table (this will cascade delete all data)
DROP TABLE IF EXISTS public.session_attendance CASCADE;

-- Recreate the table with all columns
CREATE TABLE public.session_attendance (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  student_id uuid NOT NULL,
  attendance_status character varying DEFAULT 'absent'::character varying 
    CHECK (attendance_status::text = ANY (ARRAY[
      'present'::character varying, 
      'absent'::character varying, 
      'late'::character varying, 
      'excused'::character varying
    ]::text[])),
  join_time timestamp with time zone,
  leave_time timestamp with time zone,
  total_duration interval,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT session_attendance_pkey PRIMARY KEY (id),
  CONSTRAINT session_attendance_session_id_fkey FOREIGN KEY (session_id) 
    REFERENCES public.class_sessions(id) ON DELETE CASCADE,
  CONSTRAINT session_attendance_student_id_fkey FOREIGN KEY (student_id) 
    REFERENCES public.students(id) ON DELETE CASCADE,
  CONSTRAINT unique_session_student UNIQUE (session_id, student_id)
);

-- Enable RLS
ALTER TABLE public.session_attendance ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX idx_session_attendance_session_id ON public.session_attendance(session_id);
CREATE INDEX idx_session_attendance_student_id ON public.session_attendance(student_id);
CREATE INDEX idx_session_attendance_status ON public.session_attendance(attendance_status);

-- =============================================
-- RLS POLICIES
-- =============================================

-- Teachers can view attendance for their classroom sessions
CREATE POLICY "Teachers can view attendance for their sessions" ON public.session_attendance
    FOR SELECT USING (
        session_id IN (
            SELECT cs.id FROM public.class_sessions cs
            JOIN public.classrooms c ON cs.classroom_id = c.id
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Teachers can insert attendance for their classroom sessions
CREATE POLICY "Teachers can mark attendance for their sessions" ON public.session_attendance
    FOR INSERT WITH CHECK (
        session_id IN (
            SELECT cs.id FROM public.class_sessions cs
            JOIN public.classrooms c ON cs.classroom_id = c.id
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Teachers can update attendance for their classroom sessions
CREATE POLICY "Teachers can update attendance for their sessions" ON public.session_attendance
    FOR UPDATE USING (
        session_id IN (
            SELECT cs.id FROM public.class_sessions cs
            JOIN public.classrooms c ON cs.classroom_id = c.id
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Teachers can delete attendance for their classroom sessions
CREATE POLICY "Teachers can delete attendance for their sessions" ON public.session_attendance
    FOR DELETE USING (
        session_id IN (
            SELECT cs.id FROM public.class_sessions cs
            JOIN public.classrooms c ON cs.classroom_id = c.id
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Students can view their own attendance
CREATE POLICY "Students can view their own attendance" ON public.session_attendance
    FOR SELECT USING (
        student_id IN (SELECT id FROM public.students WHERE user_id = auth.uid())
    );

-- =============================================
-- GRANT PERMISSIONS
-- =============================================

-- Grant permissions for authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.session_attendance TO authenticated;

-- =============================================
-- VERIFICATION
-- =============================================

-- Verify table was created
SELECT 
    'session_attendance' as table_name,
    COUNT(*) as column_count
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'session_attendance';

-- Verify policies were created
SELECT 
    policyname,
    cmd as command_type
FROM pg_policies
WHERE schemaname = 'public' 
    AND tablename = 'session_attendance'
ORDER BY policyname;

SELECT '✅ session_attendance table recreated successfully with all columns and policies!' as status;
