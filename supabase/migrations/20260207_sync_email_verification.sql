-- =============================================
-- SYNC EMAIL VERIFICATION STATUS
-- =============================================
-- This trigger automatically updates public.users when email is verified in auth.users

CREATE OR REPLACE FUNCTION sync_email_verification()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if email_confirmed_at was just updated (from NULL to a timestamp)
    IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
        -- Update public.users table
        UPDATE public.users
        SET 
            email_verified = true,
            email_confirmed_at = NEW.email_confirmed_at,
            updated_at = now()
        WHERE id = NEW.id;
        
        -- Log the verification
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES (
            'Email verification synced to public.users',
            jsonb_build_object(
                'user_id', NEW.id,
                'email', NEW.email,
                'confirmed_at', NEW.email_confirmed_at
            )
        );
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES (
            'Error syncing email verification',
            SQLERRM,
            jsonb_build_object('user_id', NEW.id, 'email', NEW.email)
        );
        RETURN NEW; -- Don't block the auth update
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_email_verified ON auth.users;

-- Create trigger on auth.users UPDATE
CREATE TRIGGER on_auth_user_email_verified
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    WHEN (OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at)
    EXECUTE FUNCTION sync_email_verification();

-- Log migration completion
INSERT INTO public.trigger_logs (message, metadata)
VALUES (
    'Email verification sync trigger created',
    jsonb_build_object(
        'migration', '20260207_sync_email_verification',
        'created_at', now()
    )
);
