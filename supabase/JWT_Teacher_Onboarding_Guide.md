# Teacher Onboarding System - JWT Based Implementation Guide

## 📋 Overview

This system uses **Supabase JWT authentication** combined with a `teacher_invitations` table for secure teacher onboarding. No custom tokens needed - we leverage Supabase's built-in magic link system.

## 🏗️ Architecture Flow

```
1. Admin → Creates invitation in database
2. System → Sends magic link email to teacher
3. Teacher → Clicks link (JWT authentication)
4. System → Validates JWT + checks invitation
5. Teacher → Completes profile setup
6. System → Creates teacher account + marks invitation accepted
```

## 🗄️ Database Schema

### 1. Teacher Invitations Table

```sql
-- Teacher invitations table
CREATE TABLE IF NOT EXISTS teacher_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    subject TEXT,
    grade_levels INTEGER[],
    invited_by UUID REFERENCES users(id),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (now() + interval '7 days'),
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_email ON teacher_invitations(email);
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_status ON teacher_invitations(status);
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_expires ON teacher_invitations(expires_at);

-- Row Level Security
ALTER TABLE teacher_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage all invitations" ON teacher_invitations
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND user_type = 'admin')
    );
```

### 2. Required Functions

```sql
-- Function: Create teacher invitation (Admin only)
CREATE OR REPLACE FUNCTION create_teacher_invitation(
    p_email TEXT,
    p_first_name TEXT,
    p_last_name TEXT,
    p_subject TEXT DEFAULT NULL,
    p_grade_levels INTEGER[] DEFAULT NULL,
    p_admin_id UUID
) RETURNS jsonb AS $$
DECLARE
    invitation_id UUID;
BEGIN
    -- Verify admin permissions
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    -- Check if email already exists in system
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email already exists in system';
    END IF;
    
    -- Check for existing pending invitations
    IF EXISTS (SELECT 1 FROM teacher_invitations WHERE email = p_email AND status = 'pending') THEN
        RAISE EXCEPTION 'Pending invitation already exists for this email';
    END IF;
    
    -- Create invitation record
    INSERT INTO teacher_invitations (
        email, first_name, last_name, subject, grade_levels, invited_by
    ) VALUES (
        p_email, p_first_name, p_last_name, p_subject, p_grade_levels, p_admin_id
    ) RETURNING id INTO invitation_id;
    
    -- Log the activity
    INSERT INTO audit_logs (table_name, operation, record_id, performed_by, details)
    VALUES ('teacher_invitations', 'CREATE', invitation_id, p_admin_id, 
            jsonb_build_object('email', p_email, 'action', 'invitation_created'));
    
    RETURN jsonb_build_object(
        'success', true,
        'invitation_id', invitation_id,
        'email', p_email,
        'expires_at', (now() + interval '7 days')::text,
        'message', 'Teacher invitation created successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Complete teacher onboarding (JWT validated)
CREATE OR REPLACE FUNCTION complete_teacher_onboarding(
    p_phone TEXT DEFAULT NULL,
    p_bio TEXT DEFAULT NULL,
    p_additional_subjects TEXT[] DEFAULT NULL
) RETURNS jsonb AS $$
DECLARE
    invitation_rec RECORD;
    teacher_id UUID;
    generated_teacher_id TEXT;
    current_user_id UUID;
    current_user_email TEXT;
BEGIN
    -- Get current user from JWT context
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Get user email from auth.users
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    IF current_user_email IS NULL THEN
        RAISE EXCEPTION 'Invalid user session';
    END IF;
    
    -- Find valid invitation for this email
    SELECT * INTO invitation_rec FROM teacher_invitations 
    WHERE email = current_user_email 
    AND status = 'pending' 
    AND expires_at > now();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No valid invitation found for email: %', current_user_email;
    END IF;
    
    -- Generate teacher ID
    generated_teacher_id := 'TEA' || to_char(now(), 'YYYYMMDD') || substr(current_user_id::text, 1, 6);
    
    -- Create user record in public.users table
    INSERT INTO users (
        id, email, user_type, first_name, last_name, phone,
        is_active, email_verified, created_at, updated_at
    ) VALUES (
        current_user_id, current_user_email, 'teacher'::user_type,
        invitation_rec.first_name, invitation_rec.last_name, p_phone,
        true, true, now(), now()
    );
    
    -- Combine subjects
    DECLARE
        all_subjects TEXT[];
    BEGIN
        all_subjects := CASE 
            WHEN invitation_rec.subject IS NOT NULL THEN ARRAY[invitation_rec.subject]
            ELSE ARRAY[]::TEXT[]
        END;
        
        IF p_additional_subjects IS NOT NULL THEN
            all_subjects := all_subjects || p_additional_subjects;
        END IF;
    END;
    
    -- Create teacher record
    INSERT INTO teachers (
        user_id, teacher_id, subjects, grade_levels, bio,
        status, created_at, updated_at
    ) VALUES (
        current_user_id, generated_teacher_id, all_subjects,
        invitation_rec.grade_levels, p_bio, 'active', now(), now()
    ) RETURNING id INTO teacher_id;
    
    -- Mark invitation as accepted
    UPDATE teacher_invitations 
    SET status = 'accepted', accepted_at = now(), updated_at = now()
    WHERE id = invitation_rec.id;
    
    -- Log completion
    INSERT INTO audit_logs (table_name, operation, record_id, performed_by, details)
    VALUES ('teachers', 'CREATE', teacher_id, current_user_id, 
            jsonb_build_object('teacher_id', generated_teacher_id, 'action', 'onboarding_completed'));
    
    RETURN jsonb_build_object(
        'success', true,
        'teacher_id', generated_teacher_id,
        'user_id', current_user_id,
        'email', current_user_email,
        'message', 'Teacher onboarding completed successfully'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get invitation status (Admin only)
CREATE OR REPLACE FUNCTION get_teacher_invitations(
    p_admin_id UUID
) RETURNS TABLE (
    id UUID,
    email TEXT,
    first_name TEXT,
    last_name TEXT,
    subject TEXT,
    status TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    accepted_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    -- Verify admin permissions
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    RETURN QUERY
    SELECT ti.id, ti.email, ti.first_name, ti.last_name, ti.subject, ti.status,
           ti.created_at, ti.expires_at, ti.accepted_at
    FROM teacher_invitations ti
    ORDER BY ti.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Cancel invitation (Admin only)
CREATE OR REPLACE FUNCTION cancel_teacher_invitation(
    p_invitation_id UUID,
    p_admin_id UUID
) RETURNS jsonb AS $$
BEGIN
    -- Verify admin permissions
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    -- Cancel invitation
    UPDATE teacher_invitations 
    SET status = 'cancelled', updated_at = now()
    WHERE id = p_invitation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invitation not found or already processed');
    END IF;
    
    RETURN jsonb_build_object('success', true, 'message', 'Invitation cancelled successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Cleanup expired invitations (run periodically)
CREATE OR REPLACE FUNCTION cleanup_expired_invitations()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE teacher_invitations 
    SET status = 'expired', updated_at = now()
    WHERE status = 'pending' AND expires_at < now();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## 📧 Magic Link Email Template

Configure this in **Supabase Dashboard → Authentication → Email Templates → Magic Link**:

```html
<h2>🎓 Welcome to LearnED!</h2>

