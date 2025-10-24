-- =============================================
-- FIX ASSIGNMENTS RLS POLICIES
-- Add proper policies for teachers to manage assignments
-- =============================================

-- Check existing policies
SELECT 
    policyname,
    cmd as command_type
FROM pg_policies
WHERE schemaname = 'public' 
    AND tablename = 'assignments'
ORDER BY policyname;

-- Drop existing policies (if any)
DROP POLICY IF EXISTS "Teachers can view their assignments" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can insert their assignments" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can update their assignments" ON public.assignments;
DROP POLICY IF EXISTS "Teachers can delete their assignments" ON public.assignments;
DROP POLICY IF EXISTS "Students can view assignments for enrolled classrooms" ON public.assignments;

-- =============================================
-- CREATE ASSIGNMENTS RLS POLICIES
-- =============================================

-- Teachers can view their own assignments
CREATE POLICY "Teachers can view their assignments" ON public.assignments
    FOR SELECT USING (
        teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
    );

-- Teachers can insert their own assignments
CREATE POLICY "Teachers can insert their assignments" ON public.assignments
    FOR INSERT WITH CHECK (
        teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
    );

-- Teachers can update their own assignments
CREATE POLICY "Teachers can update their assignments" ON public.assignments
    FOR UPDATE USING (
        teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
    );

-- Teachers can delete their own assignments
CREATE POLICY "Teachers can delete their assignments" ON public.assignments
    FOR DELETE USING (
        teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid())
    );

-- Students can view assignments for their enrolled classrooms
CREATE POLICY "Students can view assignments for enrolled classrooms" ON public.assignments
    FOR SELECT USING (
        classroom_id IN (
            SELECT classroom_id FROM public.student_enrollments 
            WHERE student_id IN (SELECT id FROM public.students WHERE user_id = auth.uid())
            AND status = 'active'
        )
    );

-- =============================================
-- GRANT PERMISSIONS
-- =============================================

-- Grant permissions for authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.assignments TO authenticated;

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
    AND tablename = 'assignments'
ORDER BY policyname;

SELECT '✅ Assignments RLS policies created successfully!' as status;
