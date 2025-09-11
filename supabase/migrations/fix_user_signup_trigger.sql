-- ========================================================================
-- FIXED USER SIGNUP TRIGGER - Compatible with Current Schema
-- ========================================================================
-- This fixes the user signup trigger to work with the current database schema
-- Critical for student registration flow to work properly
-- ========================================================================

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create the corrected function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_user_type public.user_type;
  v_grade_level integer;
  v_board text;
  v_school_name text;
  v_specializations text[];
  user_exists boolean := false;
BEGIN
    -- Check if the user already exists in the public.users table
    SELECT EXISTS(SELECT 1 FROM public.users WHERE id = NEW.id) INTO user_exists;

    -- If the user does not exist, insert them
    IF NOT user_exists THEN
        INSERT INTO public.users (
            id, email, user_type, first_name, last_name, password_hash, is_active, email_verified, created_at, updated_at
        ) VALUES (
            NEW.id, 
            NEW.email, 
            (NEW.raw_user_meta_data->>'user_type')::public.user_type,
            COALESCE(NEW.raw_user_meta_data->>'first_name', 'New'),
            COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
            COALESCE(NEW.encrypted_password, 'temp_hash'), -- Handle password_hash properly
            true, 
            false,
            NOW(),
            NOW()
        );
    END IF;

    -- Create a user profile
    INSERT INTO public.user_profiles (user_id, created_at, updated_at) 
    VALUES (NEW.id, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;

    -- Handle role-specific logic
    v_user_type := (NEW.raw_user_meta_data->>'user_type')::public.user_type;

    IF v_user_type = 'student' THEN
        -- Extract student-specific data
        v_grade_level := (NEW.raw_user_meta_data->>'grade_level')::integer;
        v_board := NEW.raw_user_meta_data->>'board';
        v_school_name := NEW.raw_user_meta_data->>'school_name';
        
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

    ELSIF v_user_type = 'teacher' THEN
        -- Extract teacher-specific data
        v_specializations := ARRAY[NEW.raw_user_meta_data->>'subject']; -- Convert subject to array
        
        INSERT INTO public.teachers (
            id, user_id, teacher_id, specializations, status, created_at, updated_at
        ) VALUES (
            NEW.id,
            NEW.id,
            'TCH-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)), 
            v_specializations,
            'active',
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;

    ELSIF v_user_type = 'parent' THEN
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
    END IF;
    
    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    -- Log the error for debugging
    INSERT INTO public.trigger_logs (message, error_message, metadata)
    VALUES (
        'Error in handle_new_user trigger',
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Verification: Check if trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

SELECT 'User signup trigger fixed and ready for testing!' as status;

-- ========================================================================
-- WHAT WAS FIXED:
-- ========================================================================
-- ✅ Teachers: Changed 'subject' column to 'specializations' (array)
-- ✅ Students: Added school_name column support
-- ✅ Added proper id, created_at, updated_at for all tables
-- ✅ Fixed password_hash handling
-- ✅ Added proper error logging with more context
-- ✅ Made all inserts compatible with current schema
-- ========================================================================
