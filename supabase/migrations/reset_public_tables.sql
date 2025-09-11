-- ========================================================================
-- LearnED Public Tables Reset Script (Safe Version)
-- ========================================================================
-- This script resets only the public tables that you have full control over
-- For auth.users, you'll need to use Supabase Dashboard or Admin API
-- ========================================================================

-- Step 1: Delete all data from public tables (in correct order)
DELETE FROM public.student_classroom_assignments;
DELETE FROM public.payments;
DELETE FROM public.classrooms;
DELETE FROM public.students;
DELETE FROM public.teachers;
DELETE FROM public.parents;
DELETE FROM public.users;

-- Step 2: Verify public tables are empty
SELECT 
  'public.users' as table_name, 
  COUNT(*) as record_count 
FROM public.users

UNION ALL

SELECT 
  'public.students' as table_name, 
  COUNT(*) as record_count 
FROM public.students

UNION ALL

SELECT 
  'public.teachers' as table_name, 
  COUNT(*) as record_count 
FROM public.teachers

UNION ALL

SELECT 
  'public.parents' as table_name, 
  COUNT(*) as record_count 
FROM public.parents

UNION ALL

SELECT 
  'public.classrooms' as table_name, 
  COUNT(*) as record_count 
FROM public.classrooms

UNION ALL

SELECT 
  'public.student_classroom_assignments' as table_name, 
  COUNT(*) as record_count 
FROM public.student_classroom_assignments

UNION ALL

SELECT 
  'public.payments' as table_name, 
  COUNT(*) as record_count 
FROM public.payments

ORDER BY table_name;

-- Step 3: Check remaining auth users (read-only)
SELECT 
  'auth.users (remaining)' as table_name, 
  COUNT(*) as record_count 
FROM auth.users;

SELECT 'Public tables reset completed!' as status;

-- ========================================================================
-- NEXT STEPS FOR COMPLETE RESET:
-- ========================================================================
-- To reset auth.users, choose one of these methods:
--
-- METHOD 1: Supabase Dashboard
-- 1. Go to Authentication > Users
-- 2. Select all users and delete them manually
--
-- METHOD 2: Admin API (if you have service role key)
-- Use the admin API to delete users programmatically
--
-- METHOD 3: Project Reset (Nuclear Option)
-- Reset the entire Supabase project (creates new database)
-- ========================================================================
