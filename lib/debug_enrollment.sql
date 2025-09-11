-- Debug enrollment records for student 28d01dc1-b9f1-49c7-adbe-248270d035f9

-- Check if student exists
SELECT 'Student Record:' as type, id, student_id, grade_level, status, created_at
FROM students 
WHERE id = '28d01dc1-b9f1-49c7-adbe-248270d035f9';

-- Check student classroom assignments
SELECT 'Assignments:' as type, id, student_id, classroom_id, teacher_id, status, enrolled_date, progress
FROM student_classroom_assignments 
WHERE student_id = '28d01dc1-b9f1-49c7-adbe-248270d035f9';

-- Check payments (classroom_id should exist now)
SELECT 'Payments:' as type, id, student_id, classroom_id, amount, status, created_at
FROM payments 
WHERE student_id = '28d01dc1-b9f1-49c7-adbe-248270d035f9';

-- Check all available classrooms
SELECT 'Available Classrooms:' as type, id, name, subject, grade_level, is_active
FROM classrooms 
WHERE is_active = true
ORDER BY name
LIMIT 5;

-- Check all enrollments (regardless of student)
SELECT 'All Enrollments:' as type, student_id, classroom_id, status, enrolled_date
FROM student_classroom_assignments 
ORDER BY created_at DESC
LIMIT 10;
