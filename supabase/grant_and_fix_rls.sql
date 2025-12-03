-- ============================================================================
-- FIX: Grant table permissions and simplify RLS
-- The issue might be missing GRANT permissions
-- ============================================================================

-- 1. Grant permissions to authenticated users
GRANT ALL ON public.recurring_sessions TO authenticated;
GRANT ALL ON public.recurring_sessions TO service_role;

-- 2. Ensure RLS is enabled
ALTER TABLE public.recurring_sessions ENABLE ROW LEVEL SECURITY;

-- 3. Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "Teachers can view recurring sessions for their classrooms" ON public.recurring_sessions;
DROP POLICY IF EXISTS "Teachers can create recurring sessions" ON public.recurring_sessions;
DROP POLICY IF EXISTS "Teachers can update recurring sessions" ON public.recurring_sessions;
DROP POLICY IF EXISTS "Teachers can delete recurring sessions" ON public.recurring_sessions;
DROP POLICY IF EXISTS "temp_allow_all_authenticated" ON public.recurring_sessions;

-- 4. Create simple, clear policies
-- SELECT: Teachers can see recurring sessions for their classrooms
CREATE POLICY "select_own_classrooms"
  ON public.recurring_sessions
  FOR SELECT
  TO authenticated
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      JOIN teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );

-- INSERT: Teachers can create recurring sessions for their classrooms
CREATE POLICY "insert_own_classrooms"
  ON public.recurring_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      JOIN teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );

-- UPDATE: Teachers can update recurring sessions for their classrooms
CREATE POLICY "update_own_classrooms"
  ON public.recurring_sessions
  FOR UPDATE
  TO authenticated
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      JOIN teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );

-- DELETE: Teachers can delete recurring sessions for their classrooms
CREATE POLICY "delete_own_classrooms"
  ON public.recurring_sessions
  FOR DELETE
  TO authenticated
  USING (
    classroom_id IN (
      SELECT c.id 
      FROM classrooms c
      JOIN teachers t ON c.teacher_id = t.id
      WHERE t.user_id = auth.uid()
    )
  );

-- 5. Verify setup
SELECT 'Table grants:' as info;
SELECT 
  grantee, 
  privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'recurring_sessions'
ORDER BY grantee, privilege_type;

SELECT 'RLS enabled:' as info;
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'recurring_sessions';

SELECT 'Active policies:' as info;
SELECT 
  policyname,
  cmd AS operation,
  roles
FROM pg_policies
WHERE tablename = 'recurring_sessions'
ORDER BY cmd;
