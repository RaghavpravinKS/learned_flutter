-- Test Data Population Script
-- Run this after your schema is set up

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Clear existing test data (be careful with this in production!)
TRUNCATE TABLE student_subscriptions, payments, student_assignment_attempts, assignment_questions, 
assignments, student_material_access, learning_materials, session_attendance, class_sessions, 
student_classroom_assignments, classroom_pricing, enrollment_requests, classrooms, 
teacher_availability, teachers, parent_student_relations, students, user_profiles, users 
RESTART IDENTITY CASCADE;

-- Create test users with different roles
DO $$
DECLARE
    student1_id UUID;
    student2_id UUID;
    teacher1_id UUID;
    teacher2_id UUID;
    parent1_id UUID;
    admin1_id UUID;
    
    -- Classroom and related IDs
    classroom1_id UUID;
    classroom2_id UUID;
    assignment1_id UUID;
    material1_id UUID;
    session1_id UUID;
    
    -- Payment related
    payment_plan1_id UUID;
    subscription1_id UUID;
BEGIN
    -- Create test users
    INSERT INTO users (email, password_hash, user_type, first_name, last_name, phone, is_active)
    VALUES 
        ('student1@test.com', crypt('password123', gen_salt('bf')), 'student', 'John', 'Student', '+1234567890', true)
    RETURNING id INTO student1_id;
    
    INSERT INTO users (email, password_hash, user_type, first_name, last_name, phone, is_active)
    VALUES 
        ('student2@test.com', crypt('password123', gen_salt('bf')), 'student', 'Jane', 'Doe', '+1234567891', true)
    RETURNING id INTO student2_id;
    
    INSERT INTO users (email, password_hash, user_type, first_name, last_name, phone, is_active)
    VALUES 
        ('teacher1@test.com', crypt('password123', gen_salt('bf')), 'teacher', 'Robert', 'Teacher', '+1234567892', true)
    RETURNING id INTO teacher1_id;
    
    INSERT INTO users (email, password_hash, user_type, first_name, last_name, phone, is_active)
    VALUES 
        ('teacher2@test.com', crypt('password123', gen_salt('bf')), 'teacher', 'Sarah', 'Professor', '+1234567893', true)
    RETURNING id INTO teacher2_id;
    
    INSERT INTO users (email, password_hash, user_type, first_name, last_name, phone, is_active)
    VALUES 
        ('parent1@test.com', crypt('password123', gen_salt('bf')), 'parent', 'Michael', 'Parent', '+1234567894', true)
    RETURNING id INTO parent1_id;
    
    INSERT INTO users (email, password_hash, user_type, first_name, last_name, phone, is_active)
    VALUES 
        ('admin@test.com', crypt('password123', gen_salt('bf')), 'admin', 'Admin', 'User', '+1234567899', true)
    RETURNING id INTO admin1_id;
    
    -- Create user profiles
    INSERT INTO user_profiles (user_id, date_of_birth, address, city, state, country, postal_code)
    VALUES 
        (student1_id, '2005-03-15', '123 Student St', 'Bangalore', 'Karnataka', 'India', '560001'),
        (student2_id, '2006-05-20', '456 College Ave', 'Mumbai', 'Maharashtra', 'India', '400001'),
        (teacher1_id, '1980-08-10', '789 Teacher Lane', 'Delhi', 'Delhi', 'India', '110001'),
        (parent1_id, '1980-12-25', '123 Parent Rd', 'Chennai', 'Tamil Nadu', 'India', '600001');
    
    -- Create students
    INSERT INTO students (user_id, student_id, grade_level, school_name, learning_goals, board, status)
    VALUES 
        (student1_id, 'STD' || substr(student1_id::text, 1, 8), 10, 'National Public School', 'Improve in Mathematics and Science', 'CBSE', 'active'),
        (student2_id, 'STD' || substr(student2_id::text, 1, 8), 9, 'Delhi Public School', 'Excel in all subjects', 'ICSE', 'active');
    
    -- Create teachers
    INSERT INTO teachers (user_id, teacher_id, qualifications, experience_years, specializations, is_verified, status)
    VALUES 
        (teacher1_id, 'TCH' || substr(teacher1_id::text, 1, 8), 'M.Sc in Mathematics, B.Ed', 8, '{"Mathematics", "Physics"}', true, 'active'),
        (teacher2_id, 'TCH' || substr(teacher2_id::text, 1, 8), 'M.A in English, B.Ed', 5, '{"English", "Literature"}', true, 'active');
    
    -- Create parent-student relationship
    INSERT INTO parent_student_relations (parent_id, student_id, relationship, is_primary_contact)
    SELECT parent1_id, id, 'Father', true FROM students WHERE user_id = student1_id;
    
    -- Create teacher availability
    INSERT INTO teacher_availability (teacher_id, day_of_week, start_time, end_time, is_available)
    VALUES 
        (teacher1_id, 1, '09:00:00', '17:00:00', true), -- Monday
        (teacher1_id, 2, '09:00:00', '17:00:00', true), -- Tuesday
        (teacher1_id, 3, '09:00:00', '17:00:00', true), -- Wednesday
        (teacher2_id, 1, '10:00:00', '18:00:00', true), -- Monday
        (teacher2_id, 3, '10:00:00', '18:00:00', true), -- Wednesday
        (teacher2_id, 5, '10:00:00', '18:00:00', true); -- Friday
    
    -- Create payment plan
    INSERT INTO payment_plans (name, description, price_per_hour, price_per_month, billing_cycle, is_active)
    VALUES ('Standard Plan', 'Monthly subscription with 8 classes per month', 500, 4000, 'monthly', true)
    RETURNING id INTO payment_plan1_id;
    
    -- Create classrooms
    INSERT INTO classrooms (teacher_id, name, subject, board, grade_level, description, max_students, is_active)
    VALUES 
        (teacher1_id, 'Grade 10 Mathematics', 'Mathematics', 'CBSE', 10, 'Comprehensive mathematics course for grade 10 students', 20, true)
    RETURNING id INTO classroom1_id;
    
    INSERT INTO classrooms (teacher_id, name, subject, board, grade_level, description, max_students, is_active)
    VALUES 
        (teacher2_id, 'Grade 9 English', 'English', 'ICSE', 9, 'English language and literature', 15, true)
    RETURNING id INTO classroom2_id;
    
    -- Set classroom pricing
    INSERT INTO classroom_pricing (classroom_id, payment_plan_id, price)
    VALUES 
        (classroom1_id, payment_plan1_id, 4000),
        (classroom2_id, payment_plan1_id, 4000);
    
    -- Enroll students in classrooms
    INSERT INTO student_classroom_assignments (student_id, classroom_id, teacher_id, status)
    SELECT student1_id, classroom1_id, teacher1_id, 'active' FROM students WHERE user_id = student1_id;
    
    -- Create a class session
    INSERT INTO class_sessions (classroom_id, teacher_id, title, description, scheduled_start, scheduled_end, session_status)
    VALUES 
        (classroom1_id, teacher1_id, 'Introduction to Algebra', 'Basic concepts of algebra', 
         NOW() + interval '1 day', NOW() + interval '1 day 1 hour', 'scheduled')
    RETURNING id INTO session1_id;
    
    -- Create attendance
    INSERT INTO session_attendance (session_id, student_id, attendance_status)
    SELECT session1_id, student1_id, 'present' FROM students WHERE user_id = student1_id;
    
    -- Create learning material
    INSERT INTO learning_materials (teacher_id, classroom_id, title, description, material_type, file_url, is_public, tags)
    VALUES 
        (teacher1_id, classroom1_id, 'Algebra Basics', 'Introduction to algebraic expressions', 'note', 'https://example.com/algebra-basics.pdf', true, '{"mathematics", "algebra"}')
    RETURNING id INTO material1_id;
    
    -- Track material access
    INSERT INTO student_material_access (student_id, material_id, download_count)
    SELECT student1_id, material1_id, 1 FROM students WHERE user_id = student1_id;
    
    -- Create an assignment
    INSERT INTO assignments (classroom_id, teacher_id, title, description, assignment_type, total_points, due_date, is_published)
    VALUES 
        (classroom1_id, teacher1_id, 'Algebra Quiz 1', 'Basic algebra concepts', 'quiz', 10, NOW() + interval '7 days', true)
    RETURNING id INTO assignment1_id;
    
    -- Add questions to assignment
    INSERT INTO assignment_questions (assignment_id, question_text, question_type, options, correct_answer, points, order_index)
    VALUES 
        (assignment1_id, 'What is 2x + 3 = 7?', 'short_answer', NULL, 'x = 2', 5, 1),
        (assignment1_id, 'Simplify: 3(x + 4)', 'short_answer', NULL, '3x + 12', 5, 2);
    
    -- Create a subscription for student
    INSERT INTO student_subscriptions (student_id, payment_plan_id, start_date, end_date, status, auto_renew)
    SELECT student1_id, payment_plan1_id, NOW(), NOW() + interval '1 month', 'active', true
    FROM students WHERE user_id = student1_id
    RETURNING id INTO subscription1_id;
    
    -- Record a payment
    INSERT INTO payments (student_id, subscription_id, amount, payment_status, payment_method)
    SELECT student1_id, subscription1_id, 4000, 'completed', 'credit_card'
    FROM students WHERE user_id = student1_id;
    
    -- Record student progress
    INSERT INTO student_progress (student_id, classroom_id, week_start_date, classes_attended, total_hours, average_score, assignments_completed)
    SELECT 
        student1_id, 
        classroom1_id, 
        DATE_TRUNC('week', NOW())::date, 
        2, 
        2.0, 
        85.5, 
        1
    FROM students WHERE user_id = student1_id;
    
    -- Create a notification
    INSERT INTO system_notifications (user_id, title, message, notification_type, is_read)
    VALUES 
        (student1_id, 'New Assignment', 'A new assignment has been posted in Mathematics class', 'assignment_due', false),
        (teacher1_id, 'Class Reminder', 'You have a class scheduled in 1 hour', 'class_reminder', false);
    
    RAISE NOTICE 'Test data population completed successfully';
    RAISE NOTICE 'Student login: student1@test.com / password123';
    RAISE NOTICE 'Teacher login: teacher1@test.com / password123';
    RAISE NOTICE 'Admin login: admin@test.com / password123';
END $$;
