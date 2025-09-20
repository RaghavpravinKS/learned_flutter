-- =============================================
-- MOCK DATA FOR TESTING
-- This script creates sample teachers, classrooms, payment plans, and pricing
-- =============================================

-- First, create an admin user to use for creating teachers
-- Delete existing admin if exists to avoid conflicts
DELETE FROM public.users WHERE email = 'admin@learned.com' AND user_type = 'admin';

INSERT INTO public.users (
    id, email, user_type, first_name, last_name, 
    is_active, email_verified, created_at, updated_at
) VALUES (
    gen_random_uuid(), 'admin@learned.com', 'admin', 'System', 'Admin',
    true, true, now(), now()
);

-- Get the admin user ID for creating teachers
DO $$
DECLARE
    admin_user_id uuid;
    teacher_result jsonb;
BEGIN
    -- Get admin user ID
    SELECT id INTO admin_user_id FROM public.users WHERE email = 'admin@learned.com' AND user_type = 'admin';
    
    -- Create teachers using the admin function
    SELECT public.create_teacher_by_admin(
        admin_user_id,
        'john.math@learned.com',
        'John',
        'Smith',
        '+1234567890',
        'M.Sc. Mathematics, B.Ed.',
        'Experienced mathematics teacher with 8 years of teaching experience. Specializes in algebra and calculus.',
        8,
        'Mathematics, Algebra, Calculus',
        '{"hire_date": "2023-01-15"}'::jsonb
    ) INTO teacher_result;
    
    SELECT public.create_teacher_by_admin(
        admin_user_id,
        'sarah.science@learned.com',
        'Sarah',
        'Johnson',
        '+1234567891',
        'M.Sc. Physics, B.Ed.',
        'Physics teacher passionate about making science accessible to students. Expert in practical demonstrations.',
        6,
        'Physics, Chemistry, General Science',
        '{"hire_date": "2023-03-01"}'::jsonb
    ) INTO teacher_result;
    
    SELECT public.create_teacher_by_admin(
        admin_user_id,
        'mike.english@learned.com',
        'Michael',
        'Brown',
        '+1234567892',
        'M.A. English Literature, B.Ed.',
        'English literature teacher with focus on creative writing and reading comprehension.',
        5,
        'English, Literature, Creative Writing',
        '{"hire_date": "2023-02-10"}'::jsonb
    ) INTO teacher_result;
    
    SELECT public.create_teacher_by_admin(
        admin_user_id,
        'priya.hindi@learned.com',
        'Priya',
        'Sharma',
        '+1234567893',
        'M.A. Hindi Literature, B.Ed.',
        'Hindi teacher specializing in grammar and literature. 7 years of experience.',
        7,
        'Hindi, Sanskrit, Indian Literature',
        '{"hire_date": "2022-08-15"}'::jsonb
    ) INTO teacher_result;
END $$;

-- Create payment plans (delete existing first to avoid conflicts)
DELETE FROM public.payment_plans WHERE id IN ('monthly_basic', 'quarterly_standard', 'yearly_premium');

INSERT INTO public.payment_plans (id, name, description, billing_cycle, features, is_active) VALUES 
('monthly_basic', 'Monthly Basic', 'Basic monthly subscription with full access to classes', 'monthly', 
 ARRAY['Live classes', 'Recorded sessions', 'Basic assignments', 'Email support'], true),
('quarterly_standard', 'Quarterly Standard', 'Quarterly subscription with additional benefits', 'quarterly', 
 ARRAY['Live classes', 'Recorded sessions', 'Advanced assignments', 'Priority support', 'Progress reports'], true),
('yearly_premium', 'Yearly Premium', 'Annual subscription with premium features', 'yearly', 
 ARRAY['Live classes', 'Recorded sessions', 'All assignments', '24/7 support', 'Detailed analytics', 'One-on-one sessions'], true);

-- Create classrooms (delete existing first to avoid conflicts)
DELETE FROM public.classrooms WHERE id IN ('MATH_10_CBSE', 'MATH_9_CBSE', 'PHYSICS_11_CBSE', 'PHYSICS_12_CBSE', 'ENGLISH_10_CBSE', 'HINDI_9_CBSE', 'MATH_10_ICSE');

INSERT INTO public.classrooms (id, name, description, subject, grade_level, board, max_students, teacher_id) VALUES 
('MATH_10_CBSE', 'Mathematics Grade 10 CBSE', 'Comprehensive mathematics course covering algebra, geometry, and trigonometry for CBSE Grade 10 students', 'Mathematics', 10, 'CBSE', 30, 
 (SELECT t.id FROM public.teachers t JOIN public.users u ON t.user_id = u.id WHERE u.email = 'john.math@learned.com')),
