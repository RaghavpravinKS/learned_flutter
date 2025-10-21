-- Combined query to check teacher record status
-- This will show all results in one output

WITH app_user AS (
  SELECT 'd7be67fb-1a90-4184-b27c-d86357cc6648'::uuid as user_id
),
teacher_check AS (
  SELECT 
    t.id as teacher_id,
    t.user_id,
    u.email,
    u.first_name,
    u.last_name,
    'FOUND' as status
  FROM teachers t
  JOIN users u ON u.id = t.user_id
  WHERE t.user_id = (SELECT user_id FROM app_user)
)
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM teacher_check) THEN '✓ Teacher record EXISTS'
    ELSE '✗ NO teacher record found'
  END as result,
  (SELECT user_id::text FROM app_user) as app_user_id,
  (SELECT teacher_id::text FROM teacher_check) as teacher_id,
  (SELECT email FROM teacher_check) as email,
  (SELECT first_name || ' ' || last_name FROM teacher_check) as name;

-- Also show ALL teachers in database for comparison
SELECT 
  '=== ALL TEACHERS IN DATABASE ===' as info,
  t.id as teacher_id,
  t.user_id,
  u.email,
  u.first_name || ' ' || u.last_name as name
FROM teachers t
JOIN users u ON u.id = t.user_id;
