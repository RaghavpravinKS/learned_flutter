-- =============================================
-- COMPLETE DATABASE RESET SCRIPT
-- This script will completely clear the database and start fresh
-- =============================================

-- WARNING: This will delete ALL data!
-- Make sure you want to proceed before running this script

-- 1. Drop all custom functions first (to avoid dependency issues)
DROP FUNCTION IF EXISTS enroll_student_with_payment(uuid, uuid, uuid, numeric);
DROP FUNCTION IF EXISTS get_student_classrooms(uuid);
DROP FUNCTION IF EXISTS create_teacher_by_admin(uuid, text, text, text, text, text, text, integer, text, jsonb);
DROP FUNCTION IF EXISTS verify_teacher_documents(uuid, uuid, boolean, text);
DROP FUNCTION IF EXISTS handle_new_user_signup();

-- 2. Drop all custom triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 3. Drop all custom types/enums (if any exist)
DROP TYPE IF EXISTS user_type CASCADE;
DROP TYPE IF EXISTS teacher_status CASCADE;
DROP TYPE IF EXISTS enrollment_status CASCADE;
DROP TYPE IF EXISTS payment_status CASCADE;
DROP TYPE IF EXISTS session_status CASCADE;

-- 4. Drop all tables in correct order (respecting foreign key dependencies)
-- Drop tables with foreign keys first
DROP TABLE IF EXISTS public.student_assignment_attempts CASCADE;
DROP TABLE IF EXISTS public.assignment_questions CASCADE;
DROP TABLE IF EXISTS public.session_attendance CASCADE;
DROP TABLE IF EXISTS public.learning_materials CASCADE;
DROP TABLE IF EXISTS public.student_enrollments CASCADE;
DROP TABLE IF EXISTS public.student_classroom_assignments CASCADE;
DROP TABLE IF EXISTS public.student_material_access CASCADE;
DROP TABLE IF EXISTS public.student_progress CASCADE;
DROP TABLE IF EXISTS public.student_subscriptions CASCADE;
DROP TABLE IF EXISTS public.classroom_pricing CASCADE;
DROP TABLE IF EXISTS public.teacher_documents CASCADE;
DROP TABLE IF EXISTS public.teacher_verification CASCADE;
DROP TABLE IF EXISTS public.teacher_availability CASCADE;
DROP TABLE IF EXISTS public.admin_activities CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.assignments CASCADE;
DROP TABLE IF EXISTS public.class_sessions CASCADE;
DROP TABLE IF EXISTS public.enrollment_requests CASCADE;
DROP TABLE IF EXISTS public.system_notifications CASCADE;
DROP TABLE IF EXISTS public.parent_student_relations CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- Drop main entity tables
DROP TABLE IF EXISTS public.teachers CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.parents CASCADE;
DROP TABLE IF EXISTS public.classrooms CASCADE;
DROP TABLE IF EXISTS public.payment_plans CASCADE;

-- Drop base tables
DROP TABLE IF EXISTS public.users CASCADE;

-- 5. Clear auth.users table (Supabase managed)
-- Note: In production, you might want to be more careful with this
DELETE FROM auth.users;

-- 6. Reset any sequences (if they exist)
-- PostgreSQL will auto-create sequences for serial columns
-- This ensures they start from 1 again

-- 7. Clear any custom policies
-- RLS policies will be dropped when tables are dropped

-- =============================================
-- DATABASE RESET COMPLETE
-- =============================================

-- To repopulate the database:
-- 1. Run current_schema.sql to recreate all tables and functions
-- 2. Run any test data scripts if needed
-- 3. Test the application functionality

SELECT 'Database reset completed successfully! All tables, functions, and data have been cleared.' as status;
