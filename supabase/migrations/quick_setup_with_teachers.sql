-- ========================================================================
-- QUICK SETUP WITH GENERATED TEACHER IDS (For Immediate Testing)
-- ========================================================================
-- This creates placeholder teacher records that you can test with
-- You'll need to create matching auth accounts manually
-- ========================================================================

-- Generate consistent UUIDs for teachers (for testing purposes)
DO $$
DECLARE
    teacher_sarah_id UUID := '11111111-2222-3333-4444-555555555555';
    teacher_michael_id UUID := '22222222-3333-4444-5555-666666666666';
    teacher_emily_id UUID := '33333333-4444-5555-6666-777777777777';
BEGIN

-- Step 1: Create Teacher Users in public.users
INSERT INTO public.users (
    id, email, first_name, last_name, user_type, phone, is_active, email_verified, created_at, updated_at
) VALUES
    (teacher_sarah_id, 'sarah.johnson@learned.com', 'Dr. Sarah', 'Johnson', 'teacher', '+1-555-0101', true, true, NOW(), NOW()),
    (teacher_michael_id, 'michael.chen@learned.com', 'Prof. Michael', 'Chen', 'teacher', '+1-555-0102', true, true, NOW(), NOW()),
    (teacher_emily_id, 'emily.rodriguez@learned.com', 'Dr. Emily', 'Rodriguez', 'teacher', '+1-555-0103', true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- Step 2: Create Teacher Records
INSERT INTO public.teachers (
    id, user_id, teacher_id, qualifications, experience_years, subject_specialization, status, created_at, updated_at
) VALUES
    (teacher_sarah_id, teacher_sarah_id, 'TCH-SARAH-001', 'PhD in Mathematics from MIT, 8+ years teaching experience', 8, 'Mathematics, Calculus, Algebra', 'active', NOW(), NOW()),
    (teacher_michael_id, teacher_michael_id, 'TCH-MICHAEL-002', 'PhD in Physics from Stanford, 12+ years research and teaching', 12, 'Physics, Quantum Mechanics, Thermodynamics', 'active', NOW(), NOW()),
    (teacher_emily_id, teacher_emily_id, 'TCH-EMILY-003', 'PhD in Chemistry from Harvard, Specialized in Organic Chemistry', 10, 'Chemistry, Organic Chemistry, Biochemistry', 'active', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- Step 3: Create Payment Plans
INSERT INTO public.payment_plans (
    id, name, description, price, currency, duration_months, features, is_active, created_at, updated_at
) VALUES
    ('plan-basic-monthly', 'Basic Monthly', 'Access to one subject with unlimited sessions', 29.99, 'USD', 1, '{"features": ["1 Subject Access", "Unlimited Sessions", "Basic Support", "Mobile Access"]}', true, NOW(), NOW()),
    ('plan-premium-monthly', 'Premium Monthly', 'Access to all subjects with priority support', 59.99, 'USD', 1, '{"features": ["All Subjects Access", "Unlimited Sessions", "Priority Support", "Mobile & Web Access", "Progress Analytics"]}', true, NOW(), NOW()),
    ('plan-basic-annual', 'Basic Annual', 'One subject access for full year with discount', 299.99, 'USD', 12, '{"features": ["1 Subject Access", "Unlimited Sessions", "Basic Support", "Mobile Access", "Annual Discount"]}', true, NOW(), NOW()),
    ('plan-premium-annual', 'Premium Annual', 'All subjects access for full year with maximum discount', 599.99, 'USD', 12, '{"features": ["All Subjects Access", "Unlimited Sessions", "Priority Support", "Mobile & Web Access", "Progress Analytics", "Maximum Annual Discount"]}', true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- Step 4: Create Classrooms
INSERT INTO public.classrooms (
    id, name, subject, description, grade_level, board, teacher_id, max_students, price_per_month, currency, next_session_date, session_duration_minutes, sessions_per_week, is_active, created_at, updated_at
) VALUES
    -- Mathematics Classrooms (Dr. Sarah Johnson)
    ('classroom-math-advanced', 'Advanced Mathematics - Grade 12', 'Mathematics', 'Comprehensive coverage of advanced calculus, linear algebra, and preparation for engineering entrance exams', 12, 'CBSE', teacher_sarah_id, 25, 79.99, 'USD', NOW() + INTERVAL '1 day', 90, 3, true, NOW(), NOW()),
    ('classroom-math-intermediate', 'Intermediate Mathematics - Grade 11', 'Mathematics', 'Solid foundation in algebra, trigonometry, and analytical geometry for grade 11 students', 11, 'CBSE', teacher_sarah_id, 30, 69.99, 'USD', NOW() + INTERVAL '2 days', 90, 3, true, NOW(), NOW()),
    
    -- Physics Classrooms (Prof. Michael Chen)
    ('classroom-physics-advanced', 'Advanced Physics - Grade 12', 'Physics', 'In-depth study of mechanics, thermodynamics, and electromagnetic theory with practical applications', 12, 'CBSE', teacher_michael_id, 20, 84.99, 'USD', NOW() + INTERVAL '1 day', 90, 3, true, NOW(), NOW()),
    ('classroom-physics-fundamentals', 'Physics Fundamentals - Grade 11', 'Physics', 'Essential physics concepts including motion, forces, energy, and wave phenomena', 11, 'CBSE', teacher_michael_id, 25, 74.99, 'USD', NOW() + INTERVAL '3 days', 90, 3, true, NOW(), NOW()),
    
    -- Chemistry Classrooms (Dr. Emily Rodriguez)
    ('classroom-chemistry-organic', 'Organic Chemistry Mastery - Grade 12', 'Chemistry', 'Complete organic chemistry with reaction mechanisms and synthesis for competitive exam preparation', 12, 'CBSE', teacher_emily_id, 20, 89.99, 'USD', NOW() + INTERVAL '2 days', 90, 3, true, NOW(), NOW()),
    ('classroom-chemistry-foundation', 'Chemistry Foundation - Grade 11', 'Chemistry', 'Strong foundation in atomic structure, chemical bonding, and basic organic chemistry', 11, 'CBSE', teacher_emily_id, 25, 74.99, 'USD', NOW() + INTERVAL '4 days', 90, 3, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

END $$;

-- Verification Queries
SELECT 'Setup Summary' as info, 'Teachers Created' as category, COUNT(*) as count FROM public.teachers WHERE status = 'active'
UNION ALL
SELECT 'Setup Summary', 'Payment Plans Created', COUNT(*) FROM public.payment_plans WHERE is_active = true  
UNION ALL
SELECT 'Setup Summary', 'Classrooms Created', COUNT(*) FROM public.classrooms WHERE is_active = true
ORDER BY category;

-- Show created data
SELECT 
    'Teacher Details' as type,
    CONCAT(u.first_name, ' ', u.last_name) as name,
    u.email,
    t.subject_specialization,
    (SELECT COUNT(*) FROM public.classrooms WHERE teacher_id = t.id) as classroom_count
FROM public.teachers t
JOIN public.users u ON t.user_id = u.id
WHERE t.status = 'active'
ORDER BY u.first_name;

SELECT 'Quick setup completed! Now create matching auth accounts for teachers.' as final_step;

-- ========================================================================
-- IMPORTANT: CREATE AUTH ACCOUNTS FOR THESE TEACHERS
-- ========================================================================
-- You now need to create auth accounts with these exact IDs:
-- 
-- 1. sarah.johnson@learned.com (ID: 11111111-2222-3333-4444-555555555555)
-- 2. michael.chen@learned.com (ID: 22222222-3333-4444-5555-666666666666)  
-- 3. emily.rodriguez@learned.com (ID: 33333333-4444-5555-6666-777777777777)
--
-- Use Supabase Dashboard > Authentication > Users > Add User
-- Or use the AdminUserService from your Flutter app
-- ========================================================================
