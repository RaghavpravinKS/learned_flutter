-- ============================================================
-- COMPREHENSIVE SUPABASE SCHEMA INTROSPECTION
-- Run this in Supabase SQL Editor to get full database overview
-- ============================================================

-- ============================================================
-- SECTION 1: ALL DATABASE FUNCTIONS
-- ============================================================
SELECT 
    '=== DATABASE FUNCTIONS ===' as section;

SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type,
    CASE 
        WHEN p.prosecdef THEN 'SECURITY DEFINER'
        ELSE 'SECURITY INVOKER'
    END as security
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.prokind = 'f'
ORDER BY p.proname;

-- ============================================================
-- SECTION 2: ALL RLS POLICIES ON PUBLIC TABLES
-- ============================================================
SELECT 
    '=== RLS POLICIES ===' as section;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================
-- SECTION 3: RLS STATUS FOR ALL PUBLIC TABLES
-- ============================================================
SELECT 
    '=== RLS STATUS ===' as section;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    forcerowsecurity as rls_forced
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================
-- SECTION 4: ALL PUBLIC TABLES AND THEIR COLUMNS
-- ============================================================
SELECT 
    '=== TABLE COLUMNS ===' as section;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- ============================================================
-- SECTION 5: STORAGE BUCKETS
-- ============================================================
SELECT 
    '=== STORAGE BUCKETS ===' as section;

SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets
ORDER BY name;

-- ============================================================
-- SECTION 6: STORAGE POLICIES (view only, cannot modify)
-- ============================================================
SELECT 
    '=== STORAGE POLICIES ===' as section;

SELECT 
    policyname,
    tablename,
    cmd,
    permissive,
    roles
FROM pg_policies
WHERE schemaname = 'storage'
ORDER BY tablename, policyname;

-- ============================================================
-- SECTION 7: FOREIGN KEY RELATIONSHIPS
-- ============================================================
SELECT 
    '=== FOREIGN KEYS ===' as section;

SELECT
    tc.table_name as from_table,
    kcu.column_name as from_column,
    ccu.table_name as to_table,
    ccu.column_name as to_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ============================================================
-- SECTION 8: TRIGGERS
-- ============================================================
SELECT 
    '=== TRIGGERS ===' as section;

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- ============================================================
-- SECTION 9: CLASSROOM_ID COLUMN TYPES (to check uuid vs text)
-- ============================================================
SELECT 
    '=== CLASSROOM_ID COLUMN TYPES ===' as section;

SELECT 
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name = 'classroom_id'
ORDER BY table_name;

-- ============================================================
-- SECTION 10: CLASSROOMS TABLE ID TYPE
-- ============================================================
SELECT 
    '=== CLASSROOMS.ID TYPE ===' as section;

SELECT 
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'classrooms'
AND column_name = 'id';
