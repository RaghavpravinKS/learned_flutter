-- Create test assignment to verify RLS policies work
-- Run this in Supabase SQL Editor

-- First, get the teacher_id for the classroom
DO $$
DECLARE
  v_teacher_id uuid;
BEGIN
  -- Get the teacher_id from the Physics classroom
  SELECT teacher_id INTO v_teacher_id
  FROM public.classrooms
  WHERE id = 'PHYSICS_11_CBSE';

  -- Insert a test assignment
  INSERT INTO public.assignments (
    id,
    classroom_id,
    teacher_id,
    title,
    description,
    assignment_type,
    total_points,
    due_date,
    is_published,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'PHYSICS_11_CBSE',
    v_teacher_id,
    'Test Assignment - Newton''s Laws',
    'Complete problems 1-10 from chapter 5',
    'assignment',
    100,
    (CURRENT_DATE + INTERVAL '7 days')::timestamp,
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  );

  -- Insert a test class session
  INSERT INTO public.class_sessions (
    id,
    classroom_id,
    title,
    description,
    session_date,
    start_time,
    end_time,
    status,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    'PHYSICS_11_CBSE',
    'Introduction to Mechanics',
    'First session covering basic concepts',
    (CURRENT_DATE + INTERVAL '2 days')::date,
    '10:00:00'::time,
    '11:30:00'::time,
    'scheduled',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
  );

  RAISE NOTICE 'Test data created successfully!';
END $$;

-- Verify they were created
SELECT 
  id, 
  title, 
  classroom_id, 
  due_date,
  is_published
FROM public.assignments
WHERE classroom_id = 'PHYSICS_11_CBSE';

SELECT 
  id,
  title,
  classroom_id,
  session_date,
  start_time,
  status
FROM public.class_sessions
WHERE classroom_id = 'PHYSICS_11_CBSE';
