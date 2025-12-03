-- ============================================================================
-- RECURRING SESSIONS MIGRATION
-- ============================================================================
-- Description: Add support for recurring sessions (e.g., weekly classes)
-- Date: October 27, 2025
-- Version: 1.0
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE RECURRING_SESSIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.recurring_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  classroom_id character varying NOT NULL,
  title character varying NOT NULL,
  description text,
  session_type character varying DEFAULT 'live',
  meeting_url text,
  is_recorded boolean DEFAULT false,
  
  -- Recurrence Pattern
  recurrence_type character varying NOT NULL CHECK (recurrence_type IN ('weekly', 'daily')),
  recurrence_days integer[] NOT NULL, -- Array: 0=Sunday, 1=Monday, ..., 6=Saturday
  start_time time NOT NULL,
  end_time time NOT NULL,
  
  -- Recurrence Bounds
  start_date date NOT NULL,
  end_date date, -- NULL = no end date
  
  -- Metadata
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  
  -- Foreign Keys
  CONSTRAINT recurring_sessions_classroom_id_fkey 
    FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id) ON DELETE CASCADE
);

-- Add comment
COMMENT ON TABLE public.recurring_sessions IS 'Template table for recurring class sessions';
COMMENT ON COLUMN public.recurring_sessions.recurrence_days IS 'Array of day numbers: 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday';
COMMENT ON COLUMN public.recurring_sessions.end_date IS 'NULL means the recurring session continues indefinitely';

-- ============================================================================
-- STEP 2: UPDATE CLASS_SESSIONS TABLE
-- ============================================================================

-- Add columns for recurring session tracking
ALTER TABLE public.class_sessions 
  ADD COLUMN IF NOT EXISTS recurring_session_id uuid,
  ADD COLUMN IF NOT EXISTS is_recurring_instance boolean DEFAULT false;

-- Add foreign key constraint
ALTER TABLE public.class_sessions
  ADD CONSTRAINT class_sessions_recurring_session_id_fkey 
    FOREIGN KEY (recurring_session_id) 
    REFERENCES public.recurring_sessions(id) 
    ON DELETE CASCADE;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_class_sessions_recurring_session_id 
  ON public.class_sessions(recurring_session_id)
  WHERE recurring_session_id IS NOT NULL;

-- Add index on session date for recurring queries
CREATE INDEX IF NOT EXISTS idx_class_sessions_date_recurring 
  ON public.class_sessions(session_date, recurring_session_id)
  WHERE is_recurring_instance = true;

-- Add comments
COMMENT ON COLUMN public.class_sessions.recurring_session_id IS 'References the parent recurring_sessions record if this is a generated instance';
COMMENT ON COLUMN public.class_sessions.is_recurring_instance IS 'True if this session was auto-generated from a recurring pattern';

