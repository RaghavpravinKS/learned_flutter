-- Let's see the actual enrollment records for your student
-- Student ID: 28d01dc1-b9f1-49c7-adbe-248270d035f9

-- 1. Check if student exists
SELECT 'Student Record:' as type, id, student_id, grade_level, status, created_at
FROM students 
WHERE id = '28d01dc1-b9f1-49c7-adbe-248270d035f9';

-- 2. Check student classroom assignments
SELECT 'Assignments:' as type, id, student_id, classroom_id, teacher_id, status, enrolled_date, progress, created_at
FROM student_classroom_assignments 
WHERE student_id = '28d01dc1-b9f1-49c7-adbe-248270d035f9';

-- 3. Check payments for this student
SELECT 'Payments:' as type, id, student_id, classroom_id, amount, status, created_at
FROM payments 
WHERE student_id = '28d01dc1-b9f1-49c7-adbe-248270d035f9';

-- 4. Check if there are ANY enrollments at all (to see if the table is empty)
SELECT 'Any Enrollments:' as type, COUNT(*) as total_count
FROM student_classroom_assignments;

-- 5. Check if there are ANY payments at all
SELECT 'Any Payments:' as type, COUNT(*) as total_count
FROM payments;