<p>Hello {{.FirstName}},</p>

<p>You've been invited to join LearnED as a teacher. Click the button below to complete your account setup:</p>

<table cellpadding="0" cellspacing="0" border="0" style="margin: 20px 0;">
  <tr>
    <td style="background-color: #007bff; border-radius: 6px; padding: 0;">
      <a href="{{ .ConfirmationURL }}" 
         style="display: inline-block; padding: 15px 30px; color: #ffffff; text-decoration: none; font-weight: bold; border-radius: 6px;">
        Complete Teacher Setup
      </a>
    </td>
  </tr>
</table>

<p>This link will expire in 1 hour for security reasons.</p>

<p><strong>What happens next?</strong></p>
<ul>
  <li>✅ Complete your teacher profile</li>
  <li>📱 Download the LearnED mobile app</li>
  <li>🚀 Start creating and managing classes</li>
</ul>

<p>If you didn't expect this invitation, please ignore this email or contact our support team.</p>

<hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
<p style="color: #666; font-size: 12px;">
  This email was sent from LearnED. If you have questions, contact us at support@learned.com
</p>
```

## 🌐 Web Implementation Logic

### 1. Page Structure

The onboarding page should handle these states:
- **Loading**: Validating JWT from URL
- **Email Entry**: Teacher enters email to get magic link
- **Profile Setup**: Complete teacher profile (after JWT validation)
- **Success**: Onboarding completed

### 2. URL Patterns

```
GET /teacher/onboard
GET /teacher/onboard#access_token=jwt...  (magic link return)
```

### 3. JavaScript Logic Flow

```javascript
// Page load handler
window.addEventListener('load', async () => {
    const urlHash = window.location.hash;
    
    if (urlHash.includes('access_token=')) {
        // User clicked magic link - validate JWT
        await handleMagicLinkReturn();
    } else {
        // Normal page load - show email form
        showEmailForm();
    }
});

