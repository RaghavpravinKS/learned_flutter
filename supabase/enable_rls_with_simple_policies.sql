-- Re-enable RLS with working policies

-- Step 1: Re-enable RLS
ALTER TABLE learning_materials ENABLE ROW LEVEL SECURITY;

-- Step 2: Create simple, working policies

-- Allow all authenticated users to SELECT (read)
CREATE POLICY "Authenticated users can view all materials"
ON learning_materials FOR SELECT
TO authenticated
USING (true);

-- Allow all authenticated users to INSERT (create)
CREATE POLICY "Authenticated users can insert materials"
ON learning_materials FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow all authenticated users to UPDATE (edit)
CREATE POLICY "Authenticated users can update materials"
ON learning_materials FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow all authenticated users to DELETE (remove)
CREATE POLICY "Authenticated users can delete materials"
ON learning_materials FOR DELETE
TO authenticated
USING (true);

-- Verify policies
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'learning_materials';
