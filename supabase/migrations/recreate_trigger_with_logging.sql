-- Quick trigger verification and fix
-- This will show us what's wrong and fix it

-- 1. Check if trigger exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'on_auth_user_created'
    ) THEN
        RAISE NOTICE 'Trigger EXISTS: on_auth_user_created';
    ELSE
        RAISE NOTICE 'Trigger MISSING: on_auth_user_created';
    END IF;
END $$;

-- 2. Check if function exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'handle_new_user' 
        AND routine_schema = 'public'
    ) THEN
        RAISE NOTICE 'Function EXISTS: public.handle_new_user';
    ELSE
        RAISE NOTICE 'Function MISSING: public.handle_new_user';
    END IF;
END $$;

-- 3. Show recent auth.users with metadata
SELECT 
    'Recent auth.users:' as info,
    email,
    raw_user_meta_data,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 3;

-- 4. Show recent public.users
SELECT 
    'Recent public.users:' as info,
    email,
    first_name,
    last_name,
    user_type,
    created_at
FROM public.users 
ORDER BY created_at DESC 
LIMIT 3;

-- 5. Show any trigger errors
SELECT 
    'Trigger errors:' as info,
    event_time,
    message,
    error_message
FROM public.trigger_logs 
ORDER BY event_time DESC 
LIMIT 5;

-- 6. Let's recreate the trigger if it's missing
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create the function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_user_type text;
  v_grade_level integer;
  v_board text;
  v_school_name text;
  user_exists boolean := false;
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

    -- Create a user profile
    INSERT INTO public.user_profiles (user_id, created_at, updated_at) 
    VALUES (NEW.id, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;

    -- Handle student-specific logic
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
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES ('Student record created', jsonb_build_object('user_id', NEW.id, 'grade', v_grade_level));
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

SELECT 'Trigger recreated with enhanced logging!' as status;
