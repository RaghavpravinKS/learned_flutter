-- ==================================================
-- ADMIN TEACHER MANAGEMENT SYSTEM
-- Tables and functions for admin-controlled teacher onboarding
-- ==================================================

-- 1. Teacher Documents Table
CREATE TABLE IF NOT EXISTS teacher_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
  document_type VARCHAR NOT NULL CHECK (document_type IN (
    'certificate', 'id_proof', 'background_check', 'resume', 'photo'
  )),
  document_name VARCHAR NOT NULL,
  file_url TEXT NOT NULL,
  file_size BIGINT,
  mime_type VARCHAR,
  verification_status VARCHAR DEFAULT 'pending' CHECK (verification_status IN (
    'pending', 'approved', 'rejected'
  )),
  verified_by UUID REFERENCES users(id),
  verified_at TIMESTAMPTZ,
  rejection_reason TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Teacher Verification Workflow
CREATE TABLE IF NOT EXISTS teacher_verification (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
  verification_stage VARCHAR DEFAULT 'profile_incomplete' CHECK (verification_stage IN (
    'profile_incomplete', 'documents_pending', 'documents_submitted', 
    'under_review', 'approved', 'rejected'
  )),
  profile_completed_at TIMESTAMPTZ,
  documents_submitted_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMPTZ,
  approval_notes TEXT,
  rejection_reason TEXT,
  background_check_status VARCHAR CHECK (background_check_status IN (
    'pending', 'clear', 'flagged'
  )),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT teacher_verification_teacher_id_unique UNIQUE (teacher_id)
);

-- 3. Admin Activities Log
CREATE TABLE IF NOT EXISTS admin_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES users(id),
  activity_type VARCHAR NOT NULL CHECK (activity_type IN (
    'create_teacher', 'verify_document', 'approve_teacher', 'reject_teacher',
    'review_classroom', 'handle_refund', 'ban_user'
  )),
  target_user_id UUID REFERENCES users(id),
  target_table VARCHAR,
  target_record_id UUID,
  description TEXT,
  metadata JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Admin Function: Create Teacher Account
