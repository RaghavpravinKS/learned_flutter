-- Migration: Add detailed logging to enroll_student_with_payment function
-- Created: 2025-09-19

-- Drop existing function first to avoid conflicts
DROP FUNCTION IF EXISTS get_enrollment_logs(integer);
DROP FUNCTION IF EXISTS enroll_student_with_payment(uuid, text, text, numeric);

-- First, let's modify the enroll_student_with_payment function to add comprehensive logging
-- Using the existing trigger_logs table structure: id, event_time, message, error_message, metadata
CREATE OR REPLACE FUNCTION enroll_student_with_payment(
    p_student_id uuid,
    p_classroom_id text,
    p_payment_plan_id text,
    p_amount_paid numeric
)
RETURNS jsonb AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to easily query enrollment logs
CREATE OR REPLACE FUNCTION get_enrollment_logs(
    p_limit integer DEFAULT 50
)
RETURNS TABLE (
    id integer,
    event_time timestamp with time zone,
    message text,
    error_message text,
    metadata jsonb
) AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;