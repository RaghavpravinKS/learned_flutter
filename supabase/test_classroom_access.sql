-- Test query to verify the fix works
-- This should run without permission errors after applying the migration

-- Test 1: Basic classroom access
SELECT 'Testing basic classroom access...' as test;
SELECT id, name, subject, grade_level FROM public.classrooms WHERE is_active = true LIMIT 3;

-- Test 2: Teacher profile access
SELECT 'Testing teacher profile access...' as test;
SELECT t.id, t.teacher_id, u.first_name, u.last_name 
FROM public.teachers t 
JOIN public.users u ON t.user_id = u.id 
WHERE t.status = 'active' LIMIT 3;

-- Test 3: Student enrollment counting (the failing query)
SELECT 'Testing student enrollment counting...' as test;
SELECT 
    se.classroom_id,
    COUNT(se.id) as enrollment_count
FROM public.student_enrollments se
WHERE se.status = 'active'
GROUP BY se.classroom_id
LIMIT 3;

-- Test 4: Full classroom query with student count (same as ClassroomService.getClassroomById)
SELECT 'Testing full classroom query with student count...' as test;
SELECT 
    c.id,
    c.name,
    c.subject,
    t.teacher_id,
    u.first_name || ' ' || u.last_name as teacher_name,
    COUNT(se.id) as student_count
FROM public.classrooms c
LEFT JOIN public.teachers t ON c.teacher_id = t.id
LEFT JOIN public.users u ON t.user_id = u.id
LEFT JOIN public.student_enrollments se ON c.id = se.classroom_id AND se.status = 'active'
WHERE c.is_active = true
GROUP BY c.id, c.name, c.subject, t.teacher_id, u.first_name, u.last_name
LIMIT 3;

-- Test 5: Classroom pricing access
SELECT 'Testing classroom pricing access...' as test;
SELECT cp.classroom_id, cp.price, pp.name as plan_name, pp.billing_cycle
FROM public.classroom_pricing cp
JOIN public.payment_plans pp ON cp.payment_plan_id = pp.id
LIMIT 5;