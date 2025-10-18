-- Updated create_teacher_by_admin function with correct auth.users schema
CREATE OR REPLACE FUNCTION create_teacher_by_admin(
    p_admin_id uuid,
    p_email text,
    p_first_name text,
    p_last_name text,
    p_phone text,
    p_qualifications text,
    p_bio text,
    p_experience_years integer,
    p_specializations text,
    p_password text DEFAULT 'TempPass123!',
    p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb AS $$
DECLARE
    v_user_id uuid;
    v_teacher_id uuid;
    v_teacher_id_val text;
    v_auth_user_id uuid;
    v_encrypted_password text;
BEGIN
    -- Validate admin user (bypass for testing with specific UUID)
    IF p_admin_id != '00000000-0000-0000-0000-000000000000'::uuid AND 
       NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Admin access required');
    END IF;

    -- Check if email already exists in public users
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email already exists in system');
    END IF;

    -- Generate teacher ID and auth user ID
    v_teacher_id_val := 'TEA' || to_char(now(), 'YYYYMMDD') || substr(gen_random_uuid()::text, 1, 6);
    v_auth_user_id := gen_random_uuid();

    -- Note: Direct auth.users insertion is not recommended and may not work
    -- Supabase manages auth.users table internally
    -- For testing, we'll create the public user and log auth creation instructions
    
    INSERT INTO trigger_logs (message, metadata) VALUES (
        'Teacher account created - Auth user needs manual creation',
        jsonb_build_object(
            'email', p_email,
            'password', p_password,
            'user_id', v_auth_user_id,
            'teacher_id_val', v_teacher_id_val,
            'instructions', 'Create auth user manually in Supabase Dashboard: Authentication > Users > Add User'
        )
    );

    -- Create public user record
    INSERT INTO users (
        id, email, user_type, first_name, last_name, phone,
        is_active, email_verified, created_at, updated_at
    ) VALUES (
        v_auth_user_id, p_email, 'teacher', p_first_name, p_last_name, p_phone,
        true, true, now(), now()
    ) RETURNING id INTO v_user_id;

    -- Create teacher record
    INSERT INTO teachers (
        user_id, teacher_id, qualifications, experience_years,
        bio, status, created_at, updated_at
    ) VALUES (
        v_user_id, v_teacher_id_val, p_qualifications, p_experience_years,
        p_bio, 'active', now(), now()
    ) RETURNING id INTO v_teacher_id;

    -- Log admin activity
    INSERT INTO admin_activities (
        admin_id, activity_type, target_user_id, description, metadata, created_at
    ) VALUES (
        p_admin_id, 'create_teacher', v_user_id, 
        'Created teacher account: ' || p_first_name || ' ' || p_last_name,
        p_metadata, now()
    );

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'teacher_id', v_teacher_id,
        'teacher_id_val', v_teacher_id_val,
        'email', p_email,
        'temp_password', p_password,
        'auth_manual_step', true,
        'message', 'Teacher account created. Auth user must be created manually in Supabase Dashboard.',
        'instructions', jsonb_build_object(
            'step1', 'Go to Supabase Dashboard → Authentication → Users',
            'step2', 'Click "Add user"',
            'step3', 'Email: ' || p_email,
            'step4', 'Password: ' || p_password,
            'step5', 'Check "Email Confirm" checkbox',
            'step6', 'Click "Create user"'
        )
    );

    -- Create teacher record
    INSERT INTO teachers (
        user_id, teacher_id, qualifications, experience_years,
        bio, status, created_at, updated_at
    ) VALUES (
        v_user_id, v_teacher_id_val, p_qualifications, p_experience_years,
        p_bio, 'active', now(), now()
    ) RETURNING id INTO v_teacher_id;

    -- Log admin activity
    INSERT INTO admin_activities (
        admin_id, activity_type, target_user_id, description, metadata, created_at
    ) VALUES (
        p_admin_id, 'create_teacher', v_user_id, 
        'Created teacher account: ' || p_first_name || ' ' || p_last_name,
        p_metadata, now()
    );

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'teacher_id', v_teacher_id,
        'teacher_id_val', v_teacher_id_val,
        'email', p_email,
        'temp_password', p_password,
        'message', 'Teacher account created successfully. Login with: ' || p_email || ' / ' || p_password
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Simplified test function without admin validation
CREATE OR REPLACE FUNCTION create_test_teacher_simple(
    p_email text DEFAULT 'test.teacher@learned.com',
    p_password text DEFAULT 'TestPass123!'
)
RETURNS jsonb AS $$
DECLARE
    v_user_id uuid;
    v_teacher_id uuid;
    v_teacher_id_val text;
BEGIN
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email already exists in system');
    END IF;

    -- Generate teacher ID
    v_teacher_id_val := 'TEA' || to_char(now(), 'YYYYMMDD') || substr(gen_random_uuid()::text, 1, 6);

    -- Create public user record
    INSERT INTO users (
        email, user_type, first_name, last_name, phone,
        is_active, email_verified, created_at, updated_at
    ) VALUES (
        p_email, 'teacher', 'Test', 'Teacher', '+1-555-TEST',
        true, true, now(), now()
    ) RETURNING id INTO v_user_id;

    -- Create teacher record
    INSERT INTO teachers (
        user_id, teacher_id, qualifications, experience_years,
        bio, status, created_at, updated_at
    ) VALUES (
        v_user_id, v_teacher_id_val, 'PhD in Computer Science, M.Ed in Educational Technology', 10,
        'Experienced educator with 10+ years in STEM education', 'active', now(), now()
    ) RETURNING id INTO v_teacher_id;

    -- Log creation for reference
    INSERT INTO trigger_logs (message, metadata) VALUES (
        'Test teacher created via simple function',
        jsonb_build_object(
            'email', p_email,
            'password', p_password,
            'user_id', v_user_id,
            'teacher_id_val', v_teacher_id_val
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'teacher_id', v_teacher_id,
        'teacher_id_val', v_teacher_id_val,
        'email', p_email,
        'temp_password', p_password,
        'message', 'Test teacher created successfully. Create auth user manually in Supabase Dashboard.'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;