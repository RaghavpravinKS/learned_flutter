-- Enhanced enrollment system compatible with current schema
-- This adds missing fields and functions to work with existing tables

-- Step 1: Add missing fields to existing tables
ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'active' 
CHECK (status IN ('active', 'inactive', 'completed', 'cancelled'));

ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS current_enrollment INTEGER DEFAULT 0;

ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS next_session_date TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS schedule_days TEXT[];

ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS schedule_time TIME;

ALTER TABLE public.classrooms 
ADD COLUMN IF NOT EXISTS duration_weeks INTEGER DEFAULT 12;

-- Step 2: Add missing fields to payments table to match expected structure
ALTER TABLE public.payments 
ADD COLUMN IF NOT EXISTS classroom_id UUID REFERENCES public.classrooms(id);

ALTER TABLE public.payments 
ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'pending' 
CHECK (status IN ('pending', 'completed', 'failed', 'refunded', 'cancelled'));

-- Rename payment_status to status if it exists
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'payments' AND column_name = 'payment_status') THEN
        ALTER TABLE public.payments RENAME COLUMN payment_status TO status;
    END IF;
EXCEPTION
    WHEN duplicate_column THEN
        -- Column already exists, do nothing
        NULL;
END $$;

-- Step 3: Add missing fields to student_classroom_assignments
ALTER TABLE public.student_classroom_assignments 
ADD COLUMN IF NOT EXISTS enrolled_date TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE public.student_classroom_assignments 
ADD COLUMN IF NOT EXISTS payment_id UUID REFERENCES public.payments(id);

ALTER TABLE public.student_classroom_assignments 
ADD COLUMN IF NOT EXISTS progress DECIMAL(5,2) DEFAULT 0.0;

-- Step 4: Add missing fields to classroom_pricing
ALTER TABLE public.classroom_pricing 
ADD COLUMN IF NOT EXISTS currency VARCHAR DEFAULT 'INR';

ALTER TABLE public.classroom_pricing 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

ALTER TABLE public.classroom_pricing 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Step 5: Add missing fields to payment_plans
ALTER TABLE public.payment_plans 
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE public.payment_plans 
ADD COLUMN IF NOT EXISTS billing_cycle VARCHAR DEFAULT 'monthly' 
CHECK (billing_cycle IN ('monthly', 'yearly', 'one_time', 'weekly'));

