-- Drop the existing trigger and function to apply a more robust fix.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Recreate the function using explicit IF NOT EXISTS checks instead of ON CONFLICT.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_user_type public.user_type;
  v_grade_level integer;
  v_board text;
  v_subject text;
BEGIN
    -- Step 1: Insert into public.users if the user doesn't already exist.
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = NEW.id) THEN
        INSERT INTO public.users (
            id, email, user_type, first_name, last_name, password_hash, is_active, email_verified
        ) VALUES (
            NEW.id, NEW.email, (NEW.raw_user_meta_data->>'user_type')::public.user_type,
            COALESCE(NEW.raw_user_meta_data->>'first_name', 'New'),
            COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
            NEW.encrypted_password, true, false
        );
    END IF;

    -- Step 2: Insert into user_profiles if a profile doesn't already exist.
    IF NOT EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = NEW.id) THEN
        INSERT INTO public.user_profiles (user_id) VALUES (NEW.id);
    END IF;

    -- Step 3: Handle role-specific logic.
    v_user_type := (NEW.raw_user_meta_data->>'user_type')::public.user_type;

    IF v_user_type = 'student' THEN
        IF NOT EXISTS (SELECT 1 FROM public.students WHERE user_id = NEW.id) THEN
            v_grade_level := (NEW.raw_user_meta_data->>'grade_level')::integer;
            v_board := NEW.raw_user_meta_data->>'board';
            INSERT INTO public.students (user_id, student_id, grade_level, board)
            VALUES (NEW.id, 'STU-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)), v_grade_level, v_board);
        END IF;

    ELSIF v_user_type = 'teacher' THEN
        IF NOT EXISTS (SELECT 1 FROM public.teachers WHERE user_id = NEW.id) THEN
            v_subject := NEW.raw_user_meta_data->>'subject';
            INSERT INTO public.teachers (user_id, teacher_id, subject)
            VALUES (NEW.id, 'TCH-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)), v_subject);
        END IF;

    ELSIF v_user_type = 'parent' THEN
        IF NOT EXISTS (SELECT 1 FROM public.parents WHERE user_id = NEW.id) THEN
            INSERT INTO public.parents (user_id, parent_id)
            VALUES (NEW.id, 'PAR-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)));
        END IF;
    END IF;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    INSERT INTO public.trigger_logs (message, error_message, metadata)
    VALUES (
        'Critical error in handle_new_user trigger',
        SQLERRM,
        jsonb_build_object('error_context', SQLSTATE, 'user_email', NEW.email, 'raw_meta', NEW.raw_user_meta_data)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
