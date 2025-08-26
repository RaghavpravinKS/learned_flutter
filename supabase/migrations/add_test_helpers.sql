-- Helper functions for testing

CREATE OR REPLACE FUNCTION create_test_user(p_user_type TEXT) 
RETURNS TABLE (id UUID, email TEXT)
AS $$
DECLARE
    test_email TEXT;
    new_user_id UUID;
BEGIN
    test_email := 'test_' || p_user_type || '_' || extract(epoch from now())::bigint || '@test.com';

    -- Create an auth user
    new_user_id := auth.uid() FROM auth.users WHERE auth.users.email = test_email;
    IF new_user_id IS NULL THEN
        INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_token, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_sent_at, confirmed_at)
        VALUES (current_setting('app.instance_id')::uuid, gen_random_uuid(), 'authenticated', 'authenticated', test_email, crypt('password123', gen_salt('bf')), now(), '', now(), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', now(), now())
        RETURNING auth.users.id INTO new_user_id;
    END IF;

    -- Create a public user
    INSERT INTO public.users (id, email, user_type, first_name, last_name, password_hash)
    VALUES (new_user_id, test_email, p_user_type, 'Test', 'User', crypt('password123', gen_salt('bf')));

    RETURN QUERY SELECT new_user_id, test_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_test_student()
RETURNS TABLE (id UUID, user_id UUID)
AS $$
DECLARE
    new_user RECORD;
BEGIN
    SELECT * INTO new_user FROM create_test_user('student');

    RETURN QUERY 
    INSERT INTO public.students (user_id, student_id, learning_goals)
    VALUES (new_user.id, 'temp-' || left(new_user.id::text, 8), 'Test goals')
    RETURNING students.id, students.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION create_test_teacher()
RETURNS TABLE (id UUID, user_id UUID)
AS $$
DECLARE
    new_user RECORD;
BEGIN
    SELECT * INTO new_user FROM create_test_user('teacher');

    RETURN QUERY
    INSERT INTO public.teachers (user_id, teacher_id, qualifications)
    VALUES (new_user.id, 'temp-' || left(new_user.id::text, 8), 'Test qualifications')
    RETURNING teachers.id, teachers.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
