-- ==================================================
-- TEST ENROLLMENT FLOW
-- Test the complete enrollment process
-- ==================================================

-- 1. Check current student and classroom data
SELECT 'Current Students' as info, s.id, s.student_id, u.email, u.first_name, u.last_name
FROM students s
JOIN users u ON s.user_id = u.id
ORDER BY s.created_at DESC;

SELECT 'Current Classrooms' as info, c.id, c.name, c.subject, t.teacher_id
FROM classrooms c
JOIN teachers t ON c.teacher_id = t.id
ORDER BY c.created_at DESC
LIMIT 3;

SELECT 'Current Payment Plans' as info, pp.id, pp.name, pp.billing_cycle, pp.price_per_session
FROM payment_plans pp
WHERE pp.is_active = true
ORDER BY pp.created_at DESC
LIMIT 3;

-- 2. Test the enrollment function
-- Replace these UUIDs with actual values from your database
-- You can get them from the queries above

-- Example test (replace with your actual IDs):
/*
SELECT enroll_student_with_payment(
    '12345678-1234-5678-9012-345678901234'::UUID,  -- student_id (from students table)
    'classroom-id-here'::UUID,                     -- classroom_id (from classrooms table)
    'payment-plan-id-here'::UUID,                  -- payment_plan_id (from payment_plans table)
    50.00                                           -- amount_paid
);
*/

-- 3. Check enrollment results after running the function
SELECT 'Enrollment Requests' as info, er.*, c.name as classroom_name
FROM enrollment_requests er
JOIN classrooms c ON er.classroom_id = c.id
ORDER BY er.created_at DESC
LIMIT 5;

SELECT 'Student Classroom Assignments' as info, sca.*, c.name as classroom_name
FROM student_classroom_assignments sca
JOIN classrooms c ON sca.classroom_id = c.id
ORDER BY sca.created_at DESC
LIMIT 5;

SELECT 'Recent Payments' as info, p.*, c.name as classroom_name
FROM payments p
JOIN classrooms c ON p.classroom_id = c.id
ORDER BY p.created_at DESC
LIMIT 5;

-- 4. Check what getEnrolledClassrooms would return
-- This simulates what your app will fetch
SELECT 'Enrolled Classrooms Query' as info,
       sca.student_id,
       c.id as classroom_id,
       c.name as classroom_name,
       c.subject,
       c.grade_level,
       t.teacher_id,
       u.first_name || ' ' || u.last_name as teacher_name
FROM student_classroom_assignments sca
JOIN classrooms c ON sca.classroom_id = c.id
JOIN teachers t ON c.teacher_id = t.id
JOIN users u ON t.user_id = u.id
WHERE sca.status = 'active'
ORDER BY sca.enrolled_date DESC;

-- 5. Check trigger logs for any errors
SELECT 'Recent Trigger Logs' as info, message, error_message, metadata, event_time
FROM trigger_logs
ORDER BY event_time DESC
LIMIT 10;
