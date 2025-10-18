### assign_teacher_to_classroom

DECLARE
    v_classroom_record public.classrooms%ROWTYPE;
    v_teacher_record public.teachers%ROWTYPE;
    v_teacher_user_record public.users%ROWTYPE;
    v_old_teacher_id uuid;
BEGIN
    -- Validate admin user
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Admin access required');
    END IF;
    
    -- Validate classroom exists
    SELECT * INTO v_classroom_record FROM public.classrooms WHERE id = p_classroom_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Classroom not found');
    END IF;
    
    -- Store old teacher ID for audit logging
    v_old_teacher_id := v_classroom_record.teacher_id;
    
    -- If p_teacher_id is provided, validate teacher exists
    IF p_teacher_id IS NOT NULL THEN
        SELECT * INTO v_teacher_record FROM public.teachers WHERE id = p_teacher_id;
        IF NOT FOUND THEN
            RETURN jsonb_build_object('success', false, 'error', 'Teacher not found');
        END IF;
        
        -- Get teacher user record for name
        SELECT * INTO v_teacher_user_record FROM public.users WHERE id = v_teacher_record.user_id;
    END IF;
    
    -- Update classroom with new teacher
    UPDATE public.classrooms 
    SET teacher_id = p_teacher_id,
        updated_at = now()
    WHERE id = p_classroom_id;
    
    -- Log audit event
    PERFORM public.log_audit_event(
        p_user_id := p_admin_id,
        p_action_type := 'classroom_teacher_assigned',
        p_table_name := 'classrooms',
        p_record_id := v_classroom_record.id::uuid,
        p_old_values := jsonb_build_object('teacher_id', v_old_teacher_id),
        p_new_values := jsonb_build_object('teacher_id', p_teacher_id),
        p_description := CASE 
            WHEN p_teacher_id IS NULL THEN 'Teacher removed from classroom: ' || v_classroom_record.name
            ELSE 'Teacher assigned to classroom: ' || v_classroom_record.name || ' - ' || v_teacher_user_record.first_name || ' ' || v_teacher_user_record.last_name
        END,
        p_severity := 'info',
        p_tags := ARRAY['classroom', 'teacher', 'assignment', 'admin'],
        p_metadata := jsonb_build_object(
            'classroom_name', v_classroom_record.name,
            'teacher_name', CASE 
                WHEN p_teacher_id IS NOT NULL THEN v_teacher_user_record.first_name || ' ' || v_teacher_user_record.last_name
                ELSE NULL
            END,
            'previous_teacher_id', v_old_teacher_id
        )
    );
    
    -- Log admin activity
    INSERT INTO public.admin_activities (
        admin_id, activity_type, target_table, target_record_id, description, metadata, created_at
    ) VALUES (
        p_admin_id, 'assign_teacher_classroom', 'classrooms', v_classroom_record.id::uuid,
        CASE 
            WHEN p_teacher_id IS NULL THEN 'Removed teacher from classroom: ' || v_classroom_record.name
            ELSE 'Assigned teacher to classroom: ' || v_classroom_record.name
        END,
        jsonb_build_object(
            'classroom_id', p_classroom_id,
            'teacher_id', p_teacher_id,
            'previous_teacher_id', v_old_teacher_id
        ),
        now()
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'classroom_id', p_classroom_id,
        'teacher_id', p_teacher_id,
        'teacher_name', CASE 
            WHEN p_teacher_id IS NOT NULL THEN v_teacher_user_record.first_name || ' ' || v_teacher_user_record.last_name
            ELSE NULL
        END,
        'message', CASE 
            WHEN p_teacher_id IS NULL THEN 'Teacher removed from classroom successfully'
            ELSE 'Teacher assigned to classroom successfully'
        END
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;


### create_teacher_by_admin


DECLARE
    v_user_id uuid;
    v_teacher_id uuid;
    v_teacher_id_val text;
BEGIN
    -- Validate admin user
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Admin access required');
    END IF;

    -- Generate teacher ID
    v_teacher_id_val := 'TEA' || to_char(now(), 'YYYYMMDD') || substr(gen_random_uuid()::text, 1, 6);

    -- Create user record
    INSERT INTO public.users (
        email, user_type, first_name, last_name, phone,
        is_active, email_verified, created_at, updated_at
    ) VALUES (
        p_email, 'teacher', p_first_name, p_last_name, p_phone,
        true, true, now(), now()
    ) RETURNING id INTO v_user_id;

    -- Create teacher record
    INSERT INTO public.teachers (
        user_id, teacher_id, qualifications, experience_years,
        bio, status, created_at, updated_at
    ) VALUES (
        v_user_id, v_teacher_id_val, p_qualifications, p_experience_years,
        p_bio, 'active', now(), now()
    ) RETURNING id INTO v_teacher_id;

    -- Log admin activity
    INSERT INTO public.admin_activities (
        admin_id, activity_type, target_user_id, description, metadata, created_at
    ) VALUES (
        p_admin_id, 'create_teacher', v_user_id, 
        'Created teacher account: ' || p_first_name || ' ' || p_last_name,
        p_metadata, now()
    );

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'teacher_id', v_teacher_id,
        'teacher_id_val', v_teacher_id_val,
        'message', 'Teacher account created successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;

### enroll_student_with_payment


DECLARE
    v_enrollment_id uuid;
    v_payment_id uuid;
    v_student_record students%ROWTYPE;
    v_classroom_record classrooms%ROWTYPE;
    v_payment_plan_record payment_plans%ROWTYPE;
    v_start_date timestamp with time zone;
    v_end_date timestamp with time zone;
    v_next_billing_date timestamp with time zone;
    v_step text;
BEGIN
    v_step := 'initialization';
    
    -- Log function start
    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Starting enrollment process',
        jsonb_build_object(
            'function_name', 'enroll_student_with_payment',
            'step', 'initialization',
            'parameters', jsonb_build_object(
                'p_student_id', p_student_id,
                'p_classroom_id', p_classroom_id,
                'p_payment_plan_id', p_payment_plan_id,
                'p_amount_paid', p_amount_paid
            ),
            'user_id', auth.uid()
        )
    );

    v_step := 'validating_student';
    -- Validate student exists
    SELECT * INTO v_student_record FROM students WHERE id = p_student_id;
    IF NOT FOUND THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Student validation failed',
            'Student not found',
            jsonb_build_object('student_id', p_student_id, 'step', v_step)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Student not found');
    END IF;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Student validation successful',
        jsonb_build_object('step', v_step, 'student_id', v_student_record.student_id)
    );

    v_step := 'validating_classroom';
    -- Validate classroom exists
    SELECT * INTO v_classroom_record FROM classrooms WHERE id = p_classroom_id;
    IF NOT FOUND THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Classroom validation failed',
            'Classroom not found',
            jsonb_build_object('classroom_id', p_classroom_id, 'step', v_step)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Classroom not found');
    END IF;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Classroom validation successful',
        jsonb_build_object('step', v_step, 'classroom_name', v_classroom_record.name)
    );

    v_step := 'validating_payment_plan';
    -- Validate payment plan exists
    SELECT * INTO v_payment_plan_record FROM payment_plans WHERE id = p_payment_plan_id;
    IF NOT FOUND THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Payment plan validation failed',
            'Payment plan not found',
            jsonb_build_object('payment_plan_id', p_payment_plan_id, 'step', v_step)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Payment plan not found');
    END IF;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Payment plan validation successful',
        jsonb_build_object('step', v_step, 'plan_name', v_payment_plan_record.name, 'billing_cycle', v_payment_plan_record.billing_cycle)
    );

    v_step := 'checking_existing_enrollment';
    -- Check if already enrolled
    IF EXISTS (SELECT 1 FROM student_enrollments WHERE student_id = p_student_id AND classroom_id = p_classroom_id) THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Duplicate enrollment check failed',
            'Student already enrolled',
            jsonb_build_object('student_id', p_student_id, 'classroom_id', p_classroom_id, 'step', v_step)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Student already enrolled in this classroom');
    END IF;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Duplicate enrollment check passed',
        jsonb_build_object('step', v_step)
    );

    v_step := 'calculating_dates';
    -- Calculate subscription dates based on billing cycle
    v_start_date := now();
    CASE v_payment_plan_record.billing_cycle
        WHEN 'monthly' THEN
            v_end_date := v_start_date + INTERVAL '1 month';
            v_next_billing_date := v_start_date + INTERVAL '1 month';
        WHEN 'quarterly' THEN
            v_end_date := v_start_date + INTERVAL '3 months';
            v_next_billing_date := v_start_date + INTERVAL '3 months';
        WHEN 'yearly' THEN
            v_end_date := v_start_date + INTERVAL '1 year';
            v_next_billing_date := v_start_date + INTERVAL '1 year';
        ELSE
            -- Default to monthly if billing cycle is not recognized
            v_end_date := v_start_date + INTERVAL '1 month';
            v_next_billing_date := v_start_date + INTERVAL '1 month';
    END CASE;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Subscription dates calculated',
        jsonb_build_object(
            'step', v_step,
            'start_date', v_start_date,
            'end_date', v_end_date,
            'next_billing_date', v_next_billing_date,
            'billing_cycle', v_payment_plan_record.billing_cycle
        )
    );

    v_step := 'creating_payment';
    -- Create payment record
    INSERT INTO payments (
        student_id, classroom_id, payment_plan_id, amount, 
        payment_method, status, created_at, updated_at
    ) VALUES (
        p_student_id, p_classroom_id, p_payment_plan_id, p_amount_paid,
        'simulation', 'completed', now(), now()
    ) RETURNING id INTO v_payment_id;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Payment record created successfully',
        jsonb_build_object('step', v_step, 'payment_id', v_payment_id, 'amount', p_amount_paid)
    );

    v_step := 'creating_enrollment';
    -- Create enrollment record with subscription dates
    INSERT INTO student_enrollments (
        student_id, classroom_id, payment_plan_id, status,
        enrollment_date, start_date, end_date, next_billing_date,
        auto_renew, created_at, updated_at
    ) VALUES (
        p_student_id, p_classroom_id, p_payment_plan_id, 'active',
        now(), v_start_date, v_end_date, v_next_billing_date,
        true, now(), now()
    ) RETURNING id INTO v_enrollment_id;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Student enrollment record created successfully',
        jsonb_build_object('step', v_step, 'enrollment_id', v_enrollment_id)
    );

    v_step := 'updating_classroom_count';
    -- Update classroom student count
    UPDATE classrooms 
    SET current_students = current_students + 1,
        updated_at = now()
    WHERE id = p_classroom_id;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Classroom student count updated',
        jsonb_build_object('step', v_step, 'classroom_id', p_classroom_id)
    );

    v_step := 'logging_audit_event';
    -- Log audit event for enrollment
    PERFORM log_audit_event(
        p_user_id := (SELECT user_id FROM students WHERE id = p_student_id),
        p_action_type := 'student_enrollment_created',
        p_table_name := 'student_enrollments',
        p_record_id := v_enrollment_id,
        p_new_values := jsonb_build_object(
            'student_id', p_student_id,
            'classroom_id', p_classroom_id,
            'payment_plan_id', p_payment_plan_id,
            'amount_paid', p_amount_paid,
            'end_date', v_end_date
        ),
        p_description := 'Student enrolled in classroom: ' || v_classroom_record.name,
        p_severity := 'info',
        p_tags := ARRAY['enrollment', 'payment', 'student'],
        p_metadata := jsonb_build_object(
            'payment_id', v_payment_id,
            'billing_cycle', v_payment_plan_record.billing_cycle,
            'classroom_name', v_classroom_record.name
        )
    );

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Enrollment function completed successfully',
        jsonb_build_object(
            'step', 'function_success',
            'enrollment_id', v_enrollment_id,
            'payment_id', v_payment_id,
            'success', true
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'enrollment_id', v_enrollment_id,
        'payment_id', v_payment_id,
        'start_date', v_start_date,
        'end_date', v_end_date,
        'next_billing_date', v_next_billing_date,
        'billing_cycle', v_payment_plan_record.billing_cycle,
        'message', 'Student enrolled successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Enrollment function failed with exception',
            SQLERRM,
            jsonb_build_object(
                'error_state', SQLSTATE,
                'current_step', v_step,
                'parameters', jsonb_build_object(
                    'p_student_id', p_student_id,
                    'p_classroom_id', p_classroom_id,
                    'p_payment_plan_id', p_payment_plan_id,
                    'p_amount_paid', p_amount_paid
                )
            )
        );
        RETURN jsonb_build_object('success', false, 'error', SQLERRM, 'step', v_step);