// Handle magic link return
async function handleMagicLinkReturn() {
    try {
        // Supabase automatically processes JWT from URL hash
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error || !session) {
            throw new Error('Invalid magic link');
        }
        
        // JWT is valid - check for pending invitation
        const { data: invitations, error: inviteError } = await supabase
            .from('teacher_invitations')
            .select('*')
            .eq('email', session.user.email)
            .eq('status', 'pending')
            .limit(1);
        
        if (inviteError || !invitations?.length) {
            throw new Error('No valid invitation found');
        }
        
        // Show profile setup form
        showProfileForm(session.user, invitations[0]);
        
    } catch (error) {
        showError(error.message);
    }
}

// Send magic link
async function sendMagicLink(email) {
    try {
        // Check if invitation exists
        const { data: invitations, error: checkError } = await supabase
            .from('teacher_invitations')
            .select('*')
            .eq('email', email)
            .eq('status', 'pending');
        
        if (checkError) throw checkError;
        
        if (!invitations?.length) {
            throw new Error('No teacher invitation found for this email');
        }
        
        // Send magic link
        const { error: authError } = await supabase.auth.signInWithOtp({
            email: email,
            options: {
                shouldCreateUser: true,
                emailRedirectTo: window.location.href,
                data: {
                    user_type: 'teacher',
                    first_name: invitations[0].first_name,
                    last_name: invitations[0].last_name
                }
            }
        });
        
        if (authError) throw authError;
        
        showSuccess('Check your email for the setup link!');
        
    } catch (error) {
        showError(error.message);
    }
}

// Complete teacher setup
async function completeSetup(formData) {
    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) throw new Error('Not authenticated');
        
        const { data, error } = await supabase.rpc('complete_teacher_onboarding', {
            p_phone: formData.phone || null,
            p_bio: formData.bio || null,
            p_additional_subjects: formData.subjects || null
        });
        
        if (error) throw error;
        
        showSuccess('Setup completed! You can now use the LearnED mobile app.');
        
    } catch (error) {
        showError(error.message);
    }
}
```

### 4. Required Form Fields

**Email Form (Step 1):**
```html
<input type="email" id="email" placeholder="Enter your email address" required>
<button onclick="sendMagicLink(document.getElementById('email').value)">
    Send Setup Link
</button>
```

**Profile Form (Step 2):**
```html
<input type="email" id="user-email" readonly> <!-- Pre-filled from JWT -->
<input type="text" id="full-name" readonly>   <!-- Pre-filled from invitation -->
<input type="tel" id="phone" placeholder="+1 (555) 123-4567">
<textarea id="bio" placeholder="Teaching experience..."></textarea>
<select id="additional-subjects" multiple>
    <option value="Mathematics">Mathematics</option>
    <option value="Science">Science</option>
    <!-- etc -->
