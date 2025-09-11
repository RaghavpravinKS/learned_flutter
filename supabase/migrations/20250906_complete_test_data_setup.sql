-- Complete system setup with test data compatible with current schema
-- This sets up everything needed for the enrollment flow to work

-- Step 1: Create the test student user and profile
INSERT INTO users (id, first_name, last_name, email, password_hash, user_type, phone, is_active, email_verified, created_at, updated_at) VALUES 
('mock-student-uuid-1234-5678-9012-345678901234', 'Test', 'Student', 'test.student@example.com', 'mock_hash', 'student', '+1234567892', true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email,
  updated_at = NOW();

-- Step 2: Create the student record
INSERT INTO students (id, user_id, student_id, grade_level, school_name, status, created_at, updated_at) VALUES 
('mock-student-uuid-1234-5678-9012-345678901234', 'mock-student-uuid-1234-5678-9012-345678901234', 'STU-TEST-001', 10, 'Test High School', 'active', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  grade_level = EXCLUDED.grade_level,
  school_name = EXCLUDED.school_name,
  updated_at = NOW();

-- Step 3: Create teacher users (if they don't exist)
INSERT INTO users (id, first_name, last_name, email, password_hash, user_type, phone, is_active, email_verified, created_at, updated_at) VALUES 
('teacher-user-sarah-johnson-uuid-1234', 'Dr. Sarah', 'Johnson', 'sarah.johnson@school.edu', 'mock_hash', 'teacher', '+1234567890', true, true, NOW(), NOW()),
('teacher-user-michael-chen-uuid-5678', 'Prof. Michael', 'Chen', 'michael.chen@school.edu', 'mock_hash', 'teacher', '+1234567891', true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email,
  updated_at = NOW();

-- Step 4: Create teacher records if they don't exist
INSERT INTO teachers (id, user_id, teacher_id, qualifications, experience_years, status, created_at, updated_at) VALUES 
('be59f28c-795b-468e-b219-c39fc22b2cf2', 'teacher-user-sarah-johnson-uuid-1234', 'TCH-SARAH-001', 'PhD in Mathematics, MIT', 8, 'active', NOW(), NOW()),
('d95d245e-721e-4489-ad9f-bf17823b0d4f', 'teacher-user-michael-chen-uuid-5678', 'TCH-MICHAEL-002', 'PhD in Physics, Stanford', 12, 'active', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  qualifications = EXCLUDED.qualifications,
  experience_years = EXCLUDED.experience_years,
  updated_at = NOW();

-- Step 5: Create test classrooms
INSERT INTO classrooms (
  id, 
  name, 
  subject, 
  description, 
  grade_level, 
  board, 
  teacher_id, 
  max_students, 
  current_enrollment, 
  is_active, 
  status,
  next_session_date,
  start_date,
  end_date,
  schedule_days,
  schedule_time,
  duration_weeks,
  created_at, 
  updated_at
) VALUES 
(
  '75ac924c-a66e-4172-bfd5-3ec4b9757949',
  'Advanced Mathematics',
  'Mathematics',
  'Advanced calculus and algebra concepts for grade 12 students',
  12,
  'CBSE',
  'be59f28c-795b-468e-b219-c39fc22b2cf2',
  30,
  0,
  true,
  'active',
  NOW() + INTERVAL '1 day',
  NOW(),
  NOW() + INTERVAL '3 months',
  ARRAY['Monday', 'Wednesday', 'Friday'],
  '10:00'::TIME,
  12,
  NOW(),
  NOW()
),
(
  '011ce5c6-fa85-4b94-aa63-9c5ef43a95f3',
  'Introduction to Physics',
  'Physics',
  'Fundamentals of physics and mechanics for grade 11 students',
  11,
  'CBSE',
  'd95d245e-721e-4489-ad9f-bf17823b0d4f',
  25,
  0,
  true,
  'active',
  NOW() + INTERVAL '2 days',
  NOW(),
  NOW() + INTERVAL '4 months',
  ARRAY['Tuesday', 'Thursday'],
  '14:00'::TIME,
  16,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  teacher_id = EXCLUDED.teacher_id,
  is_active = EXCLUDED.is_active,
  status = EXCLUDED.status,
  next_session_date = EXCLUDED.next_session_date,
  updated_at = NOW();

-- Step 6: Create payment plans for the classrooms
INSERT INTO payment_plans (id, name, description, billing_cycle, features, is_active, created_at, updated_at) VALUES 
('plan-monthly-math', 'Monthly Plan', 'Pay monthly for Mathematics course', 'monthly', '["Unlimited access", "1-on-1 support", "Progress tracking"]'::jsonb, true, NOW(), NOW()),
('plan-full-math', 'Full Course', 'One-time payment for complete Mathematics course', 'one_time', '["Lifetime access", "Certificate", "Priority support"]'::jsonb, true, NOW(), NOW()),
('plan-monthly-physics', 'Monthly Plan', 'Pay monthly for Physics course', 'monthly', '["Unlimited access", "Lab sessions", "Progress tracking"]'::jsonb, true, NOW(), NOW()),
('plan-full-physics', 'Full Course', 'One-time payment for complete Physics course', 'one_time', '["Lifetime access", "Certificate", "Lab equipment"]'::jsonb, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  updated_at = NOW();

-- Step 7: Create classroom pricing
INSERT INTO classroom_pricing (id, classroom_id, payment_plan_id, price, currency, is_active, created_at, updated_at) VALUES 
(gen_random_uuid(), '75ac924c-a66e-4172-bfd5-3ec4b9757949', 'plan-monthly-math', 79.99, 'USD', true, NOW(), NOW()),
(gen_random_uuid(), '75ac924c-a66e-4172-bfd5-3ec4b9757949', 'plan-full-math', 799.99, 'USD', true, NOW(), NOW()),
(gen_random_uuid(), '011ce5c6-fa85-4b94-aa63-9c5ef43a95f3', 'plan-monthly-physics', 89.99, 'USD', true, NOW(), NOW()),
(gen_random_uuid(), '011ce5c6-fa85-4b94-aa63-9c5ef43a95f3', 'plan-full-physics', 899.99, 'USD', true, NOW(), NOW())
ON CONFLICT (classroom_id, payment_plan_id) DO UPDATE SET
  price = EXCLUDED.price,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

-- Step 8: Create sample enrollment to test "My Classes" functionality
-- This simulates a student who has already enrolled in one classroom
DO $$
DECLARE
  v_enrollment_id UUID := gen_random_uuid();
  v_payment_id UUID := gen_random_uuid();
BEGIN
  -- Create payment record
  INSERT INTO payments (
    id,
    student_id,
    classroom_id,
    amount,
    currency,
    payment_method,
    transaction_id,
    status,
    created_at
  ) VALUES (
    v_payment_id,
    'mock-student-uuid-1234-5678-9012-345678901234',
    '75ac924c-a66e-4172-bfd5-3ec4b9757949',
    79.99,
    'USD',
    'simulation',
    'sim_test_enrollment_payment',
    'completed',
    NOW() - INTERVAL '3 days'
  ) ON CONFLICT (transaction_id) DO NOTHING;

  -- Create enrollment record using student_classroom_assignments
  INSERT INTO student_classroom_assignments (
    id,
    student_id,
    classroom_id,
    teacher_id,
    enrolled_date,
    status,
    progress,
    payment_id,
    created_at,
    updated_at
  ) VALUES (
    v_enrollment_id,
    'mock-student-uuid-1234-5678-9012-345678901234',
    '75ac924c-a66e-4172-bfd5-3ec4b9757949',
    'be59f28c-795b-468e-b219-c39fc22b2cf2',
    NOW() - INTERVAL '3 days',
    'active',
    25.5,
    v_payment_id,
    NOW() - INTERVAL '3 days',
    NOW()
  ) ON CONFLICT DO NOTHING;

EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Sample enrollment creation failed: %', SQLERRM;
END $$;

-- Step 9: Update classroom enrollment counts
UPDATE classrooms 
SET current_enrollment = (
  SELECT COUNT(*) 
  FROM student_classroom_assignments 
  WHERE classroom_id = classrooms.id 
  AND status = 'active'
),
updated_at = NOW();

-- Step 10: Verification queries
SELECT 
  'System Setup Verification' as check_type,
  'Users' as table_name,
  COUNT(*) as record_count
FROM users 
WHERE user_type IN ('student', 'teacher')

UNION ALL

SELECT 
  'System Setup Verification',
  'Teachers with Users',
  COUNT(*)
FROM teachers t
JOIN users u ON t.user_id = u.id

UNION ALL

SELECT 
  'System Setup Verification',
  'Active Classrooms',
  COUNT(*)
FROM classrooms 
WHERE is_active = true

UNION ALL

SELECT 
  'System Setup Verification',
  'Classroom Pricing Plans',
  COUNT(*)
FROM classroom_pricing

UNION ALL

SELECT 
  'System Setup Verification',
  'Sample Enrollments',
  COUNT(*)
FROM student_classroom_assignments
WHERE student_id = 'mock-student-uuid-1234-5678-9012-345678901234'

ORDER BY check_type, table_name;