END;


### get_enrollment_logs


BEGIN
    RETURN QUERY
    SELECT 
        tl.id,
        tl.event_time,
        tl.message,
        tl.error_message,
        tl.metadata
    FROM trigger_logs tl
    WHERE tl.message ILIKE '%enrollment%' OR tl.error_message ILIKE '%enrollment%'
    ORDER BY tl.event_time DESC
    LIMIT p_limit;
END;


### get_student_classrooms


BEGIN
    RETURN QUERY
    SELECT 
        c.id as classroom_id,
        c.name as classroom_name,
        c.subject,
        c.grade_level,
        COALESCE(t_user.first_name || ' ' || t_user.last_name, 'No Teacher Assigned') as teacher_name,
        se.status::text as enrollment_status,
        se.enrollment_date,
        se.start_date,
        se.end_date,
        se.next_billing_date,
        se.auto_renew,
        se.progress,
        cp.price,
        pp.billing_cycle,
        CASE WHEN se.end_date < now() THEN true ELSE false END as is_expired
    FROM public.student_enrollments se
    JOIN public.classrooms c ON se.classroom_id = c.id
    LEFT JOIN public.teachers t ON c.teacher_id = t.id
    LEFT JOIN public.users t_user ON t.user_id = t_user.id
    JOIN public.classroom_pricing cp ON c.id = cp.classroom_id AND se.payment_plan_id = cp.payment_plan_id
    JOIN public.payment_plans pp ON se.payment_plan_id = pp.id
    WHERE se.student_id = p_student_id
    ORDER BY se.enrollment_date DESC;
