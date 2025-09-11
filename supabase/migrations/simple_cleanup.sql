-- Database Cleanup for LearnED Flutter App (CORRECTED SCHEMA)
-- Execute these statements one by one in Supabase SQL Editor

-- Step 1: Create payment plans (using correct schema with UUIDs)
INSERT INTO payment_plans (id, name, description, billing_cycle, price_per_month, features, is_active) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Basic Monthly', 'Access to all classroom content and materials', 'monthly', 49.99, '["Live classes", "Recorded sessions", "Study materials", "Assignment feedback"]'::jsonb, true),
('550e8400-e29b-41d4-a716-446655440002', 'Premium Monthly', 'All basic features plus 1-on-1 sessions', 'monthly', 79.99, '["Live classes", "Recorded sessions", "Study materials", "Assignment feedback", "1-on-1 tutoring", "Priority support"]'::jsonb, true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  price_per_month = EXCLUDED.price_per_month,
  features = EXCLUDED.features,
  is_active = EXCLUDED.is_active;

-- Step 2: Add classroom pricing for the 3 existing classrooms (using correct UUIDs)
INSERT INTO classroom_pricing (id, classroom_id, payment_plan_id, price) VALUES
-- Advanced Mathematics: 75ac924c-a66e-4172-bfd5-3ec4b9757949
('650e8400-e29b-41d4-a716-446655440001', '75ac924c-a66e-4172-bfd5-3ec4b9757949', '550e8400-e29b-41d4-a716-446655440001', 49.99),
('650e8400-e29b-41d4-a716-446655440002', '75ac924c-a66e-4172-bfd5-3ec4b9757949', '550e8400-e29b-41d4-a716-446655440002', 79.99),

-- Introduction to Physics: 011ce5c6-fa85-4b94-aa63-9c5ef43a95f3  
('650e8400-e29b-41d4-a716-446655440003', '011ce5c6-fa85-4b94-aa63-9c5ef43a95f3', '550e8400-e29b-41d4-a716-446655440001', 54.99),
('650e8400-e29b-41d4-a716-446655440004', '011ce5c6-fa85-4b94-aa63-9c5ef43a95f3', '550e8400-e29b-41d4-a716-446655440002', 84.99)
ON CONFLICT (id) DO UPDATE SET
  price = EXCLUDED.price;

-- Step 3: Fix teacher user records (using correct schema with user_type)
UPDATE users SET
  first_name = 'Sarah',
  last_name = 'Wilson',
  email = 'sarah.wilson@learneded.com'
WHERE id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';

-- Step 4: Create additional teacher user for the second teacher (TCHR-DC-002)
INSERT INTO users (id, email, password_hash, user_type, first_name, last_name, created_at, updated_at) VALUES
('dc002000-e29b-41d4-a716-446655440000', 'david.chen@learneded.com', 'placeholder_hash', 'teacher', 'David', 'Chen', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  first_name = 'David',
  last_name = 'Chen',
  email = 'david.chen@learneded.com',
  user_type = 'teacher';

-- Step 5: Update teachers table to link to proper users
UPDATE teachers SET user_id = 'dc002000-e29b-41d4-a716-446655440000' 
WHERE teacher_id = 'TCHR-DC-002';

-- Step 6: Add pricing for the third classroom (World History)
-- First find the classroom ID
INSERT INTO classroom_pricing (id, classroom_id, payment_plan_id, price) VALUES
('650e8400-e29b-41d4-a716-446655440005', (SELECT id FROM classrooms WHERE name LIKE '%World History%' LIMIT 1), '550e8400-e29b-41d4-a716-446655440001', 39.99),
('650e8400-e29b-41d4-a716-446655440006', (SELECT id FROM classrooms WHERE name LIKE '%World History%' LIMIT 1), '550e8400-e29b-41d4-a716-446655440002', 69.99)
ON CONFLICT (id) DO UPDATE SET
  price = EXCLUDED.price;

-- Step 7: Verify the cleanup worked
SELECT 
  c.name as classroom_name,
  c.subject,
  cp.price,
  pp.name as plan_name,
  pp.billing_cycle,
  t.teacher_id,
  u.first_name,
  u.last_name
FROM classrooms c
LEFT JOIN classroom_pricing cp ON c.id = cp.classroom_id
LEFT JOIN payment_plans pp ON cp.payment_plan_id = pp.id
LEFT JOIN teachers t ON c.teacher_id = t.id
LEFT JOIN users u ON t.user_id = u.id
WHERE c.is_active = true
ORDER BY c.name, cp.price;
