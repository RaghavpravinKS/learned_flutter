-- =============================================
-- FIX ASSIGNMENTS TABLE - ADD STATUS COLUMN AND FUNCTION
-- =============================================

-- Add status column to assignments table
ALTER TABLE public.assignments 
ADD COLUMN IF NOT EXISTS status character varying DEFAULT 'draft' 
CHECK (status::text = ANY (ARRAY[
  'draft'::character varying,
  'active'::character varying,
  'completed'::character varying,
  'archived'::character varying
]::text[]));

-- Update existing records: set status based on is_published
UPDATE public.assignments 
SET status = CASE 
  WHEN is_published = true THEN 'active'
  ELSE 'draft'
END
WHERE status IS NULL;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_assignments_status ON public.assignments(status);

-- =============================================
-- CREATE get_teacher_assignments FUNCTION
-- =============================================

-- Drop all existing versions of the function
DROP FUNCTION IF EXISTS get_teacher_assignments(uuid);
DROP FUNCTION IF EXISTS get_teacher_assignments(uuid, uuid);

CREATE OR REPLACE FUNCTION get_teacher_assignments(p_teacher_id uuid)
RETURNS TABLE (
  id uuid,
  classroom_id character varying,
  teacher_id uuid,
  title character varying,
  description text,
  assignment_type character varying,
  total_points integer,
  time_limit_minutes integer,
  due_date timestamp with time zone,
  is_published boolean,
  status character varying,
  instructions text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  classroom_name character varying,
  submission_count bigint,
  graded_count bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.classroom_id,
    a.teacher_id,
    a.title,
    a.description,
    a.assignment_type,
    a.total_points,
    a.time_limit_minutes,
    a.due_date,
    a.is_published,
    a.status,
    a.instructions,
    a.created_at,
    a.updated_at,
    c.name as classroom_name,
    COUNT(DISTINCT saa.id)::bigint as submission_count,
    COUNT(DISTINCT CASE WHEN saa.graded_at IS NOT NULL THEN saa.id END)::bigint as graded_count
  FROM public.assignments a
  JOIN public.classrooms c ON a.classroom_id = c.id
  LEFT JOIN public.student_assignment_attempts saa ON a.id = saa.assignment_id
  WHERE a.teacher_id = p_teacher_id
  GROUP BY a.id, a.classroom_id, a.teacher_id, a.title, a.description, 
           a.assignment_type, a.total_points, a.time_limit_minutes, a.due_date,
           a.is_published, a.status, a.instructions, a.created_at, a.updated_at, c.name
  ORDER BY a.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_teacher_assignments(uuid) TO authenticated;

-- =============================================
-- VERIFICATION
-- =============================================

-- Check if status column was added
SELECT 
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
    AND table_name = 'assignments'
    AND column_name = 'status';

-- Check if function exists
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
    AND routine_name = 'get_teacher_assignments';

SELECT '✅ Assignments table fixed with status column and get_teacher_assignments function created!' as status;