-- ============================================================================
-- STEP 3: CREATE HELPER FUNCTION - GENERATE RECURRING SESSIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.generate_recurring_sessions(
  p_recurring_session_id uuid,
  p_months_ahead integer DEFAULT 3
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_recurring_session public.recurring_sessions%ROWTYPE;
  v_current_date date;
  v_end_date date;
  v_day_of_week integer;
  v_sessions_created integer := 0;
  v_max_end_date date;
BEGIN
  -- Get recurring session details
  SELECT * INTO v_recurring_session
  FROM public.recurring_sessions
  WHERE id = p_recurring_session_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Recurring session not found: %', p_recurring_session_id;
  END IF;
  
  -- Validate recurrence days
  IF array_length(v_recurring_session.recurrence_days, 1) IS NULL THEN
    RAISE EXCEPTION 'recurrence_days array cannot be empty';
  END IF;
  
  -- Set maximum end date (1 year from start_date as safety limit)
  v_max_end_date := v_recurring_session.start_date + interval '1 year';
  
  -- Set end date (either specified, months_ahead, or 1 year max)
  v_end_date := LEAST(
    COALESCE(
      v_recurring_session.end_date, 
      v_recurring_session.start_date + (p_months_ahead || ' months')::interval
    ),
    v_max_end_date
  );
  
  -- Loop through dates
  v_current_date := v_recurring_session.start_date;
  
  WHILE v_current_date <= v_end_date LOOP
    -- Get day of week (0=Sunday, 6=Saturday)
    v_day_of_week := EXTRACT(DOW FROM v_current_date);
    
    -- Check if this day is in the recurrence pattern
    IF v_day_of_week = ANY(v_recurring_session.recurrence_days) THEN
      -- Create session instance (using INSERT with ON CONFLICT to avoid duplicates)
      INSERT INTO public.class_sessions (
        classroom_id,
        title,
        description,
        session_date,
        start_time,
        end_time,
        session_type,
        meeting_url,
        is_recorded,
        recurring_session_id,
        is_recurring_instance,
        status
      ) VALUES (
        v_recurring_session.classroom_id,
        v_recurring_session.title,
        v_recurring_session.description,
        v_current_date,
        v_recurring_session.start_time,
        v_recurring_session.end_time,
        v_recurring_session.session_type,
        v_recurring_session.meeting_url,
        v_recurring_session.is_recorded,
        p_recurring_session_id,
        true,
        'scheduled'
      )
      ON CONFLICT (id) DO NOTHING;
      
      -- Check if row was inserted
      IF FOUND THEN
        v_sessions_created := v_sessions_created + 1;
      END IF;
    END IF;
    
    -- Move to next day
    v_current_date := v_current_date + interval '1 day';
  END LOOP;
  
  RETURN v_sessions_created;
END;
$$;

COMMENT ON FUNCTION public.generate_recurring_sessions IS 'Generates class_sessions instances from a recurring_sessions template';

-- ============================================================================
-- STEP 4: CREATE HELPER FUNCTION - DELETE RECURRING SERIES
-- ============================================================================

CREATE OR REPLACE FUNCTION public.delete_recurring_series(
  p_recurring_session_id uuid,
  p_delete_future_only boolean DEFAULT false,
  p_from_date date DEFAULT CURRENT_DATE
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sessions_deleted integer;
BEGIN
  IF p_delete_future_only THEN
    -- Delete only future instances (from specified date onwards)
    DELETE FROM public.class_sessions
    WHERE recurring_session_id = p_recurring_session_id
      AND session_date >= p_from_date
      AND is_recurring_instance = true;
    
    GET DIAGNOSTICS v_sessions_deleted = ROW_COUNT;
  ELSE
    -- Delete all instances
    DELETE FROM public.class_sessions
    WHERE recurring_session_id = p_recurring_session_id;
    
    GET DIAGNOSTICS v_sessions_deleted = ROW_COUNT;
    
    -- Delete the recurring session template
    DELETE FROM public.recurring_sessions
    WHERE id = p_recurring_session_id;
  END IF;
  
  RETURN v_sessions_deleted;
END;
$$;

COMMENT ON FUNCTION public.delete_recurring_series IS 'Deletes a recurring session series (all instances or future only)';

-- ============================================================================
-- STEP 5: CREATE HELPER FUNCTION - UPDATE RECURRING SERIES
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_recurring_series(
  p_recurring_session_id uuid,
  p_update_data jsonb,
  p_update_future_only boolean DEFAULT true
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sessions_updated integer := 0;
  v_from_date date := CURRENT_DATE;
BEGIN
  -- Update the recurring session template
  UPDATE public.recurring_sessions
  SET
    title = COALESCE((p_update_data->>'title')::varchar, title),
    description = COALESCE((p_update_data->>'description')::text, description),
    meeting_url = COALESCE((p_update_data->>'meeting_url')::text, meeting_url),
    start_time = COALESCE((p_update_data->>'start_time')::time, start_time),
    end_time = COALESCE((p_update_data->>'end_time')::time, end_time),
    updated_at = now()
  WHERE id = p_recurring_session_id;
  
  -- Update existing session instances
  IF p_update_future_only THEN
    -- Update only future instances
    UPDATE public.class_sessions
    SET
      title = COALESCE((p_update_data->>'title')::varchar, title),
      description = COALESCE((p_update_data->>'description')::text, description),
      meeting_url = COALESCE((p_update_data->>'meeting_url')::text, meeting_url),
      start_time = COALESCE((p_update_data->>'start_time')::time, start_time),
      end_time = COALESCE((p_update_data->>'end_time')::time, end_time),
      updated_at = now()
    WHERE recurring_session_id = p_recurring_session_id
      AND session_date >= v_from_date
      AND is_recurring_instance = true;
  ELSE
    -- Update all instances
    UPDATE public.class_sessions
    SET
      title = COALESCE((p_update_data->>'title')::varchar, title),
      description = COALESCE((p_update_data->>'description')::text, description),
      meeting_url = COALESCE((p_update_data->>'meeting_url')::text, meeting_url),
      start_time = COALESCE((p_update_data->>'start_time')::time, start_time),
      end_time = COALESCE((p_update_data->>'end_time')::time, end_time),
      updated_at = now()
    WHERE recurring_session_id = p_recurring_session_id
      AND is_recurring_instance = true;
  END IF;
  
  GET DIAGNOSTICS v_sessions_updated = ROW_COUNT;
  
  RETURN v_sessions_updated;
END;
$$;

COMMENT ON FUNCTION public.update_recurring_series IS 'Updates a recurring session template and its instances (all or future only)';

-- ============================================================================
-- STEP 6: ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.recurring_sessions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 7: CREATE RLS POLICIES FOR RECURRING_SESSIONS
-- ============================================================================

-- Policy: Teachers can view recurring sessions for their classrooms
CREATE POLICY "Teachers can view recurring sessions for their classrooms"
  ON public.recurring_sessions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = recurring_sessions.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers 
        WHERE user_id = auth.uid()
      )
    )
  );