END;


### get_user_audit_history


BEGIN
    RETURN QUERY
    SELECT 
        al.id,
        al.action_type,
        al.table_name,
        al.description,
        al.severity,
        al.ip_address,
        al.created_at,
        al.metadata
    FROM public.audit_logs al
    WHERE al.user_id = p_user_id
      AND (p_action_filter IS NULL OR al.action_type = p_action_filter)
      AND (p_severity_filter IS NULL OR al.severity = p_severity_filter)
    ORDER BY al.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;


### handle_new_user_signup



DECLARE
    user_type_val text;
    student_id_val text;
    teacher_id_val text;
BEGIN
    -- Log the trigger execution
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES ('handle_new_user_signup triggered', jsonb_build_object('user_id', NEW.id, 'email', NEW.email));

    -- Get user type from raw_user_meta_data
    user_type_val := COALESCE(NEW.raw_user_meta_data->>'user_type', 'student');
    
    -- Block teacher registration for security
    IF user_type_val = 'teacher' THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES ('Teacher registration blocked', 'Teachers must be created by admin', jsonb_build_object('user_id', NEW.id, 'email', NEW.email));
        
        RAISE EXCEPTION 'Teacher registration is not allowed. Teachers must be created by an administrator.';
    END IF;

    -- Update users table with proper user_type
    UPDATE auth.users 
    SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('user_type', user_type_val)
    WHERE id = NEW.id;

    -- Insert into public.users table
    INSERT INTO public.users (
        id, email, user_type, first_name, last_name, 
        email_confirmed_at, created_at, updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        user_type_val::public.user_type,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'Unknown'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
        NEW.email_confirmed_at,
        NEW.created_at,
        NEW.updated_at
    );

    -- Create student record if user_type is student
    IF user_type_val = 'student' THEN
        student_id_val := 'STU' || to_char(now(), 'YYYYMMDD') || substr(NEW.id::text, 1, 6);
        
        INSERT INTO public.students (
            user_id, 
            student_id, 
            grade_level,
            board,
            status,
            created_at, 
            updated_at
        ) VALUES (
            NEW.id, 
            student_id_val, 
            (NEW.raw_user_meta_data->>'grade_level')::integer,
            NEW.raw_user_meta_data->>'board',
            'active',
            now(), 
            now()
        );
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES ('Student record created', jsonb_build_object('user_id', NEW.id, 'student_id', student_id_val));
    END IF;

    -- Log successful completion
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES ('User signup completed successfully', jsonb_build_object('user_id', NEW.id, 'user_type', user_type_val));

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES ('Error in handle_new_user_signup', SQLERRM, jsonb_build_object('user_id', NEW.id, 'email', NEW.email));
        RAISE;
