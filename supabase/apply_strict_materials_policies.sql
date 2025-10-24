-- Apply strict RLS policies for learning_materials

-- Step 1: Drop the simple open policies
DROP POLICY IF EXISTS "Authenticated users can view all materials" ON learning_materials;
DROP POLICY IF EXISTS "Authenticated users can insert materials" ON learning_materials;
DROP POLICY IF EXISTS "Authenticated users can update materials" ON learning_materials;
DROP POLICY IF EXISTS "Authenticated users can delete materials" ON learning_materials;

-- Step 2: Create strict policies

-- Policy 1: Teachers can only view their own materials
CREATE POLICY "Teachers can view their own materials"
ON learning_materials FOR SELECT
TO authenticated
USING (
  teacher_id IN (
    SELECT id FROM teachers WHERE user_id = auth.uid()
  )
);

-- Policy 2: Teachers can only insert materials for classrooms they own
CREATE POLICY "Teachers can insert materials for their classrooms"
ON learning_materials FOR INSERT
TO authenticated
WITH CHECK (
  teacher_id IN (
    SELECT id FROM teachers WHERE user_id = auth.uid()
  )
  AND
  classroom_id IN (
    SELECT c.id FROM classrooms c
    INNER JOIN teachers t ON c.teacher_id = t.id
    WHERE t.user_id = auth.uid()
  )
);

-- Policy 3: Teachers can only update their own materials
CREATE POLICY "Teachers can update their own materials"
ON learning_materials FOR UPDATE
TO authenticated
USING (
  teacher_id IN (
    SELECT id FROM teachers WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  teacher_id IN (
    SELECT id FROM teachers WHERE user_id = auth.uid()
  )
);

-- Policy 4: Teachers can only delete their own materials
CREATE POLICY "Teachers can delete their own materials"
ON learning_materials FOR DELETE
TO authenticated
USING (
  teacher_id IN (
    SELECT id FROM teachers WHERE user_id = auth.uid()
  )
);

-- Policy 5: Students can view public materials from enrolled classrooms
CREATE POLICY "Students can view enrolled classroom materials"
ON learning_materials FOR SELECT
TO authenticated
USING (
  (is_public = true OR is_public IS NULL)
  AND
  classroom_id IN (
    SELECT se.classroom_id 
    FROM student_enrollments se
    INNER JOIN students s ON se.student_id = s.id
    WHERE s.user_id = auth.uid()
    AND se.status = 'active'
  )
);

-- Verify policies
SELECT policyname, cmd, roles FROM pg_policies WHERE tablename = 'learning_materials' ORDER BY policyname;
