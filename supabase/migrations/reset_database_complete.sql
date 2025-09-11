-- ========================================================================
-- LearnED Database Complete Reset Script
-- ========================================================================
-- This script will completely reset the database to a clean state
-- Use with CAUTION - this will delete ALL data including auth users
-- ========================================================================

-- Step 1: Delete all data from public tables (in correct order to avoid FK constraints)
DELETE FROM public.student_classroom_assignments;
DELETE FROM public.payments;
DELETE FROM public.classrooms;
DELETE FROM public.students;
DELETE FROM public.teachers;
DELETE FROM public.parents;
DELETE FROM public.users;

-- Step 2: Delete all authentication users (THIS WILL DELETE ALL LOGINS)
-- Note: This requires SUPERUSER privileges or service role key
DELETE FROM auth.users;

-- Step 3: Reset any sequences if they exist
-- This ensures IDs start from 1 again
SELECT setval(pg_get_serial_sequence('public.users', 'created_at'), 1, false) WHERE pg_get_serial_sequence('public.users', 'created_at') IS NOT NULL;
SELECT setval(pg_get_serial_sequence('public.students', 'created_at'), 1, false) WHERE pg_get_serial_sequence('public.students', 'created_at') IS NOT NULL;
SELECT setval(pg_get_serial_sequence('public.teachers', 'created_at'), 1, false) WHERE pg_get_serial_sequence('public.teachers', 'created_at') IS NOT NULL;
SELECT setval(pg_get_serial_sequence('public.classrooms', 'created_at'), 1, false) WHERE pg_get_serial_sequence('public.classrooms', 'created_at') IS NOT NULL;
SELECT setval(pg_get_serial_sequence('public.payments', 'created_at'), 1, false) WHERE pg_get_serial_sequence('public.payments', 'created_at') IS NOT NULL;

-- Step 4: Verify reset completion
SELECT 
  'auth.users' as table_name, 
  COUNT(*) as record_count 
FROM auth.users

UNION ALL

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

-- Expected result: All counts should be 0

-- ========================================================================
-- IMPORTANT NOTES:
-- ========================================================================
-- 1. This will delete ALL users including your current login
-- 2. You will need to re-register all accounts after this reset
-- 3. All enrollment data, payments, and user profiles will be lost
-- 4. This is perfect for testing the complete registration flow
-- 5. Make sure you have admin access to recreate users if needed
-- ========================================================================

SELECT 'Database reset completed successfully!' as status;
