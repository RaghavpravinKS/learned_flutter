CREATE OR REPLACE FUNCTION get_student_classrooms(p_student_id uuid)
RETURNS TABLE(classroom_id uuid) AS $$
BEGIN
  RETURN QUERY
  SELECT sca.classroom_id
  FROM public.student_classroom_assignments sca
  WHERE sca.student_id = p_student_id;
END; 
$$ LANGUAGE plpgsql;
