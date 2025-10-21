-- Test if RLS policies would match for this specific user
-- Simulate what the app query does

-- Set the user context (this simulates being logged in as the teacher)
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "d7be67fb-1a90-4184-b27c-d86357cc6648"}';

-- Now test the exact query the app makes for assignments
SELECT 
  'Testing assignments query:' as test,
  a.id,
  a.title,
  a.classroom_id,
  a.assignment_type
FROM public.assignments a
WHERE a.classroom_id = 'PHYSICS_11_CBSE'
AND a.is_published = true
AND a.due_date >= CURRENT_TIMESTAMP
ORDER BY a.due_date ASC
LIMIT 5;

-- Test the exact query the app makes for sessions
SELECT 
  'Testing sessions query:' as test,
  cs.id,
  cs.title,
  cs.classroom_id,
  cs.session_date
FROM public.class_sessions cs
WHERE cs.classroom_id = 'PHYSICS_11_CBSE'
AND cs.session_date >= CURRENT_DATE
AND cs.status != 'cancelled'
ORDER BY cs.session_date ASC, cs.start_time ASC
LIMIT 5;

-- Reset
RESET role;
