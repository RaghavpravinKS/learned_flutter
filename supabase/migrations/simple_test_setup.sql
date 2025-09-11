-- ========================================================================
-- SIMPLE TEST SETUP - NO AUTH ACCOUNTS NEEDED
-- ========================================================================
-- This creates teacher records with generated UUIDs for testing
-- No need to create auth accounts since teachers won't be logging in
-- ========================================================================

-- Step 1: Create Teacher Users in public.users (reference data only)
INSERT INTO public.users (
    id, email, password_hash, first_name, last_name, user_type, phone, is_active, email_verified, created_at, updated_at
) VALUES
    ('11111111-2222-3333-4444-555555555555', 'sarah.johnson@learned.com', 'mock_hash_teacher', 'Dr. Sarah', 'Johnson', 'teacher', '+1-555-0101', true, true, NOW(), NOW()),
    ('22222222-3333-4444-5555-666666666666', 'michael.chen@learned.com', 'mock_hash_teacher', 'Prof. Michael', 'Chen', 'teacher', '+1-555-0102', true, true, NOW(), NOW()),
    ('33333333-4444-5555-6666-777777777777', 'emily.rodriguez@learned.com', 'mock_hash_teacher', 'Dr. Emily', 'Rodriguez', 'teacher', '+1-555-0103', true, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- Step 2: Create Teacher Records (reference data only)
INSERT INTO public.teachers (
    id, user_id, teacher_id, qualifications, experience_years, specializations, status, created_at, updated_at
) VALUES
    ('11111111-2222-3333-4444-555555555555', '11111111-2222-3333-4444-555555555555', 'TCH-SARAH-001', 'PhD in Mathematics from MIT, 8+ years teaching experience', 8, ARRAY['Mathematics', 'Calculus', 'Algebra'], 'active', NOW(), NOW()),
    ('22222222-3333-4444-5555-666666666666', '22222222-3333-4444-5555-666666666666', 'TCH-MICHAEL-002', 'PhD in Physics from Stanford, 12+ years research and teaching', 12, ARRAY['Physics', 'Quantum Mechanics', 'Thermodynamics'], 'active', NOW(), NOW()),
    ('33333333-4444-5555-6666-777777777777', '33333333-4444-5555-6666-777777777777', 'TCH-EMILY-003', 'PhD in Chemistry from Harvard, Specialized in Organic Chemistry', 10, ARRAY['Chemistry', 'Organic Chemistry', 'Biochemistry'], 'active', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- Step 3: Create Payment Plans
INSERT INTO public.payment_plans (
    id, name, description, price_per_month, billing_cycle, features, is_active, created_at, updated_at
) VALUES
    ('aaaaaaaa-bbbb-cccc-dddd-111111111111', 'Basic Monthly', 'Access to one subject with unlimited sessions', 29.99, 'monthly', '{"features": ["1 Subject Access", "Unlimited Sessions", "Basic Support", "Mobile Access"]}', true, NOW(), NOW()),
    ('aaaaaaaa-bbbb-cccc-dddd-222222222222', 'Premium Monthly', 'Access to all subjects with priority support', 59.99, 'monthly', '{"features": ["All Subjects Access", "Unlimited Sessions", "Priority Support", "Mobile & Web Access", "Progress Analytics"]}', true, NOW(), NOW()),
    ('aaaaaaaa-bbbb-cccc-dddd-333333333333', 'Basic Annual', 'One subject access for full year with discount', 25.00, 'monthly', '{"features": ["1 Subject Access", "Unlimited Sessions", "Basic Support", "Mobile Access", "Annual Discount"]}', true, NOW(), NOW()),
    ('aaaaaaaa-bbbb-cccc-dddd-444444444444', 'Premium Annual', 'All subjects access for full year with maximum discount', 50.00, 'monthly', '{"features": ["All Subjects Access", "Unlimited Sessions", "Priority Support", "Mobile & Web Access", "Progress Analytics", "Maximum Annual Discount"]}', true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- Step 4: Create Classrooms
INSERT INTO public.classrooms (
    id, name, subject, description, grade_level, board, teacher_id, max_students, is_active, created_at, updated_at
) VALUES
    -- Mathematics Classrooms (Dr. Sarah Johnson)
    ('cccccccc-dddd-eeee-ffff-111111111111', 'Advanced Mathematics - Grade 12', 'Mathematics', 'Comprehensive coverage of advanced calculus, linear algebra, and preparation for engineering entrance exams', 12, 'CBSE', '11111111-2222-3333-4444-555555555555', 25, true, NOW(), NOW()),
    ('cccccccc-dddd-eeee-ffff-222222222222', 'Intermediate Mathematics - Grade 11', 'Mathematics', 'Solid foundation in algebra, trigonometry, and analytical geometry for grade 11 students', 11, 'CBSE', '11111111-2222-3333-4444-555555555555', 30, true, NOW(), NOW()),
    
    -- Physics Classrooms (Prof. Michael Chen)
    ('cccccccc-dddd-eeee-ffff-333333333333', 'Advanced Physics - Grade 12', 'Physics', 'In-depth study of mechanics, thermodynamics, and electromagnetic theory with practical applications', 12, 'CBSE', '22222222-3333-4444-5555-666666666666', 20, true, NOW(), NOW()),
    ('cccccccc-dddd-eeee-ffff-444444444444', 'Physics Fundamentals - Grade 11', 'Physics', 'Essential physics concepts including motion, forces, energy, and wave phenomena', 11, 'CBSE', '22222222-3333-4444-5555-666666666666', 25, true, NOW(), NOW()),
    
    -- Chemistry Classrooms (Dr. Emily Rodriguez)
    ('cccccccc-dddd-eeee-ffff-555555555555', 'Organic Chemistry Mastery - Grade 12', 'Chemistry', 'Complete organic chemistry with reaction mechanisms and synthesis for competitive exam preparation', 12, 'CBSE', '33333333-4444-5555-6666-777777777777', 20, true, NOW(), NOW()),
    ('cccccccc-dddd-eeee-ffff-666666666666', 'Chemistry Foundation - Grade 11', 'Chemistry', 'Strong foundation in atomic structure, chemical bonding, and basic organic chemistry', 11, 'CBSE', '33333333-4444-5555-6666-777777777777', 25, true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET updated_at = NOW();

-- Verification: Show what was created
SELECT 'SETUP COMPLETE!' as status;

SELECT 
    'Teachers Created' as type,
    COUNT(*) as count
FROM public.teachers 
WHERE status = 'active';

SELECT 
    'Classrooms Created' as type,
    COUNT(*) as count
FROM public.classrooms 
WHERE is_active = true;

SELECT 
    'Payment Plans Created' as type,
    COUNT(*) as count
FROM public.payment_plans 
WHERE is_active = true;

-- Show teacher-classroom relationships
SELECT 
    CONCAT(u.first_name, ' ', u.last_name) as teacher_name,
    COUNT(c.id) as classroom_count,
    STRING_AGG(c.name, ', ' ORDER BY c.name) as classrooms
FROM public.teachers t
JOIN public.users u ON t.user_id = u.id
LEFT JOIN public.classrooms c ON c.teacher_id = t.id AND c.is_active = true
WHERE t.status = 'active'
GROUP BY t.id, u.first_name, u.last_name
ORDER BY u.first_name;

SELECT 'Ready for student flow testing! No auth accounts needed for teachers.' as message;

-- ========================================================================
-- TESTING NOTES:
-- ========================================================================
-- ✅ 3 Teachers created (reference data only)
-- ✅ 6 Classrooms created (2 per teacher)  
-- ✅ 4 Payment plans created
-- ✅ All foreign key relationships established
-- 
-- Now test the student flow:
-- 1. Register new student account
-- 2. Complete student profile  
-- 3. Browse classrooms (should show teacher names correctly)
-- 4. Enroll in a classroom using payment bypass
-- 5. Check "My Classes" page (should show enrolled classroom with teacher name)
-- ========================================================================
