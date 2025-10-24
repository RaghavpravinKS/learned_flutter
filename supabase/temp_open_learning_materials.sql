-- Temporary super simple policy for debugging
-- This removes all security - ONLY FOR TESTING

-- Drop existing policies
DROP POLICY IF EXISTS "Teachers can view materials for their classrooms" ON learning_materials;
DROP POLICY IF EXISTS "Teachers can insert materials for their classrooms" ON learning_materials;
DROP POLICY IF EXISTS "Teachers can update their own materials" ON learning_materials;
DROP POLICY IF EXISTS "Teachers can delete their own materials" ON learning_materials;
DROP POLICY IF EXISTS "Students can view materials for enrolled classrooms" ON learning_materials;
DROP POLICY IF EXISTS "Allow all authenticated to view" ON learning_materials;
DROP POLICY IF EXISTS "Allow all authenticated to insert" ON learning_materials;
DROP POLICY IF EXISTS "Allow all authenticated to delete" ON learning_materials;

-- Create super simple policies - any authenticated user can do anything
CREATE POLICY "Allow all authenticated to view"
ON learning_materials FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow all authenticated to insert"
ON learning_materials FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow all authenticated to delete"
ON learning_materials FOR DELETE
TO authenticated
USING (true);

-- Check if there's actually data in the table
SELECT COUNT(*) as total_materials FROM learning_materials;

-- Show the data
SELECT id, title, classroom_id, teacher_id, created_at FROM learning_materials;
