-- ========================================================================
-- COMPLETE DATABASE RESET FOR FLOW VERIFICATION
-- ========================================================================
-- Run this in Supabase Dashboard > SQL Editor
-- This will clear all your application data for fresh testing
-- ========================================================================

-- Step 1: Delete all public table data (in correct order to avoid FK errors)
DELETE FROM public.student_classroom_assignments;
DELETE FROM public.payments;
DELETE FROM public.classrooms;
DELETE FROM public.students;
DELETE FROM public.teachers;
DELETE FROM public.parents;
DELETE FROM public.users;

-- Step 2: Verify all public tables are empty
SELECT 
    'Reset Verification' as status,
    'public.users' as table_name, 
    COUNT(*) as remaining_records 
FROM public.users

UNION ALL

SELECT 
    'Reset Verification',
    'public.students', 
    COUNT(*) 
FROM public.students

UNION ALL

SELECT 
    'Reset Verification',
    'public.teachers', 
    COUNT(*) 
FROM public.teachers

UNION ALL

SELECT 
    'Reset Verification',
    'public.parents', 
    COUNT(*) 
FROM public.parents

UNION ALL

SELECT 
    'Reset Verification',
    'public.classrooms', 
    COUNT(*) 
FROM public.classrooms

UNION ALL

SELECT 
    'Reset Verification',
    'public.student_classroom_assignments', 
    COUNT(*) 
FROM public.student_classroom_assignments

UNION ALL

SELECT 
    'Reset Verification',
    'public.payments', 
    COUNT(*) 
FROM public.payments

ORDER BY table_name;

-- Expected result: All counts should be 0

-- Step 3: Show current auth users (you'll need to delete these manually)
SELECT 
    'Auth Users Still Present' as status,
    email,
    created_at,
    last_sign_in_at
FROM auth.users 
ORDER BY created_at;

SELECT 'Public tables reset completed! Now delete auth users manually.' as next_step;
