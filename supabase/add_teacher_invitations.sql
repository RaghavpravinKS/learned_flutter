-- =============================================
-- CLEAN INSTALLATION - Teacher Invitation System
-- This drops the old table and creates the new JWT-based version
-- =============================================

-- Step 1: Drop old table and all dependencies
DROP TABLE IF EXISTS public.teacher_invitations CASCADE;

-- Step 2: Create new teacher_invitations table with correct schema
CREATE TABLE public.teacher_invitations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email character varying NOT NULL UNIQUE,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    subject character varying,
    grade_levels integer[],
    invited_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
    status character varying DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
    expires_at timestamp with time zone DEFAULT (now() + interval '7 days'),
    accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Step 3: Create indexes
CREATE INDEX idx_teacher_invitations_email ON public.teacher_invitations(email);
CREATE INDEX idx_teacher_invitations_status ON public.teacher_invitations(status);
CREATE INDEX idx_teacher_invitations_expires ON public.teacher_invitations(expires_at);

-- Step 4: Enable RLS
ALTER TABLE public.teacher_invitations ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies
CREATE POLICY "Admins can manage all teacher invitations" ON public.teacher_invitations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND user_type = 'admin'::user_type
        )
    );

CREATE POLICY "Invited teachers can view their own pending invitations" ON public.teacher_invitations
    FOR SELECT USING (
        email = (
            SELECT raw_user_meta_data->>'email'
            FROM auth.users WHERE id = auth.uid()
        )
        AND status = 'pending'
    );

-- Step 6: Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.teacher_invitations TO authenticated;

