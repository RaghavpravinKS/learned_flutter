-- Check if the subquery in RLS policy actually returns the classroom
-- This simulates what RLS does

SELECT 
  'Classrooms this teacher can access via RLS policy:' as info,
  c.id as classroom_id,
  c.name,
  c.teacher_id,
  t.user_id
FROM public.classrooms c
INNER JOIN public.teachers t ON t.id = c.teacher_id
WHERE t.user_id = 'd7be67fb-1a90-4184-b27c-d86357cc6648';

-- Now check if assignments would match this classroom
SELECT 
  'Assignments in accessible classrooms:' as info,
  a.id,
  a.title,
  a.classroom_id,
  CASE 
    WHEN a.classroom_id IN (
      SELECT c.id 
      FROM public.classrooms c
      INNER JOIN public.teachers t ON t.id = c.teacher_id
      WHERE t.user_id = 'd7be67fb-1a90-4184-b27c-d86357cc6648'
    ) THEN 'WOULD PASS RLS'
    ELSE 'WOULD FAIL RLS'
  END as rls_check
FROM public.assignments a
WHERE a.classroom_id = 'PHYSICS_11_CBSE';

-- Check sessions
SELECT 
  'Sessions in accessible classrooms:' as info,
  cs.id,
  cs.title,
  cs.classroom_id,
  CASE 
    WHEN cs.classroom_id IN (
      SELECT c.id 
      FROM public.classrooms c
      INNER JOIN public.teachers t ON t.id = c.teacher_id
      WHERE t.user_id = 'd7be67fb-1a90-4184-b27c-d86357cc6648'
    ) THEN 'WOULD PASS RLS'
    ELSE 'WOULD FAIL RLS'
  END as rls_check
FROM public.class_sessions cs
WHERE cs.classroom_id = 'PHYSICS_11_CBSE';
