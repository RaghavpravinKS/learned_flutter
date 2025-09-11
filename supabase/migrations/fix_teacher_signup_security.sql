-- ==================================================
-- URGENT: UPDATE SIGNUP TRIGGER TO PREVENT TEACHER SELF-SIGNUP
-- This update ensures only students and parents can self-register
-- ==================================================

CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER AS $$
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

    -- Extract user type as text first
    v_user_type := NEW.raw_user_meta_data->>'user_type';
    
    -- SECURITY CHECK: Prevent teacher self-signup
    IF v_user_type = 'teacher' THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'BLOCKED: Teacher self-signup attempt',
            'Teachers can only be created by admins',
            jsonb_build_object(
                'attempted_email', NEW.email,
                'user_id', NEW.id,
                'blocked_at', NOW()
            )
        );
        -- Block the signup by raising an exception
        RAISE EXCEPTION 'Teacher accounts can only be created by administrators. Please contact support.';
    END IF;

    -- Check if the user already exists in the public.users table
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = NEW.id) INTO user_exists;

    -- If the user does not exist, insert them
    IF NOT user_exists THEN
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
    -- Re-raise the exception to prevent user creation
    RAISE;
END;
$$ LANGUAGE plpgsql;