CREATE OR REPLACE FUNCTION admin_create_teacher(
    p_admin_id UUID,
    p_email VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_phone VARCHAR DEFAULT NULL,
    p_temporary_password VARCHAR DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_teacher_id UUID;
    v_user_id UUID;
    v_temp_password VARCHAR;
BEGIN
    -- Verify admin permissions
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RAISE EXCEPTION 'Only administrators can create teacher accounts';
    END IF;
    
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email already exists in the system';
    END IF;
    
    -- Generate temporary password if not provided
    v_temp_password := COALESCE(p_temporary_password, 'Teacher' || floor(random() * 10000)::text);
    
    -- Generate UUIDs
    v_user_id := gen_random_uuid();
    v_teacher_id := gen_random_uuid();
    
    -- Create auth user (this would typically be done via Supabase Admin API)
    -- For now, we'll create the public.users record directly
    INSERT INTO public.users (
        id, email, user_type, first_name, last_name, phone, 
        password_hash, is_active, email_verified, created_at, updated_at
    ) VALUES (
        v_user_id, p_email, 'teacher', p_first_name, p_last_name, p_phone,
        'temp_hash_' || v_temp_password, -- In real implementation, this would be properly hashed
        true, false, NOW(), NOW()
    );
    
    -- Create user profile
    INSERT INTO public.user_profiles (user_id, created_at, updated_at)
    VALUES (v_user_id, NOW(), NOW());
    
    -- Create teacher record
    INSERT INTO public.teachers (
        id, user_id, teacher_id, status, is_verified, created_at, updated_at
    ) VALUES (
        v_teacher_id, v_user_id, 
        'TCH-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
        'pending_completion', false, NOW(), NOW()
    );
    
    -- Create verification workflow
    INSERT INTO teacher_verification (teacher_id, created_at, updated_at)
    VALUES (v_teacher_id, NOW(), NOW());
    
    -- Log admin activity
    INSERT INTO admin_activities (
        admin_id, activity_type, target_user_id, description, metadata
    ) VALUES (
        p_admin_id, 'create_teacher', v_user_id,
        'Created teacher account for ' || p_email,
        jsonb_build_object(
            'teacher_id', v_teacher_id,
            'email', p_email,
            'temp_password', v_temp_password
        )
    );
    
    -- Add to email queue (welcome email with credentials)
    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Teacher account created - send welcome email',
        jsonb_build_object(
            'email', p_email,
            'teacher_id', v_teacher_id,
            'temp_password', v_temp_password,
            'action', 'send_teacher_welcome_email'
        )
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'teacher_id', v_teacher_id,
        'user_id', v_user_id,
        'email', p_email,
        'temporary_password', v_temp_password,
        'message', 'Teacher account created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    -- Log error
    INSERT INTO trigger_logs (message, error_message, metadata)
    VALUES (
        'Error creating teacher account',
        SQLERRM,
        jsonb_build_object(
            'admin_id', p_admin_id,
            'email', p_email,
            'error_code', SQLSTATE
        )
    );
    RAISE;
END;
$$ LANGUAGE plpgsql;

-- 5. Function: Verify Teacher Documents
CREATE OR REPLACE FUNCTION admin_verify_teacher_document(
    p_admin_id UUID,
    p_document_id UUID,
    p_status VARCHAR, -- 'approved' or 'rejected'
    p_notes TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_teacher_id UUID;
    v_document_type VARCHAR;
BEGIN
    -- Verify admin permissions
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RAISE EXCEPTION 'Only administrators can verify documents';
    END IF;
    
    -- Get document info
    SELECT teacher_id, document_type INTO v_teacher_id, v_document_type
    FROM teacher_documents 
    WHERE id = p_document_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Document not found';
    END IF;
    
    -- Update document verification
    UPDATE teacher_documents SET
        verification_status = p_status,
        verified_by = p_admin_id,
        verified_at = NOW(),
        rejection_reason = CASE WHEN p_status = 'rejected' THEN p_notes ELSE NULL END,
        updated_at = NOW()
    WHERE id = p_document_id;
    
    -- Log admin activity
    INSERT INTO admin_activities (
        admin_id, activity_type, target_record_id, description, metadata
    ) VALUES (
        p_admin_id, 'verify_document', p_document_id,
        p_status || ' ' || v_document_type || ' document',
        jsonb_build_object(
            'teacher_id', v_teacher_id,
            'document_id', p_document_id,
            'status', p_status,
            'notes', p_notes
        )
    );
    
    -- Check if all documents are approved and update teacher verification
    IF p_status = 'approved' THEN
        PERFORM update_teacher_verification_status(v_teacher_id);
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'Document ' || p_status || ' successfully'
    );
END;
$$ LANGUAGE plpgsql;

-- 6. Function: Update Teacher Verification Status
CREATE OR REPLACE FUNCTION update_teacher_verification_status(p_teacher_id UUID)
RETURNS VOID AS $$
DECLARE
    v_pending_docs INTEGER;
    v_rejected_docs INTEGER;
    v_total_docs INTEGER;
BEGIN
    -- Count document statuses
    SELECT 
        COUNT(*) FILTER (WHERE verification_status = 'pending'),
        COUNT(*) FILTER (WHERE verification_status = 'rejected'),
        COUNT(*)
    INTO v_pending_docs, v_rejected_docs, v_total_docs
    FROM teacher_documents 
    WHERE teacher_id = p_teacher_id;
    
    -- Update verification status based on document states
    IF v_total_docs = 0 THEN
        -- No documents uploaded
        UPDATE teacher_verification SET
            verification_stage = 'documents_pending',
            updated_at = NOW()
        WHERE teacher_id = p_teacher_id;
    ELSIF v_rejected_docs > 0 THEN
        -- Some documents rejected
        UPDATE teacher_verification SET
            verification_stage = 'rejected',
            updated_at = NOW()
        WHERE teacher_id = p_teacher_id;
    ELSIF v_pending_docs > 0 THEN
        -- Some documents still pending
        UPDATE teacher_verification SET
            verification_stage = 'under_review',
            updated_at = NOW()
        WHERE teacher_id = p_teacher_id;
    ELSE
        -- All documents approved
        UPDATE teacher_verification SET
            verification_stage = 'approved',
            reviewed_at = NOW(),
            updated_at = NOW()
        WHERE teacher_id = p_teacher_id;
        
        -- Update teacher status
        UPDATE teachers SET
            is_verified = true,
            status = 'active',
            updated_at = NOW()
        WHERE id = p_teacher_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
