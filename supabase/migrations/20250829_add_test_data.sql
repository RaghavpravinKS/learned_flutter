-- Add Test Users (Teachers and Students)
INSERT INTO public.users (id, email, password_hash, user_type, first_name, last_name, phone, profile_image_url, is_active, email_verified)
VALUES
    ('a1b2c3d4-e5f6-7890-1234-567890abcdef', 'teacher.sarah@example.com', 'hashed_password_1', 'teacher', 'Sarah', 'Williams', '123-456-7890', 'https://i.pravatar.cc/150?u=sarahwilliams', true, true),
    ('b2c3d4e5-f6a7-8901-2345-67890abcdef0', 'teacher.david@example.com', 'hashed_password_2', 'teacher', 'David', 'Chen', '234-567-8901', 'https://i.pravatar.cc/150?u=davidchen', true, true),
    ('c3d4e5f6-a7b8-9012-3456-7890abcdef01', 'student.emily@example.com', 'hashed_password_3', 'student', 'Emily', 'Jones', '345-678-9012', 'https://i.pravatar.cc/150?u=emilyjones', true, true),
    ('d4e5f6a7-b8c9-0123-4567-890abcdef012', 'student.mike@example.com', 'hashed_password_4', 'student', 'Mike', 'Brown', '456-789-0123', 'https://i.pravatar.cc/150?u=mikebrown', true, true);

-- Add Teacher Profiles
INSERT INTO public.teachers (id, user_id, teacher_id, qualifications, experience_years, specializations, bio, is_verified)
VALUES
    (gen_random_uuid(), 'a1b2c3d4-e5f6-7890-1234-567890abcdef', 'TCHR-SW-001', 'M.Sc. in Mathematics, B.Ed', 10, ARRAY['Calculus', 'Algebra'], 'Passionate about making math accessible and fun for all students.', true),
    (gen_random_uuid(), 'b2c3d4e5-f6a7-8901-2345-67890abcdef0', 'TCHR-DC-002', 'Ph.D. in Physics', 8, ARRAY['Quantum Mechanics', 'Astrophysics'], 'Exploring the wonders of the universe, one equation at a time.', true);

-- Add Student Profiles
INSERT INTO public.students (id, user_id, student_id, grade_level, school_name, board)
VALUES
    (gen_random_uuid(), 'c3d4e5f6-a7b8-9012-3456-7890abcdef01', 'STU-EJ-001', 10, 'Maplewood High', 'CBSE'),
    (gen_random_uuid(), 'd4e5f6a7-b8c9-0123-4567-890abcdef012', 'STU-MB-002', 12, 'Oakridge International', 'IB');

-- Add Classrooms and Sessions
DO $$
DECLARE
    teacher_sarah_user_id uuid := 'a1b2c3d4-e5f6-7890-1234-567890abcdef';
    teacher_david_user_id uuid := 'b2c3d4e5-f6a7-8901-2345-67890abcdef0';
    teacher_sarah_id uuid;
    teacher_david_id uuid;
    math_classroom_id uuid;
    physics_classroom_id uuid;
    history_classroom_id uuid;
BEGIN
    -- Get teacher PKs from user_ids
    SELECT id INTO teacher_sarah_id FROM public.teachers WHERE user_id = teacher_sarah_user_id;
    SELECT id INTO teacher_david_id FROM public.teachers WHERE user_id = teacher_david_user_id;

    -- Insert Classrooms one by one and capture their IDs
    INSERT INTO public.classrooms (teacher_id, name, subject, grade_level, board, description, max_students)
    VALUES (teacher_sarah_id, 'Advanced Mathematics', 'Mathematics', 10, 'CBSE', 'Covers advanced topics in algebra, calculus, and trigonometry.', 20)
    RETURNING id INTO math_classroom_id;

    INSERT INTO public.classrooms (teacher_id, name, subject, grade_level, board, description, max_students)
    VALUES (teacher_david_id, 'Introduction to Physics', 'Physics', 11, 'ICSE', 'A beginner-friendly introduction to the core concepts of physics.', 25)
    RETURNING id INTO physics_classroom_id;

    INSERT INTO public.classrooms (teacher_id, name, subject, grade_level, board, description, max_students)
    VALUES (teacher_sarah_id, 'World History: Ancient Civilizations', 'History', 9, 'State Board', 'Explore the rise and fall of ancient empires.', 30)
    RETURNING id INTO history_classroom_id;

    -- Add Sessions for Advanced Mathematics
    INSERT INTO public.class_sessions (classroom_id, teacher_id, title, scheduled_start, scheduled_end)
    VALUES
        (math_classroom_id, teacher_sarah_id, 'Algebra Fundamentals', NOW() + INTERVAL '2 days 10:00', NOW() + INTERVAL '2 days 11:30'),
        (math_classroom_id, teacher_sarah_id, 'Calculus Basics', NOW() + INTERVAL '4 days 10:00', NOW() + INTERVAL '4 days 11:30');

    -- Add Sessions for Introduction to Physics
    INSERT INTO public.class_sessions (classroom_id, teacher_id, title, scheduled_start, scheduled_end)
    VALUES
        (physics_classroom_id, teacher_david_id, 'Newton''s Laws of Motion', NOW() + INTERVAL '3 days 14:00', NOW() + INTERVAL '3 days 15:30'),
        (physics_classroom_id, teacher_david_id, 'Thermodynamics Explained', NOW() + INTERVAL '5 days 14:00', NOW() + INTERVAL '5 days 15:30');

    -- Add Sessions for World History
    INSERT INTO public.class_sessions (classroom_id, teacher_id, title, scheduled_start, scheduled_end)
    VALUES
        (history_classroom_id, teacher_sarah_id, 'Ancient Egypt', NOW() + INTERVAL '1 day 09:00', NOW() + INTERVAL '1 day 10:00'),
        (history_classroom_id, teacher_sarah_id, 'The Roman Empire', NOW() + INTERVAL '8 days 09:00', NOW() + INTERVAL '8 days 10:00');
END $$;

-- Enroll Emily Jones in Advanced Mathematics
DO $$
DECLARE
    student_emily_user_id uuid := 'c3d4e5f6-a7b8-9012-3456-7890abcdef01';
    student_emily_id uuid;
    math_classroom_id uuid;
BEGIN
    SELECT id INTO student_emily_id FROM public.students WHERE user_id = student_emily_user_id;
    SELECT id INTO math_classroom_id FROM public.classrooms WHERE name = 'Advanced Mathematics';

    INSERT INTO public.student_classroom_assignments (student_id, classroom_id)
    VALUES (student_emily_id, math_classroom_id);
END $$;
