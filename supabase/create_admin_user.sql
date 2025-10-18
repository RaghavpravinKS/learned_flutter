-- =============================================
-- CREATE ADMIN USER FUNCTION AND INSTRUCTIONS
-- =============================================

-- Function to create admin user (can only be called by service role or existing admin)
CREATE OR REPLACE FUNCTION create_admin_user(
    p_email text,
    p_password text,
    p_first_name text,
    p_last_name text,
    p_phone text DEFAULT NULL,
    p_created_by_admin_id uuid DEFAULT NULL
)
RETURNS jsonb AS $$
DECLARE
    v_user_id uuid;
    v_auth_user_id uuid;
BEGIN
    -- Check if this is being called by an existing admin (if p_created_by_admin_id is provided)
    IF p_created_by_admin_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_created_by_admin_id AND user_type = 'admin') THEN
            RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Only admins can create other admins');
        END IF;
    END IF;

    -- Check if user with this email already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
        RETURN jsonb_build_object('success', false, 'error', 'User with this email already exists');
    END IF;

    -- Create user in auth.users (this would normally be done via Supabase API)
    -- Note: In practice, you should use Supabase Admin API to create the auth user
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        p_email,
        crypt(p_password, gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider":"email","providers":["email"]}',
        jsonb_build_object(
            'user_type', 'admin',
            'first_name', p_first_name,
            'last_name', p_last_name
        ),
        now(),
        now(),
        '',
        '',
        '',
        ''
    ) RETURNING id INTO v_auth_user_id;

    -- Create user in public.users table
    INSERT INTO public.users (
        id,
        email,
        user_type,
        first_name,
        last_name,
        phone,
        is_active,
        email_verified,
        email_confirmed_at,
        created_at,
        updated_at
    ) VALUES (
        v_auth_user_id,
        p_email,
        'admin',
        p_first_name,
        p_last_name,
        p_phone,
        true,
        true,
        now(),
        now(),
        now()
    ) RETURNING id INTO v_user_id;

    -- Log admin creation if created by another admin
    IF p_created_by_admin_id IS NOT NULL THEN
        INSERT INTO admin_activities (
            admin_id,
            activity_type,
            target_user_id,
            description,
            metadata,
            created_at
        ) VALUES (
            p_created_by_admin_id,
            'create_admin_user',
            v_user_id,
            'Created admin user: ' || p_first_name || ' ' || p_last_name,
            jsonb_build_object(
                'created_admin_email', p_email,
                'created_admin_name', p_first_name || ' ' || p_last_name
            ),
            now()
        );
    END IF;

    -- Log in trigger_logs
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'Admin user created successfully',
        jsonb_build_object(
            'admin_email', p_email,
            'admin_name', p_first_name || ' ' || p_last_name,
            'created_by_admin', p_created_by_admin_id IS NOT NULL
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'email', p_email,
        'message', 'Admin user created successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message)
        VALUES ('Error creating admin user', SQLERRM);
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- SIMPLER APPROACH: Manual Admin Creation
-- =============================================

-- Step-by-step manual admin creation (execute these queries in order):

-- 1. First, manually insert into public.users table with a placeholder ID
-- Replace the values below with your actual admin details:

/*
INSERT INTO public.users (
    id,
    email,
    user_type,
    first_name,
    last_name,
    phone,
    is_active,
    email_verified,
    email_confirmed_at,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(), -- This will be replaced when we create the auth user
    'admin@learned.com', -- Replace with your admin email
    'admin',
    'Admin', -- Replace with first name
    'User', -- Replace with last name
    '+1234567890', -- Replace with phone (optional)
    true,
    true,
    now(),
    now(),
    now()
);
*/

-- =============================================
-- RECOMMENDED APPROACH: Use Supabase Dashboard
-- =============================================

-- The safest way to create an admin user is through the Supabase Dashboard:

-- 1. Go to your Supabase Dashboard
-- 2. Navigate to Authentication > Users
-- 3. Click "Add User"
-- 4. Fill in the details:
--    - Email: admin@learned.com
--    - Password: (set a strong password)
--    - Auto Confirm User: YES
--    - User Metadata: 
--      {
--        "user_type": "admin",
--        "first_name": "Admin",
--        "last_name": "User"
--      }
-- 5. After creating the auth user, the trigger will automatically create the public.users record
-- 6. If the trigger doesn't work (because it blocks non-students), manually update the user_type:

/*
-- Find the user ID from auth.users and update the public.users record:
UPDATE public.users 
SET user_type = 'admin',
    first_name = 'Admin',
    last_name = 'User',
    email_verified = true,
    is_active = true
WHERE email = 'admin@learned.com';
*/

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Check if admin user was created successfully:
-- SELECT * FROM public.users WHERE user_type = 'admin';

-- Check auth user exists:
-- SELECT id, email, raw_user_meta_data FROM auth.users WHERE email = 'admin@learned.com';

-- Test admin permissions:
-- SELECT 
--     u.email,
--     u.user_type,
--     u.first_name,
--     u.last_name,
--     u.is_active
-- FROM public.users u 
-- WHERE u.user_type = 'admin';

SELECT 'Admin user creation script ready!' as status;