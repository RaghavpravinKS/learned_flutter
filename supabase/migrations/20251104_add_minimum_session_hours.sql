-- ============================================================================
-- ADD MINIMUM SESSION HOURS VALIDATION
-- ============================================================================
-- Description: Add minimum monthly hours requirement for classrooms
-- Date: November 4, 2025
-- Version: 1.0
-- ============================================================================

-- ============================================================================
-- STEP 1: ADD COLUMN TO CLASSROOMS TABLE
-- ============================================================================

-- Add minimum_monthly_hours column to classrooms
ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS minimum_monthly_hours numeric DEFAULT 0 CHECK (minimum_monthly_hours >= 0);

COMMENT ON COLUMN public.classrooms.minimum_monthly_hours IS 'Minimum number of hours required per month for this classroom';

-- Update existing classrooms with a default value (can be updated by teachers/admins)
UPDATE public.classrooms 
SET minimum_monthly_hours = 12 
WHERE minimum_monthly_hours IS NULL OR minimum_monthly_hours = 0;

-- ============================================================================
-- STEP 2: CREATE VALIDATION FUNCTION
-- ============================================================================

-- Function to calculate total hours from recurring session pattern
CREATE OR REPLACE FUNCTION public.calculate_recurring_session_monthly_hours(
  p_start_time time,
  p_end_time time,
  p_recurrence_days integer[],
  p_start_date date,
  p_end_date date
)
RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
  v_hours_per_session numeric;
  v_sessions_per_week integer;
  v_total_weeks numeric;
  v_total_hours numeric;
  v_duration_days integer;
BEGIN
  -- Calculate hours per session
  v_hours_per_session := EXTRACT(EPOCH FROM (p_end_time - p_start_time)) / 3600.0;
  
  -- Count number of sessions per week (number of days selected)
  v_sessions_per_week := array_length(p_recurrence_days, 1);
  
  -- Calculate duration in days
  v_duration_days := p_end_date - p_start_date;
  
  -- If duration is less than 30 days, return 0 (will be validated separately)
  IF v_duration_days < 30 THEN
    RETURN 0;
  END IF;
  
  -- Calculate total weeks (approximation: duration / 7)
  v_total_weeks := v_duration_days / 7.0;
  
  -- Calculate total hours
  v_total_hours := v_hours_per_session * v_sessions_per_week * v_total_weeks;
  
  -- Calculate monthly average (30 days per month)
  RETURN (v_total_hours * 30.0) / v_duration_days;
END;
$$;

COMMENT ON FUNCTION public.calculate_recurring_session_monthly_hours IS 'Calculate average monthly hours for a recurring session pattern';

-- ============================================================================
-- STEP 3: CREATE VALIDATION TRIGGER FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION public.validate_recurring_session_hours()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_minimum_hours numeric;
  v_calculated_hours numeric;
  v_duration_days integer;
  v_end_date date;
BEGIN
  -- Get the classroom's minimum monthly hours requirement
  SELECT minimum_monthly_hours INTO v_minimum_hours
  FROM public.classrooms
  WHERE id = NEW.classroom_id;
  
  -- If no minimum is set, skip validation
  IF v_minimum_hours IS NULL OR v_minimum_hours = 0 THEN
    RETURN NEW;
  END IF;
  
  -- Determine end date (use provided or 1 month from start for validation)
  v_end_date := COALESCE(NEW.end_date, NEW.start_date + interval '1 month');
  
  -- Calculate duration in days
  v_duration_days := v_end_date - NEW.start_date;
  
  -- Validate minimum duration: must be at least 30 days (1 month)
  IF v_duration_days < 30 THEN
    RAISE EXCEPTION 'Recurring sessions must span at least 30 days (1 month). Current duration: % days. Please extend the end date or select "No end date".', 
      v_duration_days;
  END IF;
  
  -- Calculate monthly hours for this recurring pattern
  v_calculated_hours := calculate_recurring_session_monthly_hours(
    NEW.start_time,
    NEW.end_time,
    NEW.recurrence_days,
    NEW.start_date,
    v_end_date
  );
  
  -- Validate against minimum requirement
  IF v_calculated_hours < v_minimum_hours THEN
    RAISE EXCEPTION 'Insufficient session hours. This classroom requires at least % hours per month, but the current schedule provides only % hours per month. Please add more days or extend session duration.',
      v_minimum_hours,
      ROUND(v_calculated_hours, 2);
  END IF;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.validate_recurring_session_hours IS 'Validates that recurring sessions meet minimum monthly hours requirement';

-- ============================================================================
-- STEP 4: CREATE TRIGGER
-- ============================================================================

DROP TRIGGER IF EXISTS check_recurring_session_hours ON public.recurring_sessions;

CREATE TRIGGER check_recurring_session_hours
  BEFORE INSERT OR UPDATE ON public.recurring_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_recurring_session_hours();

COMMENT ON TRIGGER check_recurring_session_hours ON public.recurring_sessions IS 'Ensures recurring sessions meet classroom minimum monthly hours';

-- ============================================================================
-- STEP 5: CREATE HELPER FUNCTION FOR UI
-- ============================================================================

-- Function to preview calculated hours before creating recurring session
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

-- ============================================================================
-- STEP 6: GRANT PERMISSIONS
-- ============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.calculate_recurring_session_monthly_hours TO authenticated;
GRANT EXECUTE ON FUNCTION public.preview_recurring_session_hours TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_recurring_session_hours TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Verification query
DO $$
BEGIN
  RAISE NOTICE '✅ Migration completed successfully!';
  RAISE NOTICE '📊 Classrooms now have minimum_monthly_hours column';
  RAISE NOTICE '🔍 Validation trigger active on recurring_sessions table';
  RAISE NOTICE '💡 Use preview_recurring_session_hours() to check before creating sessions';
END $$;
