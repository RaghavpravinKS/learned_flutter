
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




BEGIN
  RETURN QUERY
  SELECT sca.classroom_id
  FROM public.student_classroom_assignments sca
  WHERE sca.student_id = p_student_id;
END; 




DECLARE
  v_user_type text;
  v_grade_level integer;
  v_board text;
  v_school_name text;
  user_exists boolean := false;
  profile_exists boolean := false;
BEGIN
    -- Log that we're starting
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'Trigger starting for user',
        jsonb_build_object(
            'user_id', NEW.id,
            'email', NEW.email,
            'raw_meta', NEW.raw_user_meta_data
        )
    );

    -- Check if the user already exists in the public.users table
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = NEW.id) INTO user_exists;

    -- If the user does not exist, insert them
    IF NOT user_exists THEN
        -- Extract user type as text first
        v_user_type := NEW.raw_user_meta_data->>'user_type';
        
        INSERT INTO public.users (
            id, email, user_type, first_name, last_name, password_hash, is_active, email_verified, created_at, updated_at
        ) VALUES (
            NEW.id, 
            NEW.email, 
            v_user_type::public.user_type,
            COALESCE(NEW.raw_user_meta_data->>'first_name', 'New'),
            COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
            COALESCE(NEW.encrypted_password, 'temp_hash'),
            true, 
            false,
            NOW(),
            NOW()
        );
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES ('User created in public.users', jsonb_build_object('user_id', NEW.id));
    END IF;

    -- Check if user profile exists (no unique constraint, so we check manually)
    SELECT EXISTS(SELECT 1 FROM public.user_profiles WHERE user_id = NEW.id) INTO profile_exists;
    
    -- Create a user profile only if it doesn't exist
    IF NOT profile_exists THEN
        INSERT INTO public.user_profiles (user_id, created_at, updated_at) 
        VALUES (NEW.id, NOW(), NOW());
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES ('User profile created', jsonb_build_object('user_id', NEW.id));
    END IF;

    -- Handle student-specific logic
    IF v_user_type = 'student' THEN
        -- Extract student-specific data
        v_grade_level := (NEW.raw_user_meta_data->>'grade_level')::integer;
        v_board := NEW.raw_user_meta_data->>'board';
        v_school_name := NEW.raw_user_meta_data->>'school_name';
        
        -- Students table has UNIQUE constraint on user_id, so ON CONFLICT works
        INSERT INTO public.students (
            id, user_id, student_id, grade_level, board, school_name, status, created_at, updated_at
        ) VALUES (
            NEW.id,
            NEW.id, 
            'STU-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)), 
            v_grade_level, 
            v_board,
            v_school_name,
            'active',
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES ('Student record created', jsonb_build_object('user_id', NEW.id, 'grade', v_grade_level));
        
    ELSIF v_user_type = 'teacher' THEN
        -- Teachers table has UNIQUE constraint on user_id, so ON CONFLICT works
        INSERT INTO public.teachers (
            id, user_id, teacher_id, status, created_at, updated_at
        ) VALUES (
            NEW.id,
            NEW.id,
            'TCH-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)), 
            'active',
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES ('Teacher record created', jsonb_build_object('user_id', NEW.id));
        
    ELSIF v_user_type = 'parent' THEN
        -- Parents table has UNIQUE constraint on user_id, so ON CONFLICT works
        INSERT INTO public.parents (
            id, user_id, parent_id, created_at, updated_at
        ) VALUES (
            NEW.id,
            NEW.id,
            'PAR-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES ('Parent record created', jsonb_build_object('user_id', NEW.id));
    END IF;
    
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES ('Trigger completed successfully', jsonb_build_object('user_id', NEW.id));
    
    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    -- Log the error
    INSERT INTO public.trigger_logs (message, error_message, metadata)
    VALUES (
        'TRIGGER ERROR',
        SQLERRM,
        jsonb_build_object(
            'error_context', SQLSTATE, 
            'user_email', NEW.email, 
            'user_id', NEW.id,
            'raw_meta', NEW.raw_user_meta_data
        )
    );
    -- Return NEW to ensure auth transaction doesn't fail
    RETURN NEW;
END;
