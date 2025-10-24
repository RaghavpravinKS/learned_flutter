-- Storage policies for student assignment submissions
-- This allows students to upload files to the learning-materials bucket under assignments folder

-- Enable RLS on storage.objects (should already be enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Students can upload assignment submissions
-- Allows INSERT into paths like: assignments/{assignment_id}/{filename}
CREATE POLICY "Students can upload assignment submissions"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'learning-materials' AND
  (storage.foldername(name))[1] = 'assignments' AND
  EXISTS (
    SELECT 1 FROM public.students s
    WHERE s.user_id = auth.uid()
  )
);

-- Policy 2: Students can read their own assignment submissions
CREATE POLICY "Students can read own submissions"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'learning-materials' AND
  (storage.foldername(name))[1] = 'assignments' AND
  EXISTS (
    SELECT 1 FROM public.students s
    WHERE s.user_id = auth.uid()
    AND name LIKE '%' || s.id::text || '%'
  )
);

-- Policy 3: Teachers can read all assignment submissions in their classrooms
CREATE POLICY "Teachers can read classroom assignment submissions"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'learning-materials' AND
  (storage.foldername(name))[1] = 'assignments' AND
  EXISTS (
    SELECT 1 FROM public.teachers t
    INNER JOIN public.assignments a ON a.teacher_id = t.id
    WHERE t.user_id = auth.uid()
    AND (storage.foldername(name))[2] = a.id::text
  )
);

-- Verify the policies were created
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%assignment%';
