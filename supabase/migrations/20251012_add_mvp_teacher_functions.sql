-- =============================================
-- MVP TEACHER FUNCTIONS - ASSIGNMENTS & LEARNING MATERIALS
-- Created: October 12, 2025
-- Purpose: Core teacher functionality for MVP
-- =============================================

-- =============================================
-- ASSIGNMENT & ASSESSMENT FUNCTIONS
-- =============================================

-- Function: Create Assignment
CREATE OR REPLACE FUNCTION create_assignment(
    p_teacher_id UUID,
    p_classroom_id UUID,
    p_title VARCHAR,
    p_description TEXT,
    p_due_date TIMESTAMPTZ,
    p_total_points INTEGER DEFAULT 100,
    p_instructions TEXT DEFAULT NULL,
    p_assignment_type VARCHAR DEFAULT 'homework',
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_assignment_id UUID;
    v_teacher_record teachers%ROWTYPE;
    v_classroom_record classrooms%ROWTYPE;
BEGIN
    -- Log function start
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'create_assignment function started',
        jsonb_build_object(
            'function_name', 'create_assignment',
            'teacher_id', p_teacher_id,
            'classroom_id', p_classroom_id,
            'title', p_title,
            'user_id', auth.uid()
        )
    );

    -- Validate teacher exists and is active
    SELECT * INTO v_teacher_record FROM public.teachers 
    WHERE id = p_teacher_id AND status = 'active';
    
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'create_assignment failed - teacher validation',
            'Teacher not found or not active',
            jsonb_build_object('teacher_id', p_teacher_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Teacher not found or not active');
    END IF;

    -- Validate classroom exists and belongs to teacher
    SELECT * INTO v_classroom_record FROM public.classrooms 
    WHERE id = p_classroom_id AND teacher_id = p_teacher_id;
    
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'create_assignment failed - classroom validation',
            'Classroom not found or not assigned to teacher',
            jsonb_build_object('teacher_id', p_teacher_id, 'classroom_id', p_classroom_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Classroom not found or not assigned to teacher');
    END IF;

    -- Create assignment record
    INSERT INTO public.assignments (
        classroom_id, teacher_id, title, description, due_date,
        total_points, instructions, assignment_type, status,
        created_at, updated_at
    ) VALUES (
        p_classroom_id, p_teacher_id, p_title, p_description, p_due_date,
        p_total_points, p_instructions, p_assignment_type, 'active',
        now(), now()
    ) RETURNING id INTO v_assignment_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        p_user_id := v_teacher_record.user_id,
        p_action_type := 'assignment_created',
        p_table_name := 'assignments',
        p_record_id := v_assignment_id,
        p_new_values := jsonb_build_object(
            'assignment_id', v_assignment_id,
            'classroom_id', p_classroom_id,
            'title', p_title,
            'due_date', p_due_date,
            'total_points', p_total_points,
            'assignment_type', p_assignment_type
        ),
        p_description := 'Teacher created assignment: ' || p_title || ' for classroom: ' || v_classroom_record.name,
        p_severity := 'info',
        p_tags := ARRAY['assignment', 'teacher', 'classroom'],
        p_metadata := p_metadata
    );

    -- Log success
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'Assignment created successfully',
        jsonb_build_object(
            'assignment_id', v_assignment_id,
            'teacher_id', p_teacher_id,
            'classroom_id', p_classroom_id,
            'title', p_title
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'assignment_id', v_assignment_id,
        'title', p_title,
        'due_date', p_due_date,
        'message', 'Assignment created successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'create_assignment function failed with exception',
            SQLERRM,
            jsonb_build_object(
                'error_state', SQLSTATE,
                'teacher_id', p_teacher_id,
                'classroom_id', p_classroom_id,
                'title', p_title
            )
        );
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Function: Get Teacher Assignments
CREATE OR REPLACE FUNCTION get_teacher_assignments(
    p_teacher_id UUID,
    p_classroom_id UUID DEFAULT NULL
) RETURNS TABLE(
    assignment_id UUID,
    classroom_id VARCHAR,
    classroom_name VARCHAR,
    title VARCHAR,
    description TEXT,
    due_date TIMESTAMPTZ,
    total_points INTEGER,
    assignment_type VARCHAR,
    status VARCHAR,
    created_at TIMESTAMPTZ,
    total_submissions BIGINT,
    graded_submissions BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    -- Log function start
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'get_teacher_assignments function started',
        jsonb_build_object(
            'teacher_id', p_teacher_id,
            'classroom_id', p_classroom_id,
            'user_id', auth.uid()
        )
    );

    RETURN QUERY
    SELECT 
        a.id as assignment_id,
        a.classroom_id,
        c.name as classroom_name,
        a.title,
        a.description,
        a.due_date,
        a.total_points,
        a.assignment_type,
        a.status,
        a.created_at,
        COUNT(saa.id) as total_submissions,
        COUNT(CASE WHEN saa.status = 'graded' THEN 1 END) as graded_submissions
    FROM public.assignments a
    JOIN public.classrooms c ON a.classroom_id = c.id
    LEFT JOIN public.student_assignment_attempts saa ON a.id = saa.assignment_id
    WHERE a.teacher_id = p_teacher_id
      AND (p_classroom_id IS NULL OR a.classroom_id = p_classroom_id)
    GROUP BY a.id, c.name
    ORDER BY a.created_at DESC;

    -- Log success
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'get_teacher_assignments completed successfully',
        jsonb_build_object('teacher_id', p_teacher_id)
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'get_teacher_assignments function failed',
            SQLERRM,
            jsonb_build_object('teacher_id', p_teacher_id)
        );
        RAISE;
