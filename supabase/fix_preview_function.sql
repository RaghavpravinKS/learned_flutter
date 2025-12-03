-- Fix preview_recurring_session_hours function to return integer for duration
-- This fixes the "invalid input syntax for type integer: '30 days'" error

CREATE OR REPLACE FUNCTION public.preview_recurring_session_hours(
  p_classroom_id varchar,
  p_start_time time,
  p_end_time time,
  p_recurrence_days integer[],
  p_start_date date,
  p_end_date date
)
RETURNS TABLE(
  minimum_required_hours numeric,
  calculated_monthly_hours numeric,
  is_valid boolean,
  sessions_per_week integer,
  hours_per_session numeric,
  total_duration_days integer
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_minimum_hours numeric;
  v_calculated_hours numeric;
  v_duration_days integer;
  v_hours_per_session numeric;
  v_sessions_per_week integer;
BEGIN
  -- Get minimum hours for classroom
  SELECT minimum_monthly_hours INTO v_minimum_hours
  FROM public.classrooms
  WHERE id = p_classroom_id;
  
  -- Calculate duration (extract days from interval to ensure integer result)
  v_duration_days := EXTRACT(DAY FROM (COALESCE(p_end_date, p_start_date + interval '3 months') - p_start_date));
  
  -- Calculate hours per session
  v_hours_per_session := EXTRACT(EPOCH FROM (p_end_time - p_start_time)) / 3600.0;
  
  -- Count sessions per week
  v_sessions_per_week := array_length(p_recurrence_days, 1);
  
  -- Calculate monthly hours
  v_calculated_hours := calculate_recurring_session_monthly_hours(
    p_start_time,
    p_end_time,
    p_recurrence_days,
    p_start_date,
    COALESCE(p_end_date, p_start_date + interval '3 months')
  );
  
  RETURN QUERY SELECT
    COALESCE(v_minimum_hours, 0),
    ROUND(v_calculated_hours, 2),
    v_calculated_hours >= COALESCE(v_minimum_hours, 0) AND v_duration_days >= 30,
    v_sessions_per_week,
    ROUND(v_hours_per_session, 2),
    v_duration_days;
END;
$$;

COMMENT ON FUNCTION public.preview_recurring_session_hours IS 'Preview calculated hours for recurring session validation before creation';
