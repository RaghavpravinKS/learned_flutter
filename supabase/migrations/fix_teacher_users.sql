-- Fix teacher user data by creating/updating user records for existing teachers
-- Based on current teachers table data

-- Create/update user records for the existing teachers
INSERT INTO users (id, first_name, last_name, email, user_type, phone, is_active, email_verified, created_at, updated_at) VALUES 
-- Teacher 1: be59f28c-795b-468e-b219-c39fc22b2cf2 with user_id a1b2c3d4-e5f6-7890-1234-567890abcdef
('a1b2c3d4-e5f6-7890-1234-567890abcdef', 'Dr. Sarah', 'Johnson', 'sarah.johnson@school.edu', 'teacher', '+1234567890', true, true, NOW(), NOW()),
-- Teacher 2: d95d245e-721e-4489-ad9f-bf17823b0d4f with user_id dc002000-e29b-41d4-a716-446655440000  
('dc002000-e29b-41d4-a716-446655440000', 'Prof. Michael', 'Chen', 'michael.chen@school.edu', 'teacher', '+1234567891', true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  updated_at = NOW();

-- Create a separate mock student user for testing enrollments
INSERT INTO users (id, first_name, last_name, email, user_type, phone, is_active, email_verified, created_at, updated_at) VALUES 
('mock-student-uuid-1234-5678-9012-345678901234', 'Test', 'Student', 'test.student@example.com', 'student', '+1234567892', true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email,
  updated_at = NOW();

-- Create the corresponding student record
INSERT INTO students (id, user_id, student_id, grade_level, school_name, status, created_at, updated_at) VALUES 
('mock-student-uuid-1234-5678-9012-345678901234', 'mock-student-uuid-1234-5678-9012-345678901234', 'STU-TEST-001', 10, 'Test High School', 'active', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  grade_level = EXCLUDED.grade_level,
  school_name = EXCLUDED.school_name,
  updated_at = NOW();

-- Verify the teacher user data was created/updated
SELECT 
  'Teacher-User Mapping' as type,
  t.id as teacher_id,
  t.teacher_id as teacher_code,
  u.first_name,
  u.last_name,
  u.email,
  t.qualifications,
  t.experience_years
FROM teachers t
LEFT JOIN users u ON t.user_id = u.id
ORDER BY t.created_at;