END;


### log_audit_event



DECLARE
    v_audit_id uuid;
    v_user_type_val public.user_type;
BEGIN
    -- Get user type if user_id is provided
    IF p_user_id IS NOT NULL THEN
        SELECT user_type INTO v_user_type_val FROM public.users WHERE id = p_user_id;
    END IF;
    
    -- Insert audit log
    INSERT INTO public.audit_logs (
        user_id, user_type, action_type, table_name, record_id,
        old_values, new_values, description, ip_address, user_agent,
        session_id, request_id, severity, tags, metadata, created_at
    ) VALUES (
        p_user_id, v_user_type_val, p_action_type, p_table_name, p_record_id,
        p_old_values, p_new_values, p_description, p_ip_address, p_user_agent,
        p_session_id, p_request_id, p_severity, p_tags, p_metadata, now()
    ) RETURNING id INTO v_audit_id;
    
    RETURN v_audit_id;
    
EXCEPTION
    WHEN OTHERS THEN
        -- If audit logging fails, log to trigger_logs instead
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES ('Audit logging failed', SQLERRM, jsonb_build_object('action_type', p_action_type, 'table_name', p_table_name));
        RETURN NULL;
END;


### renew_student_enrollment



DECLARE
    v_enrollment_record public.student_enrollments%ROWTYPE;
    v_payment_plan_record public.payment_plans%ROWTYPE;
    v_new_end_date timestamp with time zone;
    v_new_next_billing_date timestamp with time zone;
