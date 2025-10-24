-- =============================================
-- FIX ATTENDANCE MARKING ISSUES
-- =============================================

-- This file fixes:
-- 1. Adds RLS policies for session_attendance table (missing policies)
-- 2. Grants necessary permissions for teachers and students

-- =============================================
-- Enable RLS on session_attendance (if not already enabled)
-- =============================================
ALTER TABLE public.session_attendance ENABLE ROW LEVEL SECURITY;

-- =============================================
-- SESSION ATTENDANCE POLICIES
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

-- Grant permissions for authenticated users (teachers and students)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.session_attendance TO authenticated;

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Check if policies were created successfully
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'session_attendance'
ORDER BY policyname;

-- Check table permissions
SELECT 
    grantee, 
    privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'session_attendance';

SELECT 'Session attendance RLS policies and permissions set successfully!' as status;
