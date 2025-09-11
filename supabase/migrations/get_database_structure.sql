-- ==================================================
-- DATABASE STRUCTURE ANALYSIS SCRIPT
-- This script provides a comprehensive overview of all database objects
-- ==================================================

-- 1. LIST ALL TABLES WITH COLUMN DETAILS
-- ==================================================
SELECT 
    'TABLE' as object_type,
    schemaname,
    tablename as object_name,
    NULL as description
FROM pg_tables 
WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
ORDER BY schemaname, tablename;

-- Detailed table structure
SELECT 
    t.table_schema,
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    CASE 
        WHEN pk.column_name IS NOT NULL THEN 'PRIMARY KEY'
        WHEN fk.column_name IS NOT NULL THEN 'FOREIGN KEY'
        ELSE ''
    END as key_type
FROM information_schema.tables t
LEFT JOIN information_schema.columns c ON c.table_name = t.table_name AND c.table_schema = t.table_schema
LEFT JOIN (
    SELECT ku.table_name, ku.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage ku ON tc.constraint_name = ku.constraint_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
) pk ON pk.table_name = t.table_name AND pk.column_name = c.column_name
LEFT JOIN (
    SELECT ku.table_name, ku.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage ku ON tc.constraint_name = ku.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
) fk ON fk.table_name = t.table_name AND fk.column_name = c.column_name
WHERE t.table_schema = 'public'
ORDER BY t.table_name, c.ordinal_position;

-- ==================================================
-- 2. LIST ALL FUNCTIONS
-- ==================================================
SELECT 
    'FUNCTION' as object_type,
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;

-- ==================================================
-- 3. LIST ALL TRIGGERS
-- ==================================================
SELECT 
    'TRIGGER' as object_type,
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    pg_get_triggerdef(t.oid) as trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND t.tgisinternal = false
ORDER BY c.relname, t.tgname;

-- ==================================================
-- 4. LIST ALL VIEWS
-- ==================================================
SELECT 
    'VIEW' as object_type,
    schemaname,
    viewname as object_name,
    definition
FROM pg_views
WHERE schemaname = 'public'
ORDER BY viewname;

-- ==================================================
-- 5. LIST ALL INDEXES
-- ==================================================
SELECT 
    'INDEX' as object_type,
    schemaname,
    indexname,
    tablename,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ==================================================
-- 6. LIST ALL FOREIGN KEY CONSTRAINTS
-- ==================================================
SELECT 
    'FOREIGN_KEY' as object_type,
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ==================================================
-- 7. LIST ALL ENUM TYPES
-- ==================================================
SELECT 
    'ENUM' as object_type,
    n.nspname as schema_name,
    t.typname as enum_name,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) as enum_values
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname = 'public'
GROUP BY n.nspname, t.typname
ORDER BY t.typname;

-- ==================================================
-- 8. LIST ALL SEQUENCES
-- ==================================================
SELECT 
    'SEQUENCE' as object_type,
    schemaname,
    sequencename,
    start_value,
    min_value,
    max_value,
    increment_by
FROM pg_sequences
WHERE schemaname = 'public'
ORDER BY sequencename;

-- ==================================================
-- 9. LIST ALL POLICIES (RLS)
-- ==================================================
SELECT 
    'POLICY' as object_type,
    schemaname,
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

-- ==================================================
-- 10. TABLE SIZES AND ROW COUNTS
-- ==================================================
SELECT 
    'TABLE_STATS' as object_type,
    t.schemaname,
    t.tablename,
    pg_size_pretty(pg_total_relation_size('"'||t.schemaname||'"."'||t.tablename||'"')) as size,
    (SELECT n_tup_ins FROM pg_stat_user_tables WHERE relname = t.tablename) as row_count_estimate
FROM pg_tables t
WHERE t.schemaname = 'public'
ORDER BY pg_total_relation_size('"'||t.schemaname||'"."'||t.tablename||'"') DESC;

-- ==================================================
-- 11. SPECIFIC USER SIGNUP FLOW ANALYSIS
-- ==================================================

-- Check auth.users structure (if accessible)
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'auth' AND table_name = 'users'
ORDER BY ordinal_position;

-- Check user_profiles table specifically
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'user_profiles'
ORDER BY ordinal_position;

-- Check students table specifically
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'students'
ORDER BY ordinal_position;

-- Check enrollments table specifically
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'enrollments'
ORDER BY ordinal_position;

-- Check payments table specifically
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'payments'
ORDER BY ordinal_position;

-- ==================================================
-- 12. SAMPLE DATA COUNTS
-- ==================================================
SELECT 'user_profiles' as table_name, COUNT(*) as record_count FROM user_profiles
UNION ALL
SELECT 'students' as table_name, COUNT(*) as record_count FROM students
UNION ALL
SELECT 'teachers' as table_name, COUNT(*) as record_count FROM teachers
UNION ALL
SELECT 'classrooms' as table_name, COUNT(*) as record_count FROM classrooms
UNION ALL
SELECT 'enrollments' as table_name, COUNT(*) as record_count FROM enrollments
UNION ALL
SELECT 'payments' as table_name, COUNT(*) as record_count FROM payments
UNION ALL
SELECT 'payment_plans' as table_name, COUNT(*) as record_count FROM payment_plans
ORDER BY table_name;
