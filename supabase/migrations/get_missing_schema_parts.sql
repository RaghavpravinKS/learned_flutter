-- This script gets triggers, functions, enums, and data that the schema export missed

-- 1. GET ALL CUSTOM FUNCTIONS
-- ==================================================
SELECT 
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
    AND p.proname NOT LIKE 'pg_%'
    AND p.proname NOT LIKE 'sql_%'
ORDER BY p.proname;

-- 2. GET ALL TRIGGERS
-- ==================================================
SELECT 
    c.relname as table_name,
    t.tgname as trigger_name,
    pg_get_triggerdef(t.oid) as trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
    AND t.tgisinternal = false
ORDER BY c.relname, t.tgname;

-- 3. GET ALL ENUM TYPES WITH VALUES
-- ==================================================
SELECT 
    t.typname as enum_name,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) as enum_values
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname = 'public'
GROUP BY t.typname
ORDER BY t.typname;

-- 4. CHECK IF ENROLLMENTS TABLE EXISTS
-- ==================================================
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'enrollments'
ORDER BY ordinal_position;

-- 5. CHECK AUTH.USERS STRUCTURE
-- ==================================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'auth' 
    AND table_name = 'users'
ORDER BY ordinal_position;

-- 6. CHECK PUBLIC.USERS STRUCTURE
-- ==================================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'users'
ORDER BY ordinal_position;

-- 7. GET RLS POLICIES
-- ==================================================
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 8. CHECK CURRENT DATA IN KEY TABLES
-- ==================================================
SELECT 'auth.users' as table_name, COUNT(*) as count FROM auth.users
UNION ALL
SELECT 'public.users' as table_name, COUNT(*) as count FROM public.users
UNION ALL
SELECT 'user_profiles' as table_name, COUNT(*) as count FROM public.user_profiles
UNION ALL
SELECT 'students' as table_name, COUNT(*) as count FROM public.students
UNION ALL
SELECT 'teachers' as table_name, COUNT(*) as count FROM public.teachers
UNION ALL
SELECT 'parents' as table_name, COUNT(*) as count FROM public.parents
UNION ALL
SELECT 'classrooms' as table_name, COUNT(*) as count FROM public.classrooms
UNION ALL
SELECT 'payments' as table_name, COUNT(*) as count FROM public.payments
UNION ALL
SELECT 'enrollment_requests' as table_name, COUNT(*) as count FROM public.enrollment_requests
UNION ALL
SELECT 'student_classroom_assignments' as table_name, COUNT(*) as count FROM public.student_classroom_assignments;

-- 9. CHECK FOR ENROLLMENT MECHANISM
-- ==================================================

-- Check if we have a simple enrollments table
SELECT 'enrollments table exists' as status, COUNT(*) as count 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'enrollments';

-- Check enrollment_requests structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'enrollment_requests'
ORDER BY ordinal_position;

-- Check student_classroom_assignments structure  
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'student_classroom_assignments'
ORDER BY ordinal_position;

-- 10. CHECK USER SIGNUP FLOW COMPLETENESS
-- ==================================================

-- Sample users to see the flow
SELECT 
    'auth.users sample' as type,
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 3;

-- Check if user_profiles are being created
SELECT 
    'user_profiles linkage' as check_type,
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN up.user_id IS NOT NULL THEN 1 END) as linked_profiles
FROM public.user_profiles up;

-- Check student creation
SELECT 
    'student records' as check_type,
    COUNT(*) as total_students,
    COUNT(CASE WHEN s.user_id IS NOT NULL THEN 1 END) as linked_students
FROM public.students s;