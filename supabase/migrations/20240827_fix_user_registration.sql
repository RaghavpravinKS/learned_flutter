-- Create a function to handle new user signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  first_name text;
  last_name text;
  user_type text;
BEGIN
  -- Extract user data from auth.users metadata
  first_name := COALESCE(NEW.raw_user_meta_data->>'first_name', split_part(NEW.raw_user_meta_data->>'full_name', ' ', 1));
  last_name := COALESCE(NEW.raw_user_meta_data->>'last_name', 
                       CASE 
                         WHEN array_length(string_to_array(NEW.raw_user_meta_data->>'full_name', ' '), 1) > 1 
                         THEN array_to_string((string_to_array(NEW.raw_user_meta_data->>'full_name', ' '))[2:], ' ')
                         ELSE ''
                       END);
  user_type := COALESCE(NEW.raw_user_meta_data->>'user_type', 'student');

  -- Insert into public.users table with proper error handling
  BEGIN
    INSERT INTO public.users (
      id, 
      email, 
      user_type, 
      first_name, 
      last_name, 
      is_active, 
      email_verified,
      created_at, 
      updated_at
    ) VALUES (
      NEW.id,
      NEW.email,
      user_type::user_type, -- Cast to enum type
      first_name,
      last_name,
      true,
      false,
      NOW(),
      NOW()
    );
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error creating user record: %', SQLERRM;
    -- Don't re-raise the error to prevent auth signup from failing
  END;

  -- Insert into user_profiles table
  BEGIN
    INSERT INTO public.user_profiles (user_id, created_at, updated_at)
    VALUES (NEW.id, NOW(), NOW())
    ON CONFLICT (user_id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error creating user profile: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_trigger 
    WHERE tgname = 'on_auth_user_created'
  ) THEN
    CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  END IF;
END $$;

-- Enable RLS on users table if not already enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for users table if they don't exist
DO $$
BEGIN
  -- Allow users to read their own data
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE tablename = 'users' 
    AND policyname = 'Allow users to read their own data'
  ) THEN
    CREATE POLICY "Allow users to read their own data"
    ON public.users
    FOR SELECT
    USING (auth.uid() = id);
  END IF;

  -- Allow users to update their own data
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_policies 
    WHERE tablename = 'users' 
    AND policyname = 'Allow users to update their own data'
  ) THEN
    CREATE POLICY "Allow users to update their own data"
    ON public.users
    FOR UPDATE
    USING (auth.uid() = id);
  END IF;
END $$;