('MATH_9_CBSE', 'Mathematics Grade 9 CBSE', 'Foundation mathematics course for CBSE Grade 9 students', 'Mathematics', 9, 'CBSE', 25, 
 (SELECT t.id FROM public.teachers t JOIN public.users u ON t.user_id = u.id WHERE u.email = 'john.math@learned.com')),
('PHYSICS_11_CBSE', 'Physics Grade 11 CBSE', 'Introduction to physics concepts for Grade 11 students', 'Physics', 11, 'CBSE', 28, 
 (SELECT t.id FROM public.teachers t JOIN public.users u ON t.user_id = u.id WHERE u.email = 'sarah.science@learned.com')),
('PHYSICS_12_CBSE', 'Physics Grade 12 CBSE', 'Advanced physics preparation for board exams', 'Physics', 12, 'CBSE', 30, 
 (SELECT t.id FROM public.teachers t JOIN public.users u ON t.user_id = u.id WHERE u.email = 'sarah.science@learned.com')),
('ENGLISH_10_CBSE', 'English Grade 10 CBSE', 'English language and literature for CBSE Grade 10', 'English', 10, 'CBSE', 35, 
 (SELECT t.id FROM public.teachers t JOIN public.users u ON t.user_id = u.id WHERE u.email = 'mike.english@learned.com')),
('HINDI_9_CBSE', 'Hindi Grade 9 CBSE', 'Hindi language and literature for Grade 9 students', 'Hindi', 9, 'CBSE', 30, 
 (SELECT t.id FROM public.teachers t JOIN public.users u ON t.user_id = u.id WHERE u.email = 'priya.hindi@learned.com')),
('MATH_10_ICSE', 'Mathematics Grade 10 ICSE', 'Mathematics course tailored for ICSE Grade 10 curriculum', 'Mathematics', 10, 'ICSE', 25, 
 (SELECT t.id FROM public.teachers t JOIN public.users u ON t.user_id = u.id WHERE u.email = 'john.math@learned.com'));

-- Create classroom pricing (link classrooms with payment plans)
-- Delete existing pricing first to avoid conflicts
DELETE FROM public.classroom_pricing WHERE classroom_id IN ('MATH_10_CBSE', 'MATH_9_CBSE', 'PHYSICS_11_CBSE', 'PHYSICS_12_CBSE', 'ENGLISH_10_CBSE', 'HINDI_9_CBSE', 'MATH_10_ICSE');

INSERT INTO public.classroom_pricing (classroom_id, payment_plan_id, price) VALUES 
-- Mathematics Grade 10 CBSE
('MATH_10_CBSE', 'monthly_basic', 1200.00),
('MATH_10_CBSE', 'quarterly_standard', 3200.00),
('MATH_10_CBSE', 'yearly_premium', 12000.00),

-- Mathematics Grade 9 CBSE
('MATH_9_CBSE', 'monthly_basic', 1000.00),
('MATH_9_CBSE', 'quarterly_standard', 2800.00),
('MATH_9_CBSE', 'yearly_premium', 10500.00),

-- Physics Grade 11 CBSE
('PHYSICS_11_CBSE', 'monthly_basic', 1300.00),
('PHYSICS_11_CBSE', 'quarterly_standard', 3500.00),
('PHYSICS_11_CBSE', 'yearly_premium', 13000.00),

-- Physics Grade 12 CBSE
('PHYSICS_12_CBSE', 'monthly_basic', 1500.00),
('PHYSICS_12_CBSE', 'quarterly_standard', 4000.00),
('PHYSICS_12_CBSE', 'yearly_premium', 15000.00),

-- English Grade 10 CBSE
('ENGLISH_10_CBSE', 'monthly_basic', 1100.00),
('ENGLISH_10_CBSE', 'quarterly_standard', 3000.00),
('ENGLISH_10_CBSE', 'yearly_premium', 11000.00),

-- Hindi Grade 9 CBSE
('HINDI_9_CBSE', 'monthly_basic', 900.00),
('HINDI_9_CBSE', 'quarterly_standard', 2500.00),
('HINDI_9_CBSE', 'yearly_premium', 9500.00),

-- Mathematics Grade 10 ICSE
('MATH_10_ICSE', 'monthly_basic', 1250.00),
('MATH_10_ICSE', 'quarterly_standard', 3300.00),
('MATH_10_ICSE', 'yearly_premium', 12500.00);

SELECT 'Mock data created successfully! You now have:' as message;
SELECT 'Teachers: ' || count(*) FROM public.teachers;
SELECT 'Classrooms: ' || count(*) FROM public.classrooms;
SELECT 'Payment Plans: ' || count(*) FROM public.payment_plans;
SELECT 'Classroom Pricing: ' || count(*) FROM public.classroom_pricing;