-- Step 7: Create invitation function
CREATE OR REPLACE FUNCTION create_teacher_invitation(
    p_email text,
    p_first_name text,
    p_last_name text,
    p_admin_id uuid,
    p_subject text DEFAULT NULL,
    p_grade_levels integer[] DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
    invitation_id uuid;
BEGIN
    -- Verify admin permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = p_admin_id 
        AND user_type = 'admin'::user_type 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    -- Check if email exists in auth.users
    IF EXISTS (
        SELECT 1 FROM auth.users 
        WHERE raw_user_meta_data->>'email' = p_email
    ) THEN
        RAISE EXCEPTION 'Email already exists in system';
    END IF;
    
    -- Check for existing pending invitations
    IF EXISTS (
        SELECT 1 FROM public.teacher_invitations 
        WHERE email = p_email 
        AND status = 'pending'
    ) THEN
        RAISE EXCEPTION 'Pending invitation already exists for this email';
    END IF;
    
    -- Create invitation record
    INSERT INTO public.teacher_invitations (
        email, first_name, last_name, subject, grade_levels, invited_by
    ) VALUES (
        p_email, p_first_name, p_last_name, p_subject, p_grade_levels, p_admin_id
    ) RETURNING id INTO invitation_id;
    
    -- Log the activity (with fallback)
    BEGIN
        PERFORM log_audit_event(
            p_user_id := p_admin_id,
            p_action_type := 'teacher_invitation_created',
            p_table_name := 'teacher_invitations',
            p_record_id := invitation_id,
            p_new_values := jsonb_build_object(
                'email', p_email,
                'first_name', p_first_name,
                'last_name', p_last_name,
                'subject', p_subject
            ),
            p_description := 'Teacher invitation created for: ' || p_email,
            p_severity := 'info',
            p_tags := ARRAY['invitation', 'teacher', 'admin'],
            p_metadata := jsonb_build_object('expires_at', (now() + interval '7 days'))
        );
    EXCEPTION
        WHEN undefined_function THEN
            INSERT INTO public.trigger_logs (message, metadata) VALUES (
                'Teacher invitation created',
                jsonb_build_object('email', p_email, 'invitation_id', invitation_id)
            );
    END;
    
    RETURN jsonb_build_object(
        'success', true,
        'invitation_id', invitation_id,
        'email', p_email,
        'expires_at', (now() + interval '7 days')::text,
        'message', 'Teacher invitation created successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 8: Create onboarding completion function
CREATE OR REPLACE FUNCTION complete_teacher_onboarding(
    p_phone text DEFAULT NULL,
    p_bio text DEFAULT NULL,
    p_additional_subjects text[] DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
    invitation_rec record;
    teacher_id uuid;
    generated_teacher_id text;
    current_user_id uuid;
    current_user_email text;
    all_subjects text[];
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Get email from auth.users metadata
    SELECT raw_user_meta_data->>'email'
    INTO current_user_email 
    FROM auth.users 
    WHERE id = current_user_id;
    
    IF current_user_email IS NULL THEN
        RAISE EXCEPTION 'Invalid user session - no email found';
    END IF;
    
    -- Find valid invitation
    SELECT * INTO invitation_rec 
    FROM public.teacher_invitations 
    WHERE email = current_user_email 
    AND status = 'pending' 
    AND expires_at > now();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No valid invitation found for email: %', current_user_email;
    END IF;
    
    -- Generate teacher ID
    generated_teacher_id := 'TEA' || to_char(now(), 'YYYYMMDD') || substr(current_user_id::text, 1, 6);
    
    -- Create user record in public.users
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
        current_user_id, 
        current_user_email,
        'teacher'::user_type,
        invitation_rec.first_name, 
        invitation_rec.last_name, 
        p_phone,
        true, 
        true,
        now(),
        now(), 
        now()
    );
    
    -- Combine subjects
    all_subjects := CASE 
        WHEN invitation_rec.subject IS NOT NULL 
        THEN ARRAY[invitation_rec.subject]
        ELSE ARRAY[]::text[]
    END;
    
    IF p_additional_subjects IS NOT NULL THEN
        all_subjects := all_subjects || p_additional_subjects;
    END IF;
    
    -- Create teacher record
    INSERT INTO public.teachers (
        user_id, 
        teacher_id, 
        specializations, 
        bio,
        is_verified,
        status, 
        hire_date,
        created_at, 
        updated_at
    ) VALUES (
        current_user_id, 
        generated_teacher_id, 
        all_subjects,
        p_bio, 
        true,
        'active', 
        CURRENT_DATE,
        now(), 
        now()
    ) RETURNING id INTO teacher_id;
    
    -- Mark invitation as accepted
    UPDATE public.teacher_invitations 
    SET status = 'accepted', accepted_at = now(), updated_at = now()
    WHERE id = invitation_rec.id;
    
    -- Log completion
    BEGIN
        PERFORM log_audit_event(
            p_user_id := current_user_id,
            p_action_type := 'teacher_onboarding_completed',
            p_table_name := 'teachers',
            p_record_id := teacher_id,
            p_new_values := jsonb_build_object(
                'teacher_id', generated_teacher_id,
                'user_id', current_user_id,
                'specializations', all_subjects
            ),
            p_description := 'Teacher onboarding completed for: ' || current_user_email,
            p_severity := 'info',
            p_tags := ARRAY['onboarding', 'teacher', 'completed'],
            p_metadata := jsonb_build_object('invitation_id', invitation_rec.id)
        );
    EXCEPTION
        WHEN undefined_function THEN
            INSERT INTO public.trigger_logs (message, metadata) VALUES (
                'Teacher onboarding completed',
                jsonb_build_object('email', current_user_email, 'teacher_id', generated_teacher_id)
            );
    END;
    
    RETURN jsonb_build_object(
        'success', true,
        'teacher_id', generated_teacher_id,
        'user_id', current_user_id,
        'email', current_user_email,
        'message', 'Teacher onboarding completed successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 9: Admin query function
CREATE OR REPLACE FUNCTION get_teacher_invitations(
    p_admin_id uuid
) RETURNS TABLE (
    id uuid,
    email text,
    first_name text,
    last_name text,
    subject text,
    status text,
    created_at timestamp with time zone,
    expires_at timestamp with time zone,
    accepted_at timestamp with time zone
) AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = p_admin_id 
        AND user_type = 'admin'::user_type 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    RETURN QUERY
    SELECT ti.id, ti.email, ti.first_name, ti.last_name, ti.subject, ti.status,
           ti.created_at, ti.expires_at, ti.accepted_at
    FROM public.teacher_invitations ti
    ORDER BY ti.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 10: Cancel invitation function
CREATE OR REPLACE FUNCTION cancel_teacher_invitation(
    p_invitation_id uuid,
    p_admin_id uuid
) RETURNS jsonb AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = p_admin_id 
        AND user_type = 'admin'::user_type 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    UPDATE public.teacher_invitations 
    SET status = 'cancelled', updated_at = now()
    WHERE id = p_invitation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error', 'Invitation not found or already processed'
        );
    END IF;
    
    BEGIN
        PERFORM log_audit_event(
            p_user_id := p_admin_id,
            p_action_type := 'teacher_invitation_cancelled',
            p_table_name := 'teacher_invitations',
            p_record_id := p_invitation_id,
            p_description := 'Teacher invitation cancelled by admin',
            p_severity := 'info',
            p_tags := ARRAY['invitation', 'cancelled', 'admin']
        );
    EXCEPTION
        WHEN undefined_function THEN
            INSERT INTO public.trigger_logs (message, metadata) VALUES (
                'Teacher invitation cancelled',
                jsonb_build_object('invitation_id', p_invitation_id, 'admin_id', p_admin_id)
            );
    END;
    
    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Invitation cancelled successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 11: Cleanup function
CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS integer AS $$
DECLARE
    expired_count integer;
BEGIN
    UPDATE public.teacher_invitations 
    SET status = 'expired', updated_at = now()
    WHERE status = 'pending' AND expires_at < now();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES (
        'Expired invitations cleanup completed', 
        jsonb_build_object('expired_count', expired_count, 'timestamp', now())
    );
    
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 12: Deprecate old function
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
BEGIN
    RETURN jsonb_build_object(
        'success', false, 
        'error', 'DEPRECATED: Use create_teacher_invitation() instead',
        'recommendation', 'Use the new teacher invitation system with magic links',
        'new_function', 'create_teacher_invitation(email, first_name, last_name, subject, grade_levels, admin_id)'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verification: Check the new table structure
SELECT column_name, data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'teacher_invitations'
ORDER BY ordinal_position;

SELECT 'Teacher invitation system installed successfully! ✓' as status;