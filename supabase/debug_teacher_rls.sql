-- Debug queries to check teacher RLS setup
-- Run these in Supabase SQL Editor while logged in as the teacher user

-- 1. Check current authenticated user
SELECT auth.uid() as current_user_id;

-- 2. Check if teacher record exists for current user
SELECT 
    t.id as teacher_id,
    t.user_id,
    u.first_name,
    u.last_name,
    u.email
FROM teachers t
JOIN users u ON u.id = t.user_id
WHERE t.user_id = auth.uid();

-- 3. Check classrooms owned by current teacher
SELECT 
    c.id as classroom_id,
    c.name as classroom_name,
    c.teacher_id,
    t.user_id as teacher_user_id
FROM classrooms c
JOIN teachers t ON t.id = c.teacher_id
WHERE t.user_id = auth.uid();

-- 4. Check if current user can see assignments
SELECT 
    a.id,
    a.title,
    a.classroom_id,
    c.name as classroom_name,
    c.teacher_id
FROM assignments a
JOIN classrooms c ON c.id = a.classroom_id
JOIN teachers t ON t.id = c.teacher_id
WHERE t.user_id = auth.uid()
LIMIT 5;

-- 5. Check if current user can see class_sessions
SELECT 
    cs.id,
    cs.session_date,
    cs.classroom_id,
    c.name as classroom_name,
    c.teacher_id
FROM class_sessions cs
JOIN classrooms c ON c.id = cs.classroom_id
JOIN teachers t ON t.id = c.teacher_id
WHERE t.user_id = auth.uid()
LIMIT 5;

-- 6. Test the RLS policy condition directly
SELECT EXISTS (
    SELECT 1 FROM teachers
    WHERE user_id = auth.uid()
) as teacher_exists;

-- 7. Check specific classroom access
-- Replace 'YOUR_CLASSROOM_ID' with the actual classroom ID from your app
SELECT 
    c.id,
    c.name,
    c.teacher_id,
    t.user_id,
    (t.user_id = auth.uid()) as is_my_classroom
FROM classrooms c
LEFT JOIN teachers t ON t.id = c.teacher_id
WHERE c.id = 'YOUR_CLASSROOM_ID';
