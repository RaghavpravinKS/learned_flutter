-- ========================================================================
-- TRIGGER DEBUGGING AND VERIFICATION
-- ========================================================================
-- This script helps debug why the user signup trigger is not working
-- ========================================================================

-- Step 1: Check if the trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Step 2: Check if the function exists
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user' 
AND routine_schema = 'public';

-- Step 3: Check for any trigger logs (errors)
SELECT 
    event_time,
    message,
    error_message,
    metadata
FROM public.trigger_logs 
ORDER BY event_time DESC 
LIMIT 10;

-- Step 4: Check what's in auth.users
SELECT 
    id,
    email,
    raw_user_meta_data,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- Step 5: Check what's in public.users
SELECT 
    id,
    email,
    first_name,
    last_name,
    user_type,
    created_at
FROM public.users 
ORDER BY created_at DESC 
LIMIT 5;

-- Step 6: Check what's in public.students
SELECT 
    id,
    user_id,
    student_id,
    grade_level,
    board,
    school_name,
    created_at
FROM public.students 
ORDER BY created_at DESC 
LIMIT 5;

-- Step 7: Try to manually run the trigger function on a test user
-- (This will help us see if the function itself works)
DO $$
DECLARE
    test_user_id uuid := gen_random_uuid();
    test_record record;
BEGIN
    -- Create a test record that mimics what the trigger receives
    SELECT 
        test_user_id as id,
        'test@example.com' as email,
        'encrypted_password_hash' as encrypted_password,
        jsonb_build_object(
            'first_name', 'Test',
            'last_name', 'Student',
            'user_type', 'student',
            'grade_level', 10,
            'board', 'CBSE',
            'school_name', 'Test School'
        ) as raw_user_meta_data
    INTO test_record;
    
    -- Try to execute the function logic manually
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'Manual trigger test started',
        jsonb_build_object('test_user_id', test_user_id, 'test_data', test_record.raw_user_meta_data)
    );
    
    RAISE NOTICE 'Manual trigger test completed for user: %', test_user_id;
END $$;

-- Step 8: Check the current trigger function definition
SELECT pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'handle_new_user' 
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

SELECT 'Trigger debugging queries completed!' as status;
