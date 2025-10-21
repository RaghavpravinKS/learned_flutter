-- Simple debug query - run this without RLS context

-- 1. Check if teacher record exists
SELECT 
    t.id as teacher_id,
    t.user_id,
    u.first_name,
    u.last_name,
    u.email
FROM teachers t
JOIN users u ON u.id = t.user_id
WHERE t.user_id = 'd7be67fb-1a90-4184-b27c-d86357cc6648';

-- 2. Check classroom relationship
SELECT 
    c.id as classroom_id,
    c.name,
    c.teacher_id,
    t.user_id as teacher_user_id,
    (t.user_id = 'd7be67fb-1a90-4184-b27c-d86357cc6648') as matches_user
FROM classrooms c
JOIN teachers t ON t.id = c.teacher_id
WHERE c.id = 'PHYSICS_11_CBSE';

-- 3. Check what the IN clause would return
SELECT c.id 
FROM classrooms c
INNER JOIN teachers t ON t.id = c.teacher_id
WHERE t.user_id = 'd7be67fb-1a90-4184-b27c-d86357cc6648';

-- 4. Check if assignments exist for this classroom
SELECT 
    a.id,
    a.title,
    a.classroom_id
FROM assignments a
WHERE a.classroom_id = 'PHYSICS_11_CBSE';

-- 5. Check if class_sessions exist for this classroom  
SELECT 
    cs.id,
    cs.session_date,
    cs.classroom_id
FROM class_sessions cs
WHERE cs.classroom_id = 'PHYSICS_11_CBSE';
