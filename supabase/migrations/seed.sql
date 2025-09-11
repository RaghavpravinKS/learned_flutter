-- To execute this file, you can copy its contents into the Supabase SQL Editor
-- and run it. Make sure to execute this only once to avoid duplicate data errors.

-- Clear existing data to ensure a clean slate (optional, use with caution)
-- DELETE FROM public.classroom_pricing;
-- DELETE FROM public.classrooms;
-- DELETE FROM public.payment_plans;
-- DELETE FROM public.teachers;
-- DELETE FROM public.students;
-- DELETE FROM public.users;

-- 1. Create Users
-- For simplicity, using placeholder password hashes. In a real scenario, these would be securely generated.
DO $$
DECLARE
    teacher_user_id UUID := gen_random_uuid();
    student_user_id UUID := gen_random_uuid();
    teacher_profile_id UUID;
    student_profile_id UUID;
    plan_id UUID;
    classroom_id UUID;
BEGIN
    -- Create a teacher user
    INSERT INTO public.users (id, email, password_hash, user_type, first_name, last_name)
    VALUES (teacher_user_id, 'teacher@test.com', 'password123', 'teacher', 'John', 'Doe');

    -- Create a student user
    INSERT INTO public.users (id, email, password_hash, user_type, first_name, last_name)
    VALUES (student_user_id, 'student@test.com', 'password123', 'student', 'Jane', 'Smith');

    -- 2. Create Teacher and Student Profiles
    INSERT INTO public.teachers (user_id, teacher_id, qualifications, experience_years, specializations)
    VALUES (teacher_user_id, 'TID-001', 'M.Sc. Physics', 5, ARRAY['Physics', 'Mathematics'])
    RETURNING id INTO teacher_profile_id;

    INSERT INTO public.students (user_id, student_id, grade_level, board)
    VALUES (student_user_id, 'SID-001', 10, 'CBSE')
    RETURNING id INTO student_profile_id;

    -- 3. Create a Payment Plan
    INSERT INTO public.payment_plans (name, description, price_per_month, billing_cycle)
    VALUES ('Standard Monthly', 'Access to all standard features.', 99.99, 'monthly')
    RETURNING id INTO plan_id;

    -- 4. Create a Classroom
    INSERT INTO public.classrooms (teacher_id, name, subject, board, grade_level, max_students)
    VALUES (teacher_profile_id, 'Advanced Physics - Grade 10', 'Physics', 'CBSE', 10, 25)
    RETURNING id INTO classroom_id;

    -- 5. Link Classroom to Payment Plan
    INSERT INTO public.classroom_pricing (classroom_id, payment_plan_id, price)
    VALUES (classroom_id, plan_id, 99.99);

END $$;
