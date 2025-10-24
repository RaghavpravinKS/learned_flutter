-- Temporary simpler policy for testing
-- Run this in Supabase Dashboard -> Storage -> Policies -> New Policy

-- First, let's check what the policy is actually seeing
-- You can run this query in SQL Editor to debug:

SELECT 
  auth.uid() as current_user_id,
  t.id as teacher_id,
  t.user_id as teacher_user_id,
  c.id as classroom_id,
  c.teacher_id as classroom_teacher_id,
  c.name as classroom_name
FROM teachers t
INNER JOIN classrooms c ON c.teacher_id = t.id
WHERE t.user_id = auth.uid();

-- This will show if the relationships are set up correctly

-- Then, try this simplified INSERT policy:
-- Go to Storage -> Policies -> Click on "Teachers can upload learning materials"
-- Replace the policy definition with:

bucket_id = 'learning-materials' AND
(storage.foldername(name))[1] = 'classrooms' AND
EXISTS (
  SELECT 1 
  FROM public.teachers t
  INNER JOIN public.classrooms c ON c.teacher_id = t.id
  WHERE t.user_id = auth.uid()
  AND CAST(c.id AS TEXT) = (storage.foldername(name))[2]
)

-- Note: Changed c.id::text to CAST(c.id AS TEXT) for clarity
