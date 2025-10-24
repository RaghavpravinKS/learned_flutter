-- =============================================
-- RECREATE CLASS_SESSIONS TABLE WITH ALL COLUMNS
-- This will drop and recreate the class_sessions table with all required columns including meeting_url
-- =============================================

-- Drop existing policies first
DROP POLICY IF EXISTS "Students can view sessions for enrolled classrooms" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can manage their classroom sessions" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can view their classroom sessions" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can insert their classroom sessions" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can update their classroom sessions" ON public.class_sessions;
DROP POLICY IF EXISTS "Teachers can delete their classroom sessions" ON public.class_sessions;

-- Drop the table (this will cascade delete all data)
DROP TABLE IF EXISTS public.class_sessions CASCADE;

-- Recreate the table with all columns including meeting_url
CREATE TABLE public.class_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id character varying NOT NULL,
  title character varying NOT NULL,
  description text,
  session_date date,
  start_time time,
  end_time time,
  session_type character varying DEFAULT 'live',
  meeting_url text,
  recording_url text,
  is_recorded boolean DEFAULT false,
  status character varying DEFAULT 'scheduled' 
    CHECK (status::text = ANY (ARRAY[
      'scheduled'::character varying,
      'in_progress'::character varying,
      'completed'::character varying,
      'cancelled'::character varying
    ]::text[])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT class_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT class_sessions_classroom_id_fkey FOREIGN KEY (classroom_id) 
    REFERENCES public.classrooms(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX idx_class_sessions_classroom_id ON public.class_sessions(classroom_id);
CREATE INDEX idx_class_sessions_session_date ON public.class_sessions(session_date);
CREATE INDEX idx_class_sessions_status ON public.class_sessions(status);

-- =============================================
-- RLS POLICIES
-- =============================================

-- Students can view sessions for their enrolled classrooms
CREATE POLICY "Students can view sessions for enrolled classrooms" ON public.class_sessions
    FOR SELECT USING (
        classroom_id IN (
            SELECT classroom_id FROM public.student_enrollments 
            WHERE student_id IN (SELECT id FROM public.students WHERE user_id = auth.uid())
            AND status = 'active'
        )
    );

-- Teachers can view their classroom sessions
CREATE POLICY "Teachers can view their classroom sessions" ON public.class_sessions
    FOR SELECT USING (
        classroom_id IN (
            SELECT c.id FROM public.classrooms c
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Teachers can insert sessions for their classrooms
CREATE POLICY "Teachers can insert their classroom sessions" ON public.class_sessions
    FOR INSERT WITH CHECK (
        classroom_id IN (
            SELECT c.id FROM public.classrooms c
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Teachers can update their classroom sessions
CREATE POLICY "Teachers can update their classroom sessions" ON public.class_sessions
    FOR UPDATE USING (
        classroom_id IN (
            SELECT c.id FROM public.classrooms c
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Teachers can delete their classroom sessions
CREATE POLICY "Teachers can delete their classroom sessions" ON public.class_sessions
    FOR DELETE USING (
        classroom_id IN (
            SELECT c.id FROM public.classrooms c
            JOIN public.teachers t ON c.teacher_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- =============================================
-- GRANT PERMISSIONS
-- =============================================

-- Grant permissions for authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.class_sessions TO authenticated;

-- Grant select permission for anon users (for public browsing if needed)
GRANT SELECT ON public.class_sessions TO anon;

-- =============================================
-- VERIFICATION
-- =============================================

-- Verify table was created with all columns
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'class_sessions'
ORDER BY ordinal_position;

-- Verify policies were created
SELECT 
    policyname,
    cmd as command_type
FROM pg_policies
WHERE schemaname = 'public' 
    AND tablename = 'class_sessions'
ORDER BY policyname;

SELECT '✅ class_sessions table recreated successfully with meeting_url and all columns!' as status;
