-- =============================================
-- FIX STUDENT_ASSIGNMENT_ATTEMPTS RLS POLICIES
-- Add proper policies for teachers and students
-- =============================================

-- Enable RLS if not already enabled
ALTER TABLE public.student_assignment_attempts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (if any)
DROP POLICY IF EXISTS "Teachers can view submissions for their assignments" ON public.student_assignment_attempts;
DROP POLICY IF EXISTS "Teachers can insert submissions for their assignments" ON public.student_assignment_attempts;
DROP POLICY IF EXISTS "Teachers can update submissions for their assignments" ON public.student_assignment_attempts;
DROP POLICY IF EXISTS "Students can view their own submissions" ON public.student_assignment_attempts;
DROP POLICY IF EXISTS "Students can insert their own submissions" ON public.student_assignment_attempts;
DROP POLICY IF EXISTS "Students can update their own submissions" ON public.student_assignment_attempts;

-- =============================================
-- CREATE RLS POLICIES
-- =============================================

-- Teachers can view submissions for their assignments
CREATE POLICY "Teachers can view submissions for their assignments" ON public.student_assignment_attempts
    FOR SELECT USING (
        assignment_id IN (
            SELECT a.id FROM public.assignments a
            WHERE a.teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
        )
    );

-- Teachers can update submissions for their assignments (for grading)
CREATE POLICY "Teachers can update submissions for their assignments" ON public.student_assignment_attempts
    FOR UPDATE USING (
        assignment_id IN (
            SELECT a.id FROM public.assignments a
            WHERE a.teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
        )
    );

-- Students can view their own submissions
CREATE POLICY "Students can view their own submissions" ON public.student_assignment_attempts
    FOR SELECT USING (
        student_id IN (SELECT id FROM public.students WHERE user_id = auth.uid())
    );

-- Students can insert their own submissions
CREATE POLICY "Students can insert their own submissions" ON public.student_assignment_attempts
    FOR INSERT WITH CHECK (
        student_id IN (SELECT id FROM public.students WHERE user_id = auth.uid())
    );

-- Students can update their own submissions (before final submission)
CREATE POLICY "Students can update their own submissions" ON public.student_assignment_attempts
    FOR UPDATE USING (
        student_id IN (SELECT id FROM public.students WHERE user_id = auth.uid())
    );

-- =============================================
-- GRANT PERMISSIONS
-- =============================================

-- Grant permissions for authenticated users
GRANT SELECT, INSERT, UPDATE ON public.student_assignment_attempts TO authenticated;

-- =============================================
-- VERIFICATION
-- =============================================

-- Verify policies were created
SELECT 
    policyname,
    cmd as command_type,
    permissive
FROM pg_policies
WHERE schemaname = 'public' 
    AND tablename = 'student_assignment_attempts'
ORDER BY policyname;

SELECT '✅ student_assignment_attempts RLS policies created successfully!' as status;
