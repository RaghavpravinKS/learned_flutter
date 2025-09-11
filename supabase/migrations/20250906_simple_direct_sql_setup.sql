-- Simplified schema enhancements for direct SQL operations
-- No stored procedures needed - just add missing fields

-- Add missing fields to existing tables for better enrollment tracking
ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS next_session_date TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.student_classroom_assignments 
ADD COLUMN IF NOT EXISTS enrolled_date TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.student_classroom_assignments 
ADD COLUMN IF NOT EXISTS progress DECIMAL(5,2) DEFAULT 0.0;

-- Create test data for demonstration
-- Step 1: Create test student user
INSERT INTO users (id, first_name, last_name, email, password_hash, user_type, phone, is_active, email_verified, created_at, updated_at) VALUES 
('12345678-1234-5678-9012-345678901234', 'Test', 'Student', 'test.student@example.com', 'mock_hash', 'student', '+1234567892', true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  updated_at = NOW();

-- Step 2: Create test student record
INSERT INTO students (id, user_id, student_id, grade_level, school_name, status, created_at, updated_at) VALUES 
('12345678-1234-5678-9012-345678901234', '12345678-1234-5678-9012-345678901234', 'STU-TEST-001', 10, 'Test High School', 'active', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  grade_level = EXCLUDED.grade_level,
  school_name = EXCLUDED.school_name,
  updated_at = NOW();

-- Step 3: Create teacher users if they don't exist
INSERT INTO users (id, first_name, last_name, email, password_hash, user_type, phone, is_active, email_verified, created_at, updated_at) VALUES 
('87654321-4321-8765-2109-876543210987', 'Dr. Sarah', 'Johnson', 'sarah.johnson@school.edu', 'mock_hash', 'teacher', '+1234567890', true, true, NOW(), NOW()),
('11111111-2222-3333-4444-555555555555', 'Prof. Michael', 'Chen', 'michael.chen@school.edu', 'mock_hash', 'teacher', '+1234567891', true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  updated_at = NOW();

-- Step 4: Create/update teacher records
INSERT INTO teachers (id, user_id, teacher_id, qualifications, experience_years, status, created_at, updated_at) VALUES 
('be59f28c-795b-468e-b219-c39fc22b2cf2', '87654321-4321-8765-2109-876543210987', 'TCH-SARAH-001', 'PhD in Mathematics, MIT', 8, 'active', NOW(), NOW()),
('d95d245e-721e-4489-ad9f-bf17823b0d4f', '11111111-2222-3333-4444-555555555555', 'TCH-MICHAEL-002', 'PhD in Physics, Stanford', 12, 'active', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  user_id = EXCLUDED.user_id,
  qualifications = EXCLUDED.qualifications,
  experience_years = EXCLUDED.experience_years,
  updated_at = NOW();

-- Step 5: Create sample classrooms
INSERT INTO classrooms (
  id, 
  name, 
  subject, 
  description, 
  grade_level, 
  board, 
  teacher_id, 
  max_students,
  next_session_date,
  is_active, 
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
  NOW() + INTERVAL '1 day',
  true,
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
  NOW() + INTERVAL '2 days',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  teacher_id = EXCLUDED.teacher_id,
  next_session_date = EXCLUDED.next_session_date,
  updated_at = NOW();

-- Step 6: Create a sample enrollment to test "My Classes" functionality
-- Create payment record first
INSERT INTO payments (
  id,
  student_id,
  amount,
  currency,
  payment_method,
  transaction_id,
  payment_status,
  created_at
) VALUES (
  '99999999-8888-7777-6666-555555555555',
  '12345678-1234-5678-9012-345678901234',
  79.99,
  'USD',
  'simulation',
  'sim_test_enrollment_payment',
  'completed',
  NOW() - INTERVAL '3 days'
) ON CONFLICT (id) DO NOTHING;

-- Create enrollment record
INSERT INTO student_classroom_assignments (
  id,
  student_id,
  classroom_id,
  teacher_id,
  enrolled_date,
  status,
  progress,
  created_at,
  updated_at
) VALUES (
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  '12345678-1234-5678-9012-345678901234',
  '75ac924c-a66e-4172-bfd5-3ec4b9757949',
  'be59f28c-795b-468e-b219-c39fc22b2cf2',
  NOW() - INTERVAL '3 days',
  'active',
  25.5,
  NOW() - INTERVAL '3 days',
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- Verification query
SELECT 
  'Setup Complete' as status,
  COUNT(*) as enrolled_count
FROM student_classroom_assignments sca
JOIN classrooms c ON sca.classroom_id = c.id
JOIN teachers t ON c.teacher_id = t.id
JOIN users u ON t.user_id = u.id
WHERE sca.student_id = '12345678-1234-5678-9012-345678901234'
AND sca.status = 'active';
