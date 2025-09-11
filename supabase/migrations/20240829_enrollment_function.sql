-- Function to handle student enrollment with payment
CREATE OR REPLACE FUNCTION enroll_student_with_payment(
  p_student_id UUID,
  p_classroom_id UUID,
  p_payment_plan_id UUID,
  p_amount_paid DECIMAL(10,2)
) 
RETURNS VOID AS $$
DECLARE
  v_teacher_id UUID;
  v_duration_days INT;
  v_end_date DATE;
  v_subscription_id UUID;
  v_transaction_id UUID;
  v_classroom_record RECORD;
  v_payment_plan RECORD;
BEGIN
  -- Get classroom and payment plan details
  SELECT * INTO v_classroom_record 
  FROM classrooms 
  WHERE id = p_classroom_id 
  FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Classroom not found';
  END IF;
  
  SELECT * INTO v_payment_plan 
  FROM payment_plans 
  WHERE id = p_payment_plan_id 
  FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment plan not found';
  END IF;
  
  -- Create transaction record
  INSERT INTO transactions (
    id,
    user_id,
    amount,
    currency,
    payment_method,
    status,
    description
  ) VALUES (
    gen_random_uuid(),
    (SELECT user_id FROM students WHERE id = p_student_id),
    p_amount_paid,
    'USD',
    'credit_card',
    'succeeded',
    'Classroom enrollment: ' || v_classroom_record.name
  )
  RETURNING id INTO v_transaction_id;
  
  -- Create subscription
  v_end_date := CURRENT_DATE + (v_payment_plan.duration_days || ' days')::INTERVAL;
  
  INSERT INTO student_subscriptions (
    id,
    student_id,
    payment_plan_id,
    start_date,
    end_date,
    status,
    payment_status,
    amount_paid
  ) VALUES (
    gen_random_uuid(),
    p_student_id,
    p_payment_plan_id,
    CURRENT_DATE,
    v_end_date,
    'active',
    'paid',
    p_amount_paid
  )
  RETURNING id INTO v_subscription_id;
  
  -- Link subscription to transaction
  INSERT INTO subscription_payments (
    subscription_id,
    transaction_id,
    payment_date
  ) VALUES (
    v_subscription_id,
    v_transaction_id,
    CURRENT_DATE
  );
  
  -- Enroll student in classroom
  INSERT INTO student_classroom_assignments (
    id,
    student_id,
    classroom_id,
    teacher_id,
    status,
    assigned_date
  ) VALUES (
    gen_random_uuid(),
    p_student_id,
    p_classroom_id,
    v_classroom_record.teacher_id,
    'active',
    CURRENT_DATE
  );
  
  -- Create attendance records for upcoming sessions
  INSERT INTO session_attendance (
    id,
    session_id,
    student_id,
    attendance_status
  )
  SELECT 
    gen_random_uuid(),
    s.id,
    p_student_id,
    'scheduled'
  FROM class_sessions s
  WHERE s.classroom_id = p_classroom_id
  AND s.scheduled_start > NOW()
  AND s.session_status = 'scheduled';
  
  -- Update classroom student count
  UPDATE classrooms 
  SET student_count = COALESCE(student_count, 0) + 1
  WHERE id = p_classroom_id;
  
  -- Log the enrollment
  INSERT INTO audit_log (
    user_id,
    action,
    table_name,
    record_id,
    details
  ) VALUES (
    (SELECT user_id FROM students WHERE id = p_student_id),
    'ENROLL',
    'student_classroom_assignments',
    p_classroom_id,
    jsonb_build_object(
      'classroom', v_classroom_record.name,
      'payment_plan', v_payment_plan.name,
      'amount_paid', p_amount_paid
    )
  );
  
  -- If this is the first student, update the classroom status to active
  IF (SELECT COUNT(*) FROM student_classroom_assignments WHERE classroom_id = p_classroom_id) = 1 THEN
    UPDATE classrooms 
    SET status = 'active' 
    WHERE id = p_classroom_id;
  END IF;
  
  -- If the classroom has reached maximum capacity, mark it as full
  IF (SELECT student_count FROM classrooms WHERE id = p_classroom_id) >= 
     (SELECT max_students FROM classrooms WHERE id = p_classroom_id) THEN
    UPDATE classrooms 
    SET status = 'full' 
    WHERE id = p_classroom_id;
  END IF;
  
  -- Send notification to teacher
  PERFORM pg_notify('new_student_enrollment', 
    jsonb_build_object(
      'classroom_id', p_classroom_id,
      'classroom_name', v_classroom_record.name,
      'student_id', p_student_id,
      'teacher_id', v_classroom_record.teacher_id
    )::text
  );
  
  -- Send welcome email (this would be handled by a trigger or external service)
  -- For now, we'll just log it
  INSERT INTO email_queue (
    recipient_email,
    subject,
    template_name,
    template_data
  ) VALUES (
    (SELECT email FROM users WHERE id = (SELECT user_id FROM students WHERE id = p_student_id)),
    'Welcome to ' || v_classroom_record.name || '!',
    'welcome_to_classroom',
    jsonb_build_object(
      'student_name', (SELECT first_name || ' ' || last_name FROM users WHERE id = (SELECT user_id FROM students WHERE id = p_student_id)),
      'classroom_name', v_classroom_record.name,
      'teacher_name', (SELECT first_name || ' ' || last_name FROM users WHERE id = v_classroom_record.teacher_id),
      'start_date', CURRENT_DATE,
      'end_date', v_end_date,
      'payment_amount', p_amount_paid
    )
  );
  
  -- Log successful enrollment
  RAISE NOTICE 'Successfully enrolled student % in classroom %', p_student_id, p_classroom_id;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error
    INSERT INTO error_log (
      error_time,
      error_message,
      error_context,
      user_id
    ) VALUES (
      NOW(),
      SQLERRM,
      'enroll_student_with_payment(' || 
      'student_id: ' || COALESCE(p_student_id::text, 'NULL') || ', ' ||
      'classroom_id: ' || COALESCE(p_classroom_id::text, 'NULL') || ', ' ||
      'payment_plan_id: ' || COALESCE(p_payment_plan_id::text, 'NULL') || ', ' ||
      'amount_paid: ' || COALESCE(p_amount_paid::text, 'NULL') || ')',
      (SELECT user_id FROM students WHERE id = p_student_id)
    );
    
    -- Re-raise the exception
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION enroll_student_with_payment(UUID, UUID, UUID, DECIMAL) TO authenticated;
