-- Teacher Invitation System with Magic Links
-- This is a better approach for production teacher onboarding

-- Function: Invite teacher (creates profile and sends magic link)
CREATE OR REPLACE FUNCTION invite_teacher(
    p_admin_id uuid,
    p_email text,
    p_first_name text,
    p_last_name text,
    p_phone text DEFAULT NULL,
    p_qualifications text DEFAULT NULL,
    p_bio text DEFAULT NULL,
    p_experience_years integer DEFAULT 0,
    p_specializations text DEFAULT NULL
)
RETURNS jsonb AS $$
DECLARE
    v_user_id uuid;
    v_teacher_id uuid;
    v_teacher_id_val text;
    v_invitation_token text;
BEGIN
    -- Validate admin user (bypass for testing with special UUID)
    IF p_admin_id != '00000000-0000-0000-0000-000000000000'::uuid AND 
       NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Admin access required');
    END IF;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Teacher with this email already exists');
    END IF;

    -- Generate teacher ID and invitation token
    v_teacher_id_val := 'TEA' || to_char(now(), 'YYYYMMDD') || substr(gen_random_uuid()::text, 1, 6);
    v_invitation_token := encode(gen_random_bytes(32), 'hex');
    v_user_id := gen_random_uuid();

    -- Create user record with pending status
    INSERT INTO users (
        id, email, user_type, first_name, last_name, phone,
        is_active, email_verified, created_at, updated_at
    ) VALUES (
        v_user_id, p_email, 'teacher', p_first_name, p_last_name, p_phone,
        false, false, now(), now()  -- inactive until they accept invitation
    ) RETURNING id INTO v_user_id;

    -- Create teacher record
    INSERT INTO teachers (
        user_id, teacher_id, qualifications, experience_years,
        bio, status, created_at, updated_at
    ) VALUES (
        v_user_id, v_teacher_id_val, p_qualifications, p_experience_years,
        p_bio, 'pending', now(), now()  -- pending until invitation accepted
    ) RETURNING id INTO v_teacher_id;

    -- Create invitation record
    INSERT INTO teacher_invitations (
        teacher_id, invitation_token, invited_by, expires_at, status, created_at
    ) VALUES (
        v_teacher_id, v_invitation_token, p_admin_id, now() + interval '7 days', 'pending', now()
    );

    -- Log admin activity
    IF p_admin_id != '00000000-0000-0000-0000-000000000000'::uuid THEN
        INSERT INTO admin_activities (
            admin_id, activity_type, target_user_id, description, created_at
        ) VALUES (
            p_admin_id, 'invite_teacher', v_user_id, 
            'Invited teacher: ' || p_first_name || ' ' || p_last_name || ' (' || p_email || ')',
            now()
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'teacher_id', v_teacher_id,
        'teacher_id_val', v_teacher_id_val,
        'email', p_email,
        'invitation_token', v_invitation_token,
        'invitation_link', 'https://your-app.com/teacher/accept-invitation?token=' || v_invitation_token,
        'magic_link_email', p_email,
        'message', 'Teacher invitation created. Send magic link to complete registration.',
        'expires_at', (now() + interval '7 days')::text
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Accept teacher invitation and activate account
CREATE OR REPLACE FUNCTION accept_teacher_invitation(
    p_invitation_token text,
    p_auth_user_id uuid  -- This will be the actual Supabase auth user ID
)
RETURNS jsonb AS $$
DECLARE
    v_invitation_record record;
    v_teacher_id uuid;
    v_user_id uuid;
BEGIN
    -- Find and validate invitation
    SELECT ti.*, t.user_id, t.id as teacher_id
    INTO v_invitation_record
    FROM teacher_invitations ti
    JOIN teachers t ON ti.teacher_id = t.id
    WHERE ti.invitation_token = p_invitation_token
      AND ti.status = 'pending'
      AND ti.expires_at > now();

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error', 'Invalid or expired invitation token'
        );
    END IF;

    v_user_id := v_invitation_record.user_id;
    v_teacher_id := v_invitation_record.teacher_id;

    -- Update user record with auth user ID and activate
    UPDATE users 
    SET id = p_auth_user_id,
        is_active = true,
        email_verified = true,
        updated_at = now()
    WHERE id = v_user_id;

    -- Update teacher status
    UPDATE teachers 
    SET user_id = p_auth_user_id,
        status = 'active',
        updated_at = now()
    WHERE id = v_teacher_id;

    -- Mark invitation as accepted
    UPDATE teacher_invitations 
    SET status = 'accepted',
        accepted_at = now()
    WHERE invitation_token = p_invitation_token;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Teacher invitation accepted successfully',
        'user_id', p_auth_user_id,
        'teacher_id', v_teacher_id
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create teacher_invitations table if it doesn't exist
CREATE TABLE IF NOT EXISTS teacher_invitations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id uuid REFERENCES teachers(id) ON DELETE CASCADE,
    invitation_token text UNIQUE NOT NULL,
    invited_by uuid REFERENCES users(id),
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
    expires_at timestamptz NOT NULL,
    accepted_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_token ON teacher_invitations(invitation_token);
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_status ON teacher_invitations(status);
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_expires ON teacher_invitations(expires_at);

COMMENT ON TABLE teacher_invitations IS 'Tracks teacher invitation tokens and status for magic link onboarding';
COMMENT ON FUNCTION invite_teacher IS 'Creates teacher profile and invitation for magic link onboarding';
COMMENT ON FUNCTION accept_teacher_invitation IS 'Completes teacher registration after magic link authentication';