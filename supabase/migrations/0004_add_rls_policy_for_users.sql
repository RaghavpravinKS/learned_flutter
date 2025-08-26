-- Enable RLS on the public.users table if it's not already enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow individual insert access" ON public.users;
DROP POLICY IF EXISTS "Allow individual read access" ON public.users;

-- Create a policy that allows users to insert their own profile
CREATE POLICY "Allow individual insert access"
ON public.users
FOR INSERT
WITH CHECK (auth.uid() = id);

-- Create a policy that allows users to read their own profile
CREATE POLICY "Allow individual read access"
ON public.users
FOR SELECT
USING (auth.uid() = id);