BEGIN
    -- Get enrollment record
    SELECT * INTO v_enrollment_record FROM public.student_enrollments WHERE id = p_enrollment_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Enrollment not found');
    END IF;
    
    -- Get payment plan
    SELECT * INTO v_payment_plan_record FROM public.payment_plans WHERE id = v_enrollment_record.payment_plan_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Payment plan not found');
    END IF;
    
    -- Calculate new subscription dates based on current end_date or now (whichever is later)
    CASE v_payment_plan_record.billing_cycle
        WHEN 'monthly' THEN
            v_new_end_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 month';
            v_new_next_billing_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 month';
        WHEN 'quarterly' THEN
            v_new_end_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '3 months';
            v_new_next_billing_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '3 months';
        WHEN 'yearly' THEN
            v_new_end_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 year';
            v_new_next_billing_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 year';
        ELSE
            v_new_end_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 month';
            v_new_next_billing_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 month';
    END CASE;
    
    -- Update enrollment with new dates and active status
    UPDATE public.student_enrollments 
    SET status = 'active',
        end_date = v_new_end_date,
        next_billing_date = v_new_next_billing_date,
        updated_at = now()
    WHERE id = p_enrollment_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'enrollment_id', p_enrollment_id,
        'new_end_date', v_new_end_date,
        'new_next_billing_date', v_new_next_billing_date,
        'message', 'Enrollment renewed successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;


### update_expired_enrollments



DECLARE
    v_updated_count integer := 0;
BEGIN
    -- Update enrollments that have passed their end_date to 'cancelled' status
    UPDATE public.student_enrollments 
    SET status = 'cancelled',
        updated_at = now()
    WHERE end_date < now() 
      AND status = 'active';
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    -- Log the operation
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES ('Expired enrollments updated', jsonb_build_object('updated_count', v_updated_count));
    
    RETURN jsonb_build_object(
        'success', true,
        'updated_count', v_updated_count,
        'message', 'Expired enrollments updated successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message)
        VALUES ('Error updating expired enrollments', SQLERRM);
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
