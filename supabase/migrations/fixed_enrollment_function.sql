-- ==================================================
-- FIXED ENROLLMENT FUNCTION FOR CURRENT SCHEMA
-- This version works with your existing table structure
-- ==================================================

-- Drop the existing function first
DROP FUNCTION IF EXISTS enroll_student_with_payment(UUID, UUID, UUID, NUMERIC);

-- Create the new function with JSONB return type
CREATE OR REPLACE FUNCTION enroll_student_with_payment(
    p_student_id UUID,
    p_classroom_id UUID, 
    p_payment_plan_id UUID,
    p_amount_paid NUMERIC
) RETURNS JSONB AS $$
DECLARE
  v_teacher_id UUID;
  v_classroom_record RECORD;
  v_payment_plan RECORD;
  v_payment_id UUID;
  v_enrollment_id UUID;
  v_user_id UUID;
BEGIN
  -- Get classroom details
  SELECT * INTO v_classroom_record 
  FROM classrooms 
  WHERE id = p_classroom_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Classroom not found with ID: %', p_classroom_id;
  END IF;
  
  -- Get payment plan details
  SELECT * INTO v_payment_plan 
  FROM payment_plans 
  WHERE id = p_payment_plan_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment plan not found with ID: %', p_payment_plan_id;
  END IF;
  
  -- Get user_id for the student
  SELECT user_id INTO v_user_id 
  FROM students 
  WHERE id = p_student_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Student not found with ID: %', p_student_id;
  END IF;
  
  -- Create payment record
  INSERT INTO payments (
    id,
    student_id,
    classroom_id,
    amount,
    currency,
    payment_method,
    payment_status,
    status,
    payment_date,
    description,
    created_at
  ) VALUES (
    gen_random_uuid(),
    p_student_id,
    p_classroom_id,
    p_amount_paid,
    'USD',
    'credit_card',
    'completed',
    'completed',
    NOW(),
    'Enrollment payment for: ' || v_classroom_record.name,
    NOW()
  )
  RETURNING id INTO v_payment_id;
  
  -- Create enrollment request (approved and paid)
  INSERT INTO enrollment_requests (
    id,
    student_id,
    classroom_id,
    request_status,
    payment_id,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    p_student_id,
    p_classroom_id,
    'paid',
    v_payment_id,
    NOW(),
    NOW()
  )
  RETURNING id INTO v_enrollment_id;
  
  -- Create student classroom assignment
  INSERT INTO student_classroom_assignments (
    id,
    student_id,
    classroom_id,
    teacher_id,
    assigned_by,
    status,
    assigned_date,
    enrolled_date,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    p_student_id,
    p_classroom_id,
    v_classroom_record.teacher_id,
    v_user_id, -- assigned by the student themselves
    'active',
    CURRENT_DATE,
    NOW(),
    NOW(),
    NOW()
  );
  
  -- Create student subscription if payment plan has monthly billing
  IF v_payment_plan.billing_cycle = 'monthly' THEN
    INSERT INTO student_subscriptions (
      id,
      student_id,
      payment_plan_id,
      start_date,
      end_date,
      status,
      auto_renew,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      p_student_id,
      p_payment_plan_id,
      CURRENT_DATE,
      CURRENT_DATE + INTERVAL '1 month',
      'active',
      true,
      NOW(),
      NOW()
    );
  END IF;
  
  -- Create attendance records for upcoming sessions
  INSERT INTO session_attendance (
    id,
    session_id,
    student_id,
    attendance_status,
    created_at
  )
  SELECT 
    gen_random_uuid(),
    s.id,
    p_student_id,
    'absent', -- Default to absent, will be updated when student attends
    NOW()
  FROM class_sessions s
  WHERE s.classroom_id = p_classroom_id
  AND s.scheduled_start > NOW()
  AND s.session_status = 'scheduled';
  
  -- Log success
  INSERT INTO trigger_logs (message, metadata)
  VALUES (
    'Student enrolled successfully via enroll_student_with_payment',
    jsonb_build_object(
      'student_id', p_student_id,
      'classroom_id', p_classroom_id,
      'payment_id', v_payment_id,
      'enrollment_id', v_enrollment_id,
      'amount_paid', p_amount_paid
    )
  );
  
  -- Return success response
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Student enrolled successfully',
    'payment_id', v_payment_id,
    'enrollment_id', v_enrollment_id,
    'classroom_name', v_classroom_record.name
  );
  
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error
    INSERT INTO trigger_logs (message, error_message, metadata)
    VALUES (
      'Error in enroll_student_with_payment',
      SQLERRM,
      jsonb_build_object(
        'student_id', p_student_id,
        'classroom_id', p_classroom_id,
        'payment_plan_id', p_payment_plan_id,
        'amount_paid', p_amount_paid,
        'error_code', SQLSTATE
      )
    );
    
    -- Re-raise the exception
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- ==================================================
-- HELPER FUNCTION: Get enrolled classrooms for student
-- ==================================================

CREATE OR REPLACE FUNCTION get_enrolled_classrooms(p_student_id UUID)
RETURNS TABLE(classroom_id UUID) AS $$
BEGIN
  RETURN QUERY
  SELECT sca.classroom_id
  FROM public.student_classroom_assignments sca
  WHERE sca.student_id = p_student_id
    AND sca.status = 'active';
END;
$$ LANGUAGE plpgsql;

-- ==================================================
-- OPTIONAL: Create missing tables if you want the original function
-- ==================================================

-- Transactions table (if you want to track payments separately)
/*
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  amount NUMERIC NOT NULL,
  currency VARCHAR DEFAULT 'USD',
  payment_method VARCHAR,
  status VARCHAR CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
*/

-- Audit log table (for tracking actions)
/*
CREATE TABLE IF NOT EXISTS audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action VARCHAR NOT NULL,
  table_name VARCHAR NOT NULL,
  record_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
*/

-- Error log table (for tracking errors)
/*
CREATE TABLE IF NOT EXISTS error_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  error_time TIMESTAMPTZ DEFAULT NOW(),
  error_message TEXT,
  error_context TEXT,
  user_id UUID REFERENCES users(id)
);
*/

-- Email queue table (for sending emails)
/*
CREATE TABLE IF NOT EXISTS email_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_email VARCHAR NOT NULL,
  subject VARCHAR NOT NULL,
  template_name VARCHAR,
  template_data JSONB,
  status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ
);
*/
