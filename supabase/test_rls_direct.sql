-- Test if RLS policies are actually working
-- Run this in Supabase SQL Editor after logging in as the teacher

-- 1. First, verify you're authenticated
SELECT 
    auth.uid() as my_user_id,
    current_user as postgres_user;

-- 2. Check if you have a teacher record
SELECT 
    t.id as teacher_id,
    t.user_id,
    'Teacher record EXISTS' as status
FROM teachers t
WHERE t.user_id = auth.uid();

-- 3. Check what classrooms you should be able to see
SELECT 
    c.id,
    c.name,
    c.teacher_id
FROM classrooms c
INNER JOIN teachers t ON t.id = c.teacher_id
WHERE t.user_id = auth.uid();

-- 4. Test if you can directly query assignments (with RLS enabled)
-- This will fail if RLS policies aren't working
SELECT 
    a.id,
    a.title,
    a.classroom_id,
    'RLS is working!' as status
FROM assignments a
WHERE a.classroom_id = 'PHYSICS_11_CBSE'
LIMIT 1;

-- 5. Test if you can directly query class_sessions (with RLS enabled)
-- This will fail if RLS policies aren't working
SELECT 
    cs.id,
    cs.session_date,
    cs.classroom_id,
    'RLS is working!' as status
FROM class_sessions cs
WHERE cs.classroom_id = 'PHYSICS_11_CBSE'
LIMIT 1;

-- 6. Check what RLS policies exist on assignments table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'assignments';

-- 7. Check what RLS policies exist on class_sessions table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'class_sessions';
