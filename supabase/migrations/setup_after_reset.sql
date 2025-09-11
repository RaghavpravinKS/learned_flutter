-- ========================================================================
-- POST-RESET DATABASE SETUP SCRIPT
-- ========================================================================
-- Run this AFTER resetting the database to populate essential data
-- This creates teachers, classrooms, and payment plans for testing
-- ========================================================================

-- Step 1: Create Teacher Users (auth + public.users + teachers table)
-- Note: You'll need to create these users via Supabase Auth first, then run this script

-- Create teacher user records in public.users (manually insert auth user IDs after creating them)
-- Replace these UUIDs with actual IDs from auth.users after creating teacher accounts

-- Teacher 1: Dr. Sarah Johnson (Mathematics)
INSERT INTO public.users (
    id, 
    email, 
    first_name, 
    last_name, 
    user_type, 
    phone, 
    is_active, 
    email_verified, 
    created_at, 
    updated_at
) VALUES (
    'teacher-1-replace-with-auth-id',  -- Replace with actual auth.users.id
    'sarah.johnson@learned.com',
    'Dr. Sarah',
    'Johnson',
    'teacher',
    '+1-555-0101',
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();

-- Create teacher record for Sarah
INSERT INTO public.teachers (
    id,
    user_id,
    teacher_id,
    qualifications,
    experience_years,
    subject_specialization,
    status,
    created_at,
    updated_at
) VALUES (
    'teacher-1-replace-with-auth-id',  -- Same as user_id
    'teacher-1-replace-with-auth-id',
    'TCH-SARAH-001',
    'PhD in Mathematics from MIT, 8+ years teaching experience',
    8,
    'Mathematics, Calculus, Algebra',
    'active',
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();

-- Teacher 2: Prof. Michael Chen (Physics)
INSERT INTO public.users (
    id, 
    email, 
    first_name, 
    last_name, 
    user_type, 
    phone, 
    is_active, 
    email_verified, 
    created_at, 
    updated_at
) VALUES (
    'teacher-2-replace-with-auth-id',  -- Replace with actual auth.users.id
    'michael.chen@learned.com',
    'Prof. Michael',
    'Chen',
    'teacher',
    '+1-555-0102',
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();

INSERT INTO public.teachers (
    id,
    user_id,
    teacher_id,
    qualifications,
    experience_years,
    subject_specialization,
    status,
    created_at,
    updated_at
) VALUES (
    'teacher-2-replace-with-auth-id',
    'teacher-2-replace-with-auth-id',
    'TCH-MICHAEL-002',
    'PhD in Physics from Stanford, 12+ years research and teaching',
    12,
    'Physics, Quantum Mechanics, Thermodynamics',
    'active',
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();

-- Teacher 3: Dr. Emily Rodriguez (Chemistry)
INSERT INTO public.users (
    id, 
    email, 
    first_name, 
    last_name, 
    user_type, 
    phone, 
    is_active, 
    email_verified, 
    created_at, 
    updated_at
) VALUES (
    'teacher-3-replace-with-auth-id',
    'emily.rodriguez@learned.com',
    'Dr. Emily',
    'Rodriguez',
    'teacher',
    '+1-555-0103',
    true,
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();

INSERT INTO public.teachers (
    id,
    user_id,
    teacher_id,
    qualifications,
    experience_years,
    subject_specialization,
    status,
    created_at,
    updated_at
) VALUES (
    'teacher-3-replace-with-auth-id',
    'teacher-3-replace-with-auth-id',
    'TCH-EMILY-003',
    'PhD in Chemistry from Harvard, Specialized in Organic Chemistry',
    10,
    'Chemistry, Organic Chemistry, Biochemistry',
    'active',
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();

-- Step 2: Create Payment Plans
INSERT INTO public.payment_plans (
    id,
    name,
    description,
    price,
    currency,
    duration_months,
    features,
    is_active,
    created_at,
    updated_at
) VALUES
(
    'plan-basic-monthly',
    'Basic Monthly',
    'Access to one subject with unlimited sessions',
    29.99,
    'USD',
    1,
    '{"features": ["1 Subject Access", "Unlimited Sessions", "Basic Support", "Mobile Access"]}',
    true,
    NOW(),
    NOW()
),
(
    'plan-premium-monthly',
    'Premium Monthly',
    'Access to all subjects with priority support',
    59.99,
    'USD',
    1,
    '{"features": ["All Subjects Access", "Unlimited Sessions", "Priority Support", "Mobile & Web Access", "Progress Analytics"]}',
    true,
    NOW(),
    NOW()
),
(
    'plan-basic-annual',
    'Basic Annual',
    'One subject access for full year with discount',
    299.99,
    'USD',
    12,
    '{"features": ["1 Subject Access", "Unlimited Sessions", "Basic Support", "Mobile Access", "Annual Discount"]}',
    true,
    NOW(),
    NOW()
),
(
    'plan-premium-annual',
    'Premium Annual',
    'All subjects access for full year with maximum discount',
    599.99,
    'USD',
    12,
    '{"features": ["All Subjects Access", "Unlimited Sessions", "Priority Support", "Mobile & Web Access", "Progress Analytics", "Maximum Annual Discount"]}',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();

-- Step 3: Create Classrooms
INSERT INTO public.classrooms (
    id,
    name,
    subject,
    description,
    grade_level,
    board,
    teacher_id,
    max_students,
    price_per_month,
    currency,
    next_session_date,
    session_duration_minutes,
    sessions_per_week,
    is_active,
    created_at,
    updated_at
) VALUES
-- Mathematics Classrooms
(
    'classroom-math-advanced',
    'Advanced Mathematics - Grade 12',
    'Mathematics',
    'Comprehensive coverage of advanced calculus, linear algebra, and preparation for engineering entrance exams',
    12,
    'CBSE',
    'teacher-1-replace-with-auth-id',  -- Dr. Sarah Johnson
    25,
    79.99,
    'USD',
    NOW() + INTERVAL '1 day',
    90,
    3,
    true,
    NOW(),
    NOW()
),
(
    'classroom-math-intermediate',
    'Intermediate Mathematics - Grade 11',
    'Mathematics',
    'Solid foundation in algebra, trigonometry, and analytical geometry for grade 11 students',
    11,
    'CBSE',
    'teacher-1-replace-with-auth-id',  -- Dr. Sarah Johnson
    30,
    69.99,
    'USD',
    NOW() + INTERVAL '2 days',
    90,
    3,
    true,
    NOW(),
    NOW()
),

-- Physics Classrooms
(
    'classroom-physics-advanced',
    'Advanced Physics - Grade 12',
    'Physics',
    'In-depth study of mechanics, thermodynamics, and electromagnetic theory with practical applications',
    12,
    'CBSE',
    'teacher-2-replace-with-auth-id',  -- Prof. Michael Chen
    20,
    84.99,
    'USD',
    NOW() + INTERVAL '1 day',
    90,
    3,
    true,
    NOW(),
    NOW()
),
(
    'classroom-physics-fundamentals',
    'Physics Fundamentals - Grade 11',
    'Physics',
    'Essential physics concepts including motion, forces, energy, and wave phenomena',
    11,
    'CBSE',
    'teacher-2-replace-with-auth-id',  -- Prof. Michael Chen
    25,
    74.99,
    'USD',
    NOW() + INTERVAL '3 days',
    90,
    3,
    true,
    NOW(),
    NOW()
),

-- Chemistry Classrooms
(
    'classroom-chemistry-organic',
    'Organic Chemistry Mastery - Grade 12',
    'Chemistry',
    'Complete organic chemistry with reaction mechanisms and synthesis for competitive exam preparation',
    12,
    'CBSE',
    'teacher-3-replace-with-auth-id',  -- Dr. Emily Rodriguez
    20,
    89.99,
    'USD',
    NOW() + INTERVAL '2 days',
    90,
    3,
    true,
    NOW(),
    NOW()
),
(
    'classroom-chemistry-foundation',
    'Chemistry Foundation - Grade 11',
    'Chemistry',
    'Strong foundation in atomic structure, chemical bonding, and basic organic chemistry',
    11,
    'CBSE',
    'teacher-3-replace-with-auth-id',  -- Dr. Emily Rodriguez
    25,
    74.99,
    'USD',
    NOW() + INTERVAL '4 days',
    90,
    3,
    true,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();

-- Step 4: Verification Query
SELECT 
    'Setup Verification' as status,
    'Teachers' as table_name,
    COUNT(*) as records_created
FROM public.teachers
WHERE status = 'active'

UNION ALL

SELECT 
    'Setup Verification',
    'Payment Plans',
    COUNT(*)
FROM public.payment_plans
WHERE is_active = true

UNION ALL

SELECT 
    'Setup Verification',
    'Classrooms',
    COUNT(*)
FROM public.classrooms
WHERE is_active = true

ORDER BY table_name;

-- Step 5: Show created data summary
SELECT 
    'Created Teachers' as summary,
    CONCAT(u.first_name, ' ', u.last_name) as teacher_name,
    t.subject_specialization,
    u.email
FROM public.teachers t
JOIN public.users u ON t.user_id = u.id
WHERE t.status = 'active'

UNION ALL

SELECT 
    'Created Classrooms',
    c.name,
    c.subject,
    CONCAT('$', c.price_per_month, '/month')
FROM public.classrooms c
WHERE c.is_active = true

ORDER BY summary, teacher_name;

SELECT 'Database setup completed! Remember to replace teacher IDs with actual auth user IDs.' as final_note;