-- Step 6: Function to handle student enrollment (compatible with current schema)
CREATE OR REPLACE FUNCTION handle_student_enrollment(
  p_student_id UUID,
  p_classroom_id UUID,
  p_payment_method TEXT DEFAULT 'stripe',
  p_amount DECIMAL(10,2) DEFAULT 0.00,
  p_transaction_id TEXT DEFAULT NULL
) RETURNS TABLE (
  enrollment_id UUID,
  payment_id UUID,
  status TEXT,
  message TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_enrollment_id UUID;
  v_payment_id UUID;
  v_classroom_exists BOOLEAN;
  v_student_exists BOOLEAN;
  v_already_enrolled BOOLEAN;
  v_teacher_id UUID;
BEGIN
  -- Generate IDs
  v_enrollment_id := gen_random_uuid();
  v_payment_id := gen_random_uuid();
  
  -- Check if classroom exists and is active
  SELECT EXISTS(
    SELECT 1 FROM classrooms 
    WHERE id = p_classroom_id 
    AND is_active = true
  ), teacher_id INTO v_classroom_exists, v_teacher_id
  FROM classrooms 
  WHERE id = p_classroom_id;
  
  IF NOT v_classroom_exists THEN
    RETURN QUERY SELECT NULL::UUID, NULL::UUID, 'error'::TEXT, 'Classroom not found or inactive'::TEXT;
    RETURN;
  END IF;
  
  -- Check if student exists
  SELECT EXISTS(
    SELECT 1 FROM students 
    WHERE id = p_student_id
  ) INTO v_student_exists;
  
  IF NOT v_student_exists THEN
    RETURN QUERY SELECT NULL::UUID, NULL::UUID, 'error'::TEXT, 'Student not found'::TEXT;
    RETURN;
  END IF;
  
  -- Check if already enrolled
  SELECT EXISTS(
    SELECT 1 FROM student_classroom_assignments 
    WHERE student_id = p_student_id 
    AND classroom_id = p_classroom_id
    AND status IN ('active', 'completed')
  ) INTO v_already_enrolled;
  
  IF v_already_enrolled THEN
    RETURN QUERY SELECT NULL::UUID, NULL::UUID, 'error'::TEXT, 'Student already enrolled in this classroom'::TEXT;
    RETURN;
  END IF;
  
  -- Start transaction for enrollment and payment
  BEGIN
    -- Create payment record first
    INSERT INTO payments (
      id,
      student_id,
      classroom_id,
      amount,
      currency,
      payment_method,
      transaction_id,
      status,
      created_at
    ) VALUES (
      v_payment_id,
      p_student_id,
      p_classroom_id,
      p_amount,
      'USD',
      p_payment_method,
      COALESCE(p_transaction_id, 'sim_' || v_payment_id::TEXT),
      'completed',
      NOW()
    );
    
    -- Create enrollment record using student_classroom_assignments table
    INSERT INTO student_classroom_assignments (
      id,
      student_id,
      classroom_id,
      teacher_id,
      enrolled_date,
      status,
      progress,
      payment_id,
      created_at,
      updated_at
    ) VALUES (
      v_enrollment_id,
      p_student_id,
      p_classroom_id,
      v_teacher_id,
      NOW(),
      'active',
      0.0,
      v_payment_id,
      NOW(),
      NOW()
    );
    
    -- Update classroom enrollment count
    UPDATE classrooms 
    SET 
      current_enrollment = current_enrollment + 1,
      updated_at = NOW()
    WHERE id = p_classroom_id;
    
    -- Return success
    RETURN QUERY SELECT v_enrollment_id, v_payment_id, 'success'::TEXT, 'Student enrolled successfully'::TEXT;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Log error and return failure
      RAISE WARNING 'Enrollment failed for student % in classroom %: %', p_student_id, p_classroom_id, SQLERRM;
      RETURN QUERY SELECT NULL::UUID, NULL::UUID, 'error'::TEXT, ('Enrollment failed: ' || SQLERRM)::TEXT;
  END;
END;
$$;

-- Step 7: Function to get enrolled classrooms (compatible with current schema)
CREATE OR REPLACE FUNCTION get_student_enrolled_classrooms(
  p_student_id UUID
) RETURNS TABLE (
  classroom_id UUID,
  classroom_name TEXT,
  subject TEXT,
  grade_level INTEGER,
  teacher_name TEXT,
  enrollment_date TIMESTAMP WITH TIME ZONE,
  progress DECIMAL(5,2),
  next_session TIMESTAMP WITH TIME ZONE,
  status TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as classroom_id,
    c.name as classroom_name,
    c.subject,
    c.grade_level,
    COALESCE(u.first_name || ' ' || u.last_name, 'Unknown Teacher') as teacher_name,
    sca.enrolled_date as enrollment_date,
    COALESCE(sca.progress, 0.0) as progress,
    c.next_session_date as next_session,
    sca.status
  FROM student_classroom_assignments sca
  JOIN classrooms c ON sca.classroom_id = c.id
  JOIN teachers t ON c.teacher_id = t.id
  LEFT JOIN users u ON t.user_id = u.id
  WHERE sca.student_id = p_student_id
    AND sca.status IN ('active', 'completed')
    AND c.is_active = true
  ORDER BY sca.enrolled_date DESC;
END;
$$;

-- Step 8: Trigger to update classroom statistics when assignments change
CREATE OR REPLACE FUNCTION update_classroom_stats() 
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- Update current enrollment count
  IF TG_OP = 'INSERT' AND NEW.status = 'active' THEN
    UPDATE classrooms 
    SET current_enrollment = current_enrollment + 1
    WHERE id = NEW.classroom_id;
  END IF;
  
  IF TG_OP = 'UPDATE' THEN
    -- If status changed from active to something else
    IF OLD.status = 'active' AND NEW.status != 'active' THEN
      UPDATE classrooms 
      SET current_enrollment = current_enrollment - 1
      WHERE id = NEW.classroom_id;
    END IF;
    
    -- If status changed to active from something else
    IF OLD.status != 'active' AND NEW.status = 'active' THEN
      UPDATE classrooms 
      SET current_enrollment = current_enrollment + 1
      WHERE id = NEW.classroom_id;
    END IF;
  END IF;
  
  IF TG_OP = 'DELETE' AND OLD.status = 'active' THEN
    UPDATE classrooms 
    SET current_enrollment = current_enrollment - 1
    WHERE id = OLD.classroom_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_update_classroom_stats ON student_classroom_assignments;
CREATE TRIGGER trigger_update_classroom_stats
  AFTER INSERT OR UPDATE OR DELETE ON student_classroom_assignments
  FOR EACH ROW EXECUTE FUNCTION update_classroom_stats();

-- Grant permissions
GRANT EXECUTE ON FUNCTION handle_student_enrollment TO authenticated;
GRANT EXECUTE ON FUNCTION get_student_enrolled_classrooms TO authenticated;
