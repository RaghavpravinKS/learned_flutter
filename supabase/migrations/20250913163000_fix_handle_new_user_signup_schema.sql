-- Fix for "trigger_logs does not exist" error during user signup
-- This migration updates the handle_new_user_signup function to explicitly reference the public schema.

CREATE OR REPLACE FUNCTION public.handle_new_user_signup()
RETURNS TRIGGER AS $$
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
        user_type_val::user_type,
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
            user_id, student_id, created_at, updated_at
        ) VALUES (
            NEW.id, student_id_val, now(), now()
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
