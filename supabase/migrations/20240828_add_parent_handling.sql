-- 1. Create the 'parents' table
CREATE TABLE IF NOT EXISTS public.parents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    parent_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Drop the existing trigger and function to update them
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Recreate the function with updated logic for parents
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_user_type public.user_type;
  v_grade_level integer;
  v_board text;
  v_subject text;
BEGIN
    -- Insert into public.users first
    INSERT INTO public.users (id, email, user_type, first_name, last_name, is_active, email_verified)
    VALUES (
        NEW.id,
        NEW.email,
        (NEW.raw_user_meta_data->>'user_type')::public.user_type,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'New'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
        true,
        false
    );

    -- Create a user profile for all new users
    INSERT INTO public.user_profiles (user_id) VALUES (NEW.id);

    -- Handle role-specific logic
    v_user_type := (NEW.raw_user_meta_data->>'user_type')::public.user_type;

    IF v_user_type = 'student' THEN
        v_grade_level := (NEW.raw_user_meta_data->>'grade_level')::integer;
        v_board := NEW.raw_user_meta_data->>'board';
        INSERT INTO public.students (user_id, student_id, grade_level, board)
        VALUES (NEW.id, 'STU-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)), v_grade_level, v_board);

    ELSIF v_user_type = 'teacher' THEN
        v_subject := NEW.raw_user_meta_data->>'subject';
        INSERT INTO public.teachers (user_id, teacher_id, subject)
        VALUES (NEW.id, 'TCH-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)), v_subject);

    ELSIF v_user_type = 'parent' THEN
        INSERT INTO public.parents (user_id, parent_id)
        VALUES (NEW.id, 'PAR-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)));
    END IF;
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    INSERT INTO public.trigger_logs (message, error_message, metadata)
    VALUES (
        'Error in handle_new_user trigger',
        SQLERRM,
        jsonb_build_object('error_context', SQLSTATE, 'user_email', NEW.email, 'raw_meta', NEW.raw_user_meta_data)
    );
    RAISE EXCEPTION 'Error processing new user: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recreate the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