END;
$$;

-- Function: Submit Assignment Attempt
CREATE OR REPLACE FUNCTION submit_assignment_attempt(
    p_student_id UUID,
    p_assignment_id UUID,
    p_submission_text TEXT DEFAULT NULL,
    p_attachment_urls TEXT[] DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_attempt_id UUID;
    v_student_record students%ROWTYPE;
    v_assignment_record assignments%ROWTYPE;
    v_existing_attempt_id UUID;
BEGIN
    -- Log function start
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'submit_assignment_attempt function started',
        jsonb_build_object(
            'student_id', p_student_id,
            'assignment_id', p_assignment_id,
            'user_id', auth.uid()
        )
    );

    -- Validate student exists
    SELECT * INTO v_student_record FROM public.students WHERE id = p_student_id;
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'submit_assignment_attempt failed - student validation',
            'Student not found',
            jsonb_build_object('student_id', p_student_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Student not found');
    END IF;

    -- Validate assignment exists
    SELECT * INTO v_assignment_record FROM public.assignments WHERE id = p_assignment_id;
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'submit_assignment_attempt failed - assignment validation',
            'Assignment not found',
            jsonb_build_object('assignment_id', p_assignment_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Assignment not found');
    END IF;

    -- Check if student is enrolled in the classroom
    IF NOT EXISTS (
        SELECT 1 FROM public.student_enrollments 
        WHERE student_id = p_student_id 
        AND classroom_id = v_assignment_record.classroom_id 
        AND status = 'active'
    ) THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'submit_assignment_attempt failed - enrollment validation',
            'Student not enrolled in classroom',
            jsonb_build_object('student_id', p_student_id, 'classroom_id', v_assignment_record.classroom_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Student not enrolled in this classroom');
    END IF;

    -- Check if assignment is past due (optional warning, not blocking)
    IF v_assignment_record.due_date < now() THEN
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES (
            'Late assignment submission detected',
            jsonb_build_object(
                'student_id', p_student_id,
                'assignment_id', p_assignment_id,
                'due_date', v_assignment_record.due_date,
                'submission_time', now()
            )
        );
    END IF;

    -- Check for existing attempt
    SELECT id INTO v_existing_attempt_id 
    FROM public.student_assignment_attempts 
    WHERE student_id = p_student_id AND assignment_id = p_assignment_id;

    IF v_existing_attempt_id IS NOT NULL THEN
        -- Update existing attempt
        UPDATE public.student_assignment_attempts 
        SET submission_text = p_submission_text,
            attachment_urls = p_attachment_urls,
            status = 'submitted',
            submitted_at = now(),
            updated_at = now()
        WHERE id = v_existing_attempt_id;
        
        v_attempt_id := v_existing_attempt_id;
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES (
            'Assignment attempt updated',
            jsonb_build_object('attempt_id', v_attempt_id, 'student_id', p_student_id)
        );
    ELSE
        -- Create new attempt
        INSERT INTO public.student_assignment_attempts (
            student_id, assignment_id, submission_text, attachment_urls,
            status, submitted_at, created_at, updated_at
        ) VALUES (
            p_student_id, p_assignment_id, p_submission_text, p_attachment_urls,
            'submitted', now(), now(), now()
        ) RETURNING id INTO v_attempt_id;
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES (
            'New assignment attempt created',
            jsonb_build_object('attempt_id', v_attempt_id, 'student_id', p_student_id)
        );
    END IF;

    -- Log audit event
    PERFORM public.log_audit_event(
        p_user_id := v_student_record.user_id,
        p_action_type := 'assignment_submitted',
        p_table_name := 'student_assignment_attempts',
        p_record_id := v_attempt_id,
        p_new_values := jsonb_build_object(
            'attempt_id', v_attempt_id,
            'assignment_id', p_assignment_id,
            'submission_status', 'submitted',
            'submitted_at', now()
        ),
        p_description := 'Student submitted assignment: ' || v_assignment_record.title,
        p_severity := 'info',
        p_tags := ARRAY['assignment', 'student', 'submission'],
        p_metadata := p_metadata
    );

    RETURN jsonb_build_object(
        'success', true,
        'attempt_id', v_attempt_id,
        'assignment_id', p_assignment_id,
        'status', 'submitted',
        'submitted_at', now(),
        'message', 'Assignment submitted successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'submit_assignment_attempt function failed',
            SQLERRM,
            jsonb_build_object(
                'student_id', p_student_id,
                'assignment_id', p_assignment_id
            )
        );
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Function: Grade Assignment
CREATE OR REPLACE FUNCTION grade_assignment(
    p_teacher_id UUID,
    p_attempt_id UUID,
    p_score NUMERIC,
    p_feedback TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_attempt_record student_assignment_attempts%ROWTYPE;
    v_assignment_record assignments%ROWTYPE;
    v_teacher_record teachers%ROWTYPE;
    v_student_record students%ROWTYPE;
BEGIN
    -- Log function start
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'grade_assignment function started',
        jsonb_build_object(
            'teacher_id', p_teacher_id,
            'attempt_id', p_attempt_id,
            'score', p_score,
            'user_id', auth.uid()
        )
    );

    -- Validate teacher
    SELECT * INTO v_teacher_record FROM public.teachers WHERE id = p_teacher_id;
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'grade_assignment failed - teacher validation',
            'Teacher not found',
            jsonb_build_object('teacher_id', p_teacher_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Teacher not found');
    END IF;

    -- Get attempt record
    SELECT * INTO v_attempt_record FROM public.student_assignment_attempts WHERE id = p_attempt_id;
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'grade_assignment failed - attempt validation',
            'Assignment attempt not found',
            jsonb_build_object('attempt_id', p_attempt_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Assignment attempt not found');
    END IF;

    -- Get assignment record
    SELECT * INTO v_assignment_record FROM public.assignments WHERE id = v_attempt_record.assignment_id;
    IF NOT FOUND OR v_assignment_record.teacher_id != p_teacher_id THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'grade_assignment failed - authorization',
            'Teacher not authorized to grade this assignment',
            jsonb_build_object('teacher_id', p_teacher_id, 'assignment_teacher_id', v_assignment_record.teacher_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Not authorized to grade this assignment');
    END IF;

    -- Validate score range
    IF p_score < 0 OR p_score > v_assignment_record.total_points THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'grade_assignment failed - score validation',
            'Score out of valid range',
            jsonb_build_object('score', p_score, 'max_points', v_assignment_record.total_points)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Score must be between 0 and ' || v_assignment_record.total_points);
    END IF;

    -- Update attempt with grade
    UPDATE public.student_assignment_attempts 
    SET score = p_score,
        feedback = p_feedback,
        status = 'graded',
        graded_at = now(),
        graded_by = p_teacher_id,
        updated_at = now()
    WHERE id = p_attempt_id;

    -- Get student record for audit logging
    SELECT * INTO v_student_record FROM public.students WHERE id = v_attempt_record.student_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        p_user_id := v_teacher_record.user_id,
        p_action_type := 'assignment_graded',
        p_table_name := 'student_assignment_attempts',
        p_record_id := p_attempt_id,
        p_new_values := jsonb_build_object(
            'attempt_id', p_attempt_id,
            'score', p_score,
            'total_points', v_assignment_record.total_points,
            'percentage', (p_score / v_assignment_record.total_points * 100),
            'graded_at', now()
        ),
        p_description := 'Teacher graded assignment: ' || v_assignment_record.title || ' for student: ' || v_student_record.student_id,
        p_severity := 'info',
        p_tags := ARRAY['assignment', 'teacher', 'grading'],
        p_metadata := p_metadata
    );

    -- Log success
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'Assignment graded successfully',
        jsonb_build_object(
            'attempt_id', p_attempt_id,
            'teacher_id', p_teacher_id,
            'score', p_score,
            'percentage', (p_score / v_assignment_record.total_points * 100)
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'attempt_id', p_attempt_id,
        'score', p_score,
        'total_points', v_assignment_record.total_points,
        'percentage', (p_score / v_assignment_record.total_points * 100),
        'graded_at', now(),
        'message', 'Assignment graded successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'grade_assignment function failed',
            SQLERRM,
            jsonb_build_object(
                'teacher_id', p_teacher_id,
                'attempt_id', p_attempt_id
            )
        );
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- =============================================
-- LEARNING MATERIALS FUNCTIONS
-- =============================================

-- Function: Upload Learning Material
CREATE OR REPLACE FUNCTION upload_learning_material(
    p_teacher_id UUID,
    p_classroom_id UUID,
    p_title VARCHAR,
    p_file_url TEXT,
    p_file_type VARCHAR,
    p_description TEXT DEFAULT NULL,
    p_file_size BIGINT DEFAULT NULL,
    p_material_type VARCHAR DEFAULT 'document',
    p_is_public BOOLEAN DEFAULT false,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_material_id UUID;
    v_teacher_record teachers%ROWTYPE;
    v_classroom_record classrooms%ROWTYPE;
BEGIN
    -- Log function start
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'upload_learning_material function started',
        jsonb_build_object(
            'teacher_id', p_teacher_id,
            'classroom_id', p_classroom_id,
            'title', p_title,
            'material_type', p_material_type,
            'user_id', auth.uid()
        )
    );

    -- Validate teacher
    SELECT * INTO v_teacher_record FROM public.teachers 
    WHERE id = p_teacher_id AND status = 'active';
    
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'upload_learning_material failed - teacher validation',
            'Teacher not found or not active',
            jsonb_build_object('teacher_id', p_teacher_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Teacher not found or not active');
    END IF;

    -- Validate classroom belongs to teacher
    SELECT * INTO v_classroom_record FROM public.classrooms 
    WHERE id = p_classroom_id AND teacher_id = p_teacher_id;
    
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'upload_learning_material failed - classroom validation',
            'Classroom not found or not assigned to teacher',
            jsonb_build_object('teacher_id', p_teacher_id, 'classroom_id', p_classroom_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Classroom not found or not assigned to teacher');
    END IF;

    -- Create learning material record
    INSERT INTO public.learning_materials (
        classroom_id, teacher_id, title, description, file_url,
        file_type, file_size, material_type, is_public,
        created_at, updated_at
    ) VALUES (
        p_classroom_id, p_teacher_id, p_title, p_description, p_file_url,
        p_file_type, p_file_size, p_material_type, p_is_public,
        now(), now()
    ) RETURNING id INTO v_material_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        p_user_id := v_teacher_record.user_id,
        p_action_type := 'learning_material_uploaded',
        p_table_name := 'learning_materials',
        p_record_id := v_material_id,
        p_new_values := jsonb_build_object(
            'material_id', v_material_id,
            'classroom_id', p_classroom_id,
            'title', p_title,
            'material_type', p_material_type,
            'file_type', p_file_type,
            'file_size', p_file_size,
            'is_public', p_is_public
        ),
        p_description := 'Teacher uploaded learning material: ' || p_title || ' for classroom: ' || v_classroom_record.name,
        p_severity := 'info',
        p_tags := ARRAY['learning_material', 'teacher', 'upload'],
        p_metadata := p_metadata
    );

    -- Log success
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'Learning material uploaded successfully',
        jsonb_build_object(
            'material_id', v_material_id,
            'teacher_id', p_teacher_id,
            'classroom_id', p_classroom_id,
            'title', p_title
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'material_id', v_material_id,
        'title', p_title,
        'file_url', p_file_url,
        'material_type', p_material_type,
        'message', 'Learning material uploaded successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'upload_learning_material function failed',
            SQLERRM,
            jsonb_build_object(
                'teacher_id', p_teacher_id,
                'classroom_id', p_classroom_id,
                'title', p_title
            )
        );
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Function: Get Classroom Learning Materials
CREATE OR REPLACE FUNCTION get_classroom_materials(
    p_classroom_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_user_type VARCHAR DEFAULT NULL
) RETURNS TABLE(
    material_id UUID,
    title VARCHAR,
    description TEXT,
    file_url TEXT,
    file_type VARCHAR,
    file_size BIGINT,
    material_type VARCHAR,
    teacher_name TEXT,
    created_at TIMESTAMPTZ,
    access_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    -- Log function start
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'get_classroom_materials function started',
        jsonb_build_object(
            'classroom_id', p_classroom_id,
            'user_id', p_user_id,
            'user_type', p_user_type,
            'auth_uid', auth.uid()
        )
    );

    RETURN QUERY
    SELECT 
        lm.id as material_id,
        lm.title,
        lm.description,
        lm.file_url,
        lm.file_type,
        lm.file_size,
        lm.material_type,
        COALESCE(u.first_name || ' ' || u.last_name, 'Unknown Teacher') as teacher_name,
        lm.created_at,
        COALESCE(access_counts.access_count, 0) as access_count
    FROM public.learning_materials lm
    LEFT JOIN public.teachers t ON lm.teacher_id = t.id
    LEFT JOIN public.users u ON t.user_id = u.id
    LEFT JOIN (
        SELECT material_id, COUNT(*) as access_count 
        FROM public.student_material_access 
        GROUP BY material_id
    ) access_counts ON lm.id = access_counts.material_id
    WHERE lm.classroom_id = p_classroom_id
      AND (lm.is_public = true OR p_user_type = 'teacher' OR 
           (p_user_type = 'student' AND EXISTS (
               SELECT 1 FROM public.student_enrollments se 
               WHERE se.classroom_id = p_classroom_id 
               AND se.student_id IN (SELECT id FROM public.students WHERE user_id = p_user_id)
               AND se.status = 'active'
           ))
      )
    ORDER BY lm.created_at DESC;

    -- Log success
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'get_classroom_materials completed successfully',
        jsonb_build_object('classroom_id', p_classroom_id)
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'get_classroom_materials function failed',
            SQLERRM,
            jsonb_build_object('classroom_id', p_classroom_id)
        );
        RAISE;
END;
$$;

-- Function: Track Material Access
CREATE OR REPLACE FUNCTION track_material_access(
    p_student_id UUID,
    p_material_id UUID,
    p_access_duration INTEGER DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_student_record students%ROWTYPE;
    v_material_record learning_materials%ROWTYPE;
    v_access_id UUID;
BEGIN
    -- Log function start
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'track_material_access function started',
        jsonb_build_object(
            'student_id', p_student_id,
            'material_id', p_material_id,
            'user_id', auth.uid()
        )
    );

    -- Validate student
    SELECT * INTO v_student_record FROM public.students WHERE id = p_student_id;
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'track_material_access failed - student validation',
            'Student not found',
            jsonb_build_object('student_id', p_student_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Student not found');
    END IF;

    -- Validate material
    SELECT * INTO v_material_record FROM public.learning_materials WHERE id = p_material_id;
    IF NOT FOUND THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'track_material_access failed - material validation',
            'Learning material not found',
            jsonb_build_object('material_id', p_material_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Learning material not found');
    END IF;

    -- Check if student is enrolled in the classroom
    IF NOT EXISTS (
        SELECT 1 FROM public.student_enrollments 
        WHERE student_id = p_student_id 
        AND classroom_id = v_material_record.classroom_id 
        AND status = 'active'
    ) THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'track_material_access failed - enrollment validation',
            'Student not enrolled in classroom',
            jsonb_build_object('student_id', p_student_id, 'classroom_id', v_material_record.classroom_id)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Student not enrolled in this classroom');
    END IF;

    -- Record material access
    INSERT INTO public.student_material_access (
        student_id, material_id, access_time, access_duration,
        created_at
    ) VALUES (
        p_student_id, p_material_id, now(), p_access_duration,
        now()
    ) RETURNING id INTO v_access_id;

    -- Log audit event
    PERFORM public.log_audit_event(
        p_user_id := v_student_record.user_id,
        p_action_type := 'learning_material_accessed',
        p_table_name := 'student_material_access',
        p_record_id := v_access_id,
        p_new_values := jsonb_build_object(
            'access_id', v_access_id,
            'material_id', p_material_id,
            'access_time', now(),
            'access_duration', p_access_duration
        ),
        p_description := 'Student accessed learning material: ' || v_material_record.title,
        p_severity := 'info',
        p_tags := ARRAY['learning_material', 'student', 'access'],
        p_metadata := p_metadata
    );

    -- Log success
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'Material access tracked successfully',
        jsonb_build_object(
            'access_id', v_access_id,
            'student_id', p_student_id,
            'material_id', p_material_id
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'access_id', v_access_id,
        'material_id', p_material_id,
        'access_time', now(),
        'message', 'Material access tracked successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'track_material_access function failed',
            SQLERRM,
            jsonb_build_object(
                'student_id', p_student_id,
                'material_id', p_material_id
            )
        );
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;