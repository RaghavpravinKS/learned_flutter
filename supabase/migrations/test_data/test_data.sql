-- Test Data for LearnED Platform

-- Clear existing data (be careful with this in production!)
-- TRUNCATE TABLE users CASCADE;

-- Test Users
-- Password for all test users: Test@123
-- Use Supabase Auth UI or API to create these users first, then update the IDs below

-- Test Student
INSERT INTO users (id, email, password_hash, user_type, first_name, last_name, phone, is_active, email_verified)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'student@test.com',
  '$2a$10$FB/BOAVhpuLvpOREQVmvmezD4ED/.JBIDRh70tGevYzYzQgFId2u.', -- Hashed for 'Test@123'
  'student',
  'Alex',
  'Johnson',
  '+1234567890',
  true,
  true
);

-- Test Teacher
INSERT INTO users (id, email, password_hash, user_type, first_name, last_name, phone, is_active, email_verified)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  'teacher@test.com',
  '$2a$10$FB/BOAVhpuLvpOREQVmvmezD4ED/.JBIDRh70tGevYzYzQgFId2u.',
  'teacher',
  'Sarah',
  'Williams',
  '+1987654321',
  true,
  true
);

-- Student Profile
INSERT INTO students (id, user_id, student_id, grade_level, school_name, board, status)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  '11111111-1111-1111-1111-111111111111',
  'STU001',
  10,
  'Metro High School',
  'CBSE',
  'active'
);

-- Teacher Profile
INSERT INTO teachers (id, user_id, teacher_id, qualifications, experience_years, specializations, is_verified)
VALUES (
  '44444444-4444-4444-4444-444444444444',
  '22222222-2222-2222-2222-222222222222',
  'TCH001',
  'M.Sc. in Mathematics, B.Ed',
  8,
  ARRAY['Mathematics', 'Physics'],
  true
);

-- Classrooms
INSERT INTO classrooms (id, teacher_id, name, subject, board, grade_level, description, max_students, is_active)
VALUES 
  ('55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', 'Advanced Mathematics', 'Mathematics', 'CBSE', 10, 'Advanced mathematics for grade 10 students', 20, true),
  ('66666666-6666-6666-6666-666666666666', '44444444-4444-4444-4444-444444444444', 'Physics Fundamentals', 'Physics', 'CBSE', 10, 'Basic physics concepts', 15, true);

-- Student Classroom Assignment
INSERT INTO student_classroom_assignments (id, student_id, classroom_id, teacher_id, status)
VALUES (
  '77777777-7777-7777-7777-777777777777',
  '33333333-3333-3333-3333-333333333333',
  '55555555-5555-5555-5555-555555555555',
  '44444444-4444-4444-4444-444444444444',
  'active'
);

-- Class Sessions (Next 7 days)
INSERT INTO class_sessions (id, classroom_id, teacher_id, title, description, scheduled_start, scheduled_end, session_status)
VALUES 
  ('88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', 'Algebra Basics', 'Introduction to algebraic expressions', 
   (NOW() + INTERVAL '1 day 10:00:00'), (NOW() + INTERVAL '1 day 11:30:00'), 'scheduled'),
  
  ('99999999-9999-9999-9999-999999999999', '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', 'Quadratic Equations', 'Solving quadratic equations', 
   (NOW() + INTERVAL '3 days 10:00:00'), (NOW() + INTERVAL '3 days 11:30:00'), 'scheduled'),
  
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '66666666-6666-6666-6666-666666666666', '44444444-4444-4444-4444-444444444444', 'Motion in One Dimension', 'Basic concepts of motion', 
   (NOW() + INTERVAL '2 days 14:00:00'), (NOW() + INTERVAL '2 days 15:30:00'), 'scheduled');

-- Assignments
INSERT INTO assignments (id, classroom_id, teacher_id, title, description, assignment_type, total_points, due_date, is_published)
VALUES 
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', 'Algebra Assignment 1', 'Practice problems on algebraic expressions', 'assignment', 20, (NOW() + INTERVAL '5 days'), true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', 'Mid-term Test', 'Mid-term examination', 'test', 50, (NOW() + INTERVAL '14 days'), true);

-- Learning Materials
INSERT INTO learning_materials (id, teacher_id, classroom_id, title, description, material_type, file_url, is_public)
VALUES 
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', 'Algebra Basics PDF', 'Introduction to algebra concepts', 'document', 'https://example.com/materials/algebra_basics.pdf', true),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', 'Quadratic Equations Video', 'Video tutorial on solving quadratics', 'video', 'https://example.com/videos/quadratics.mp4', true);

-- Student Material Access
INSERT INTO student_material_access (id, student_id, material_id, download_count, last_accessed)
VALUES 
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '33333333-3333-3333-3333-333333333333', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 2, NOW()),
  ('11111111-1111-1111-1111-111111111112', '33333333-3333-3333-3333-333333333333', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 1, NOW() - INTERVAL '2 days');

-- Payment Plans (example)
INSERT INTO payment_plans (id, name, description, price, duration_days, is_active)
VALUES 
  ('22222222-2222-2222-2222-222222222223', 'Monthly Plan', '1 month access to all courses', 29.99, 30, true),
  ('22222222-2222-2222-2222-222222222224', 'Quarterly Plan', '3 months access with 10% discount', 80.97, 90, true);

-- Student Subscription
INSERT INTO student_subscriptions (id, student_id, payment_plan_id, start_date, end_date, status, payment_status, amount_paid)
VALUES (
  '33333333-3333-3333-3333-333333333334',
  '33333333-3333-3333-3333-333333333333',
  '22222222-2222-2222-2222-222222222223',
  CURRENT_DATE,
  (CURRENT_DATE + INTERVAL '30 days'),
  'active',
  'paid',
  29.99
);

-- Transaction
INSERT INTO transactions (id, user_id, amount, currency, payment_method, status, description)
VALUES (
  '44444444-4444-4444-4444-444444444445',
  '11111111-1111-1111-1111-111111111111',
  29.99,
  'USD',
  'credit_card',
  'succeeded',
  'Monthly subscription payment'
);

-- Link subscription to transaction
INSERT INTO subscription_payments (subscription_id, transaction_id, payment_date)
VALUES (
  '33333333-3333-3333-3333-333333333334',
  '44444444-4444-4444-4444-444444444445',
  CURRENT_DATE
);

-- Add some sample attendance
INSERT INTO session_attendance (session_id, student_id, attendance_status, join_time, leave_time, duration_minutes, participation_score)
VALUES 
  ('88888888-8888-8888-8888-888888888888', '33333333-3333-3333-3333-333333333333', 'present', 
   (NOW() + INTERVAL '1 day 10:00:00'), (NOW() + INTERVAL '1 day 11:30:00'), 90, 8),
  
  ('99999999-9999-9999-9999-999999999999', '33333333-3333-3333-3333-333333333333', 'scheduled', NULL, NULL, NULL, NULL);