-- Policy: Teachers can create recurring sessions for their classrooms
CREATE POLICY "Teachers can create recurring sessions"
  ON public.recurring_sessions
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = recurring_sessions.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers 
        WHERE user_id = auth.uid()
      )
    )
  );

-- Policy: Teachers can update their recurring sessions
CREATE POLICY "Teachers can update recurring sessions"
  ON public.recurring_sessions
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = recurring_sessions.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers 
        WHERE user_id = auth.uid()
      )
    )
  );

-- Policy: Teachers can delete their recurring sessions
CREATE POLICY "Teachers can delete recurring sessions"
  ON public.recurring_sessions
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.classrooms
      WHERE classrooms.id = recurring_sessions.classroom_id
      AND classrooms.teacher_id IN (
        SELECT id FROM public.teachers 
        WHERE user_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- STEP 8: CREATE TRIGGER - AUTO-UPDATE TIMESTAMP
-- ============================================================================

-- Create the update_updated_at_column function if it doesn't exist
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for recurring_sessions
CREATE TRIGGER update_recurring_sessions_updated_at
  BEFORE UPDATE ON public.recurring_sessions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify table was created
-- SELECT EXISTS (
--   SELECT FROM information_schema.tables 
--   WHERE table_schema = 'public' 
--   AND table_name = 'recurring_sessions'
-- );

-- Verify columns were added to class_sessions
-- SELECT column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'class_sessions' 
-- AND column_name IN ('recurring_session_id', 'is_recurring_instance');

-- Verify functions exist
-- SELECT routine_name 
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
-- AND routine_name LIKE '%recurring%';

-- ============================================================================
-- ROLLBACK SCRIPT (IF NEEDED)
-- ============================================================================

-- DROP FUNCTION IF EXISTS public.update_recurring_series(uuid, jsonb, boolean);
-- DROP FUNCTION IF EXISTS public.delete_recurring_series(uuid, boolean, date);
-- DROP FUNCTION IF EXISTS public.generate_recurring_sessions(uuid, integer);
-- ALTER TABLE public.class_sessions DROP COLUMN IF EXISTS is_recurring_instance;
-- ALTER TABLE public.class_sessions DROP COLUMN IF EXISTS recurring_session_id;
-- DROP TABLE IF EXISTS public.recurring_sessions CASCADE;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
