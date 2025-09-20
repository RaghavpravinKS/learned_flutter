-- =============================================
-- FIX MISSING RLS POLICIES FOR TEACHER DATA ACCESS
-- This migration adds missing policies for teachers and users tables
-- to allow public access to teacher profile information for classroom browsing
-- =============================================

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Anyone can view teacher profiles" ON public.teachers;
DROP POLICY IF EXISTS "Anyone can view teacher user profiles" ON public.users;
DROP POLICY IF EXISTS "Anyone can count active enrollments per classroom" ON public.student_enrollments;
DROP POLICY IF EXISTS "Anyone can read student existence for enrollment counting" ON public.students;

-- Add missing policy for teachers table (public read access to teacher profile info)
CREATE POLICY "Anyone can view teacher profiles" ON public.teachers
    FOR SELECT USING (status = 'active');

-- Add policy for users table to allow reading teacher profile information
CREATE POLICY "Anyone can view teacher user profiles" ON public.users
    FOR SELECT USING (user_type = 'teacher' AND is_active = true);

-- Add policy for student_enrollments to allow counting students per classroom
CREATE POLICY "Anyone can count active enrollments per classroom" ON public.student_enrollments
    FOR SELECT USING (status = 'active');

-- Add policy for students table to allow foreign key validation during enrollment counting
CREATE POLICY "Anyone can read student existence for enrollment counting" ON public.students
    FOR SELECT USING (status = 'active');

-- Grant necessary table permissions for anon users (classroom browsing)
GRANT SELECT ON public.teachers TO anon;
GRANT SELECT ON public.users TO anon;
GRANT SELECT ON public.classrooms TO anon;
GRANT SELECT ON public.classroom_pricing TO anon;
GRANT SELECT ON public.payment_plans TO anon;
GRANT SELECT ON public.student_enrollments TO anon;
GRANT SELECT ON public.students TO anon;

-- Grant permissions for authenticated users  
GRANT SELECT ON public.teachers TO authenticated;
GRANT SELECT ON public.users TO authenticated;
GRANT SELECT ON public.classrooms TO authenticated;
GRANT SELECT ON public.classroom_pricing TO authenticated;
GRANT SELECT ON public.payment_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.student_enrollments TO authenticated;
GRANT SELECT, INSERT ON public.payments TO authenticated;
GRANT SELECT ON public.students TO authenticated;

COMMENT ON MIGRATION IS 'Fix missing RLS policies for teacher data access and enrollment counting in classroom browsing';