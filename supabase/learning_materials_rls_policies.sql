-- Complete reset and recreation of learning_materials table with RLS policies

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "Teachers can view materials for their classrooms" ON learning_materials;
DROP POLICY IF EXISTS "Teachers can insert materials for their classrooms" ON learning_materials;
DROP POLICY IF EXISTS "Teachers can update their own materials" ON learning_materials;
DROP POLICY IF EXISTS "Teachers can delete their own materials" ON learning_materials;
DROP POLICY IF EXISTS "Students can view materials for enrolled classrooms" ON learning_materials;

-- Step 2: Disable RLS temporarily
ALTER TABLE learning_materials DISABLE ROW LEVEL SECURITY;

-- Step 3: Drop and recreate the table
DROP TABLE IF EXISTS learning_materials CASCADE;

CREATE TABLE learning_materials (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  classroom_id character varying NOT NULL,
  title character varying NOT NULL,
  description text,
  material_type character varying NOT NULL CHECK (material_type::text = ANY (ARRAY['note'::character varying, 'video'::character varying, 'document'::character varying, 'presentation'::character varying, 'assignment'::character varying, 'recording'::character varying]::text[])),
  file_url text,
  file_size bigint,
  mime_type character varying,
  is_public boolean DEFAULT false,
  tags text[],
  upload_date timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT learning_materials_pkey PRIMARY KEY (id),
  CONSTRAINT learning_materials_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE,
  CONSTRAINT learning_materials_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- Step 4: Enable RLS
ALTER TABLE learning_materials ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies

-- Policy 1: Teachers can view materials for classrooms they teach (SIMPLIFIED)
CREATE POLICY "Teachers can view materials for their classrooms"
ON learning_materials FOR SELECT
TO authenticated
USING (
  teacher_id IN (
    SELECT id FROM teachers WHERE user_id = auth.uid()
  )
);

-- Policy 2: Teachers can insert materials for their classrooms
CREATE POLICY "Teachers can insert materials for their classrooms"
ON learning_materials FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM teachers t
    INNER JOIN classrooms c ON c.teacher_id = t.id
    WHERE t.user_id = auth.uid()
    AND c.id = learning_materials.classroom_id
    AND t.id = learning_materials.teacher_id
  )
);

-- Policy 3: Teachers can update their own materials
CREATE POLICY "Teachers can update their own materials"
ON learning_materials FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM teachers
    WHERE teachers.user_id = auth.uid()
    AND teachers.id = learning_materials.teacher_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM teachers
    WHERE teachers.user_id = auth.uid()
    AND teachers.id = learning_materials.teacher_id
  )
);

-- Policy 4: Teachers can delete their own materials
CREATE POLICY "Teachers can delete their own materials"
ON learning_materials FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM teachers
    WHERE teachers.user_id = auth.uid()
    AND teachers.id = learning_materials.teacher_id
  )
);

-- Policy 5: Students can view materials for classrooms they are enrolled in
CREATE POLICY "Students can view materials for enrolled classrooms"
ON learning_materials FOR SELECT
TO authenticated
USING (
  (is_public = true OR is_public IS NULL) AND
  EXISTS (
    SELECT 1 FROM students s
    INNER JOIN student_enrollments se ON se.student_id = s.id
    WHERE s.user_id = auth.uid()
    AND se.classroom_id = learning_materials.classroom_id
    AND se.status = 'active'
  )
);

-- Step 6: Verify policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'learning_materials'
ORDER BY policyname;