</select>
<button onclick="completeSetup(getFormData())">Complete Setup</button>
```

## 👨‍💼 Admin Panel Logic

### 1. Admin Authentication

```javascript
// Admin login
async function adminLogin(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
        email: email,
        password: password
    });
    
    if (error) throw error;
    
    // Verify admin role
    const { data: userData } = await supabase
        .from('users')
        .select('user_type')
        .eq('id', data.user.id)
        .single();
    
    if (userData?.user_type !== 'admin') {
        throw new Error('Admin access required');
    }
    
    return data.user;
}
```

### 2. Create Teacher Invitation

```javascript
async function createInvitation(formData, adminId) {
    const { data, error } = await supabase.rpc('create_teacher_invitation', {
        p_email: formData.email,
        p_first_name: formData.firstName,
        p_last_name: formData.lastName,
        p_subject: formData.subject,
        p_grade_levels: formData.gradeLevels,
        p_admin_id: adminId
    });
    
    if (error) throw error;
    
    // Show success with instructions
    showSuccess(`
        Invitation created for ${formData.email}
        
        Next steps:
        1. Teacher will receive magic link email
        2. They click link to complete setup
        3. Then they can use mobile app
    `);
    
    return data;
}
```

### 3. View Invitations

```javascript
async function loadInvitations(adminId) {
    const { data, error } = await supabase.rpc('get_teacher_invitations', {
        p_admin_id: adminId
    });
    
    if (error) throw error;
    
    // Display in table
    displayInvitationsTable(data);
}
```

## 🔧 Supabase Configuration

### 1. URL Configuration

In **Supabase Dashboard → Authentication → URL Configuration**:

```
Site URL: https://learned.com
Redirect URLs:
- https://learned.com/teacher/onboard
- http://localhost:3000/teacher/onboard  (for testing)
```

### 2. Email Provider Setup

In **Supabase Dashboard → Authentication → Providers**:
- ✅ Enable Email provider
- ✅ Confirm email changes: Enabled
- ✅ Secure email change: Enabled

## 🧪 Testing Flow

### 1. Create Test Admin

```sql
-- Run this in Supabase SQL Editor to create test admin
INSERT INTO auth.users (
    id, email, encrypted_password, email_confirmed_at, 
    created_at, updated_at, raw_app_meta_data, raw_user_meta_data
) VALUES (
    gen_random_uuid(),
    'admin@learned.com',
    crypt('AdminPass123!', gen_salt('bf')),
    now(), now(), now(),
    '{"provider": "email", "providers": ["email"]}',
    '{"user_type": "admin"}'
);

-- Create corresponding public user
INSERT INTO users (email, user_type, first_name, last_name, is_active, email_verified)
VALUES ('admin@learned.com', 'admin', 'Test', 'Admin', true, true);
```

### 2. Test Invitation Flow

```javascript
// 1. Admin creates invitation
const invitation = await createInvitation({
    email: 'teacher@test.com',
    firstName: 'Jane',
    lastName: 'Doe',
    subject: 'Mathematics',
    gradeLevels: [1, 2, 3]
}, adminId);

// 2. Teacher receives email and clicks magic link
// 3. Teacher completes profile
// 4. Teacher can now login to mobile app
```

## 🚀 Deployment Checklist

- [ ] Database schema deployed
- [ ] Functions created and tested
- [ ] Email template configured
- [ ] URL redirects set up
- [ ] Web page deployed to `learned.com/teacher/onboard`
- [ ] Admin panel configured
- [ ] Test flow completed
- [ ] Mobile app login tested

## 🔐 Security Features

1. **JWT Validation**: Supabase handles all JWT security
2. **Email Verification**: Magic links confirm email ownership
3. **Admin Authorization**: Database functions verify admin permissions
4. **Time-Limited Invitations**: 7-day expiry on invitations
5. **Single-Use Links**: JWTs expire after 1 hour
6. **Audit Trail**: All operations logged in audit_logs table

This implementation provides enterprise-grade security while maintaining simplicity and leveraging Supabase's robust authentication system.