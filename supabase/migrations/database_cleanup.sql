-- Database Cleanup Script for LearnED Flutter App
-- This script will clean up and populate missing data in the database

-- 1. First, let's add some payment plans
INSERT INTO payment_plans (id, name, description, billing_cycle, features) VALUES
('plan-basic-monthly', 'Basic Monthly', 'Access to all classroom content and materials', 'month', '["Live classes", "Recorded sessions", "Study materials", "Assignment feedback"]'),
('plan-premium-monthly', 'Premium Monthly', 'All basic features plus 1-on-1 sessions', 'month', '["Live classes", "Recorded sessions", "Study materials", "Assignment feedback", "1-on-1 tutoring", "Priority support"]'),
('plan-basic-quarterly', 'Basic Quarterly', 'Access to all classroom content and materials - 3 months', 'quarter', '["Live classes", "Recorded sessions", "Study materials", "Assignment feedback"]')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  billing_cycle = EXCLUDED.billing_cycle,
  features = EXCLUDED.features;

-- 2. Add classroom pricing for existing classrooms
INSERT INTO classroom_pricing (id, classroom_id, payment_plan_id, price, is_active) VALUES
-- For Advanced Mathematics (75ac924c-a66e-4172-bfd5-3ec4b9757949)
('pricing-math-basic', '75ac924c-a66e-4172-bfd5-3ec4b9757949', 'plan-basic-monthly', 49.99, true),
('pricing-math-premium', '75ac924c-a66e-4172-bfd5-3ec4b9757949', 'plan-premium-monthly', 79.99, true),

-- For Introduction to Physics (011ce5c6-fa85-4b94-aa63-9c5ef43a95f3)
('pricing-physics-basic', '011ce5c6-fa85-4b94-aa63-9c5ef43a95f3', 'plan-basic-monthly', 54.99, true),
('pricing-physics-premium', '011ce5c6-fa85-4b94-aa63-9c5ef43a95f3', 'plan-premium-monthly', 84.99, true),

-- For World History (assuming the third classroom ID - we'll need to get the actual ID)
('pricing-history-basic', (SELECT id FROM classrooms WHERE name LIKE '%World History%' LIMIT 1), 'plan-basic-monthly', 39.99, true),
('pricing-history-premium', (SELECT id FROM classrooms WHERE name LIKE '%World History%' LIMIT 1), 'plan-premium-monthly', 69.99, true)
ON CONFLICT (id) DO UPDATE SET
  price = EXCLUDED.price,
  is_active = EXCLUDED.is_active;

-- 3. Update users table for teachers to have proper names
-- First, let's check if the teacher users exist, if not create them
INSERT INTO users (id, email, first_name, last_name, role, created_at, updated_at) VALUES
('a1b2c3d4-e5f6-7890-1234-567890abcdef', 'sarah.wilson@learneded.com', 'Sarah', 'Wilson', 'teacher', NOW(), NOW()),
('teacher-dc-002-user-id', 'david.chen@learneded.com', 'David', 'Chen', 'teacher', NOW(), NOW()),
('teacher-history-user-id', 'emily.johnson@learneded.com', 'Emily', 'Johnson', 'teacher', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email;

-- 4. Update teachers table to link to proper users
UPDATE teachers SET user_id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef' 
WHERE teacher_id = 'TCHR-SW-001';

-- Update the other teacher if we can find the record
UPDATE teachers SET user_id = 'teacher-dc-002-user-id' 
WHERE teacher_id = 'TCHR-DC-002';

-- 5. Let's also add a sample student user for testing enrollment
INSERT INTO users (id, email, first_name, last_name, role, created_at, updated_at) VALUES
('student-test-001', 'student.test@learneded.com', 'Test', 'Student', 'student', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name;

-- Add corresponding student record
INSERT INTO students (id, user_id, student_id, grade_level, school_name, created_at, updated_at) VALUES
('student-test-001-profile', 'student-test-001', 'STU-001', 10, 'Test High School', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  grade_level = EXCLUDED.grade_level,
  school_name = EXCLUDED.school_name;
