-- Drop existing trigger and function to ensure a clean update
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Recreate the function with logic to handle all user roles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_user_type public.user_type;
  v_grade_level integer;
  v_board text;
BEGIN
    -- Insert into public.users first
    INSERT INTO public.users (
        id,
        email,
        user_type,
        first_name,
        last_name,
        password_hash,
        is_active,
        email_verified
    ) VALUES (
        NEW.id,
        NEW.email,
        (NEW.raw_user_meta_data->>'user_type')::public.user_type,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'New'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
        NEW.encrypted_password,
        true,
        false
    );

    -- Create a user profile for all new users
    INSERT INTO public.user_profiles (user_id)
    VALUES (NEW.id);

    -- Handle role-specific logic
    v_user_type := (NEW.raw_user_meta_data->>'user_type')::public.user_type;

    IF v_user_type = 'student' THEN
        -- Extract grade and board from metadata
        v_grade_level := (NEW.raw_user_meta_data->>'grade_level')::integer;
        v_board := NEW.raw_user_meta_data->>'board';

        -- Insert into the students table
        INSERT INTO public.students (
            user_id,
            student_id,
            grade_level,
            board
        ) VALUES (
            NEW.id,
            'STU-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)), -- Generate a unique student ID
            v_grade_level,
            v_board
        );
    ELSIF v_user_type = 'teacher' THEN
        -- Insert into the teachers table
        INSERT INTO public.teachers (
            user_id,
            teacher_id
        ) VALUES (
            NEW.id,
            'TCH-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)) -- Generate a unique teacher ID
        );
    END IF;
    -- Note: 'parent' and 'admin' roles do not require an entry in a separate table upon registration.
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Log any errors to help with debugging
    INSERT INTO public.trigger_logs (message, error_message, metadata)
    VALUES (
        'Error in handle_new_user trigger',
        SQLERRM,
        jsonb_build_object(
            'error_context', SQLSTATE,
            'user_email', NEW.email,
            'raw_meta', NEW.raw_user_meta_data
        )
    );
    RAISE EXCEPTION 'Error processing new user: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
