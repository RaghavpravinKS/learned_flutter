-- Enable RLS for the required tables
ALTER TABLE public.classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classroom_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_plans ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to view active classrooms" ON public.classrooms;
DROP POLICY IF EXISTS "Allow authenticated users to view classroom pricing" ON public.classroom_pricing;
DROP POLICY IF EXISTS "Allow authenticated users to view payment plans" ON public.payment_plans;

-- Create policies to allow read access
CREATE POLICY "Allow authenticated users to view active classrooms"
ON public.classrooms
FOR SELECT
TO authenticated
USING (is_active = true);

CREATE POLICY "Allow authenticated users to view classroom pricing"
ON public.classroom_pricing
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow authenticated users to view payment plans"
ON public.payment_plans
FOR SELECT
TO authenticated
USING (true);
