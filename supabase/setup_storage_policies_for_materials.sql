-- Storage RLS Policies for learning-materials bucket
-- This fixes the "403 Unauthorized" error when uploading materials

-- First, ensure the bucket exists (skip if already created)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'learning-materials',
  'learning-materials',
  false,
  52428800, -- 50MB limit
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'video/mp4', 'video/webm', 
        'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Teachers can upload learning materials" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can read own materials" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can update own materials" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can delete own materials" ON storage.objects;
DROP POLICY IF EXISTS "Students can read classroom materials" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can read learning materials" ON storage.objects;

-- Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Teachers can upload files to their classrooms
-- Allows INSERT into paths like: classrooms/{classroom_id}/{filename}
CREATE POLICY "Teachers can upload learning materials"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'learning-materials' AND
  (storage.foldername(name))[1] = 'classrooms' AND
  EXISTS (
    SELECT 1 FROM public.teachers t
    INNER JOIN public.classrooms c ON c.teacher_id = t.id
    WHERE t.user_id = auth.uid()
    AND c.id::text = (storage.foldername(name))[2]
  )
);

-- Policy 2: Teachers can read their own classroom materials
CREATE POLICY "Teachers can read own materials"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'learning-materials' AND
  (storage.foldername(name))[1] = 'classrooms' AND
  EXISTS (
    SELECT 1 FROM public.teachers t
    INNER JOIN public.classrooms c ON c.teacher_id = t.id
    WHERE t.user_id = auth.uid()
    AND c.id::text = (storage.foldername(name))[2]
  )
);

-- Policy 3: Teachers can update their own classroom materials
CREATE POLICY "Teachers can update own materials"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'learning-materials' AND
  (storage.foldername(name))[1] = 'classrooms' AND
  EXISTS (
    SELECT 1 FROM public.teachers t
    INNER JOIN public.classrooms c ON c.teacher_id = t.id
    WHERE t.user_id = auth.uid()
    AND c.id::text = (storage.foldername(name))[2]
  )
);

-- Policy 4: Teachers can delete their own classroom materials
CREATE POLICY "Teachers can delete own materials"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'learning-materials' AND
  (storage.foldername(name))[1] = 'classrooms' AND
  EXISTS (
    SELECT 1 FROM public.teachers t
    INNER JOIN public.classrooms c ON c.teacher_id = t.id
    WHERE t.user_id = auth.uid()
    AND c.id::text = (storage.foldername(name))[2]
  )
);

-- Policy 5: Students can read materials from enrolled classrooms
CREATE POLICY "Students can read classroom materials"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'learning-materials' AND
  (storage.foldername(name))[1] = 'classrooms' AND
  EXISTS (
    SELECT 1 FROM public.students s
    INNER JOIN public.student_enrollments se ON se.student_id = s.id
    WHERE s.user_id = auth.uid()
    AND se.classroom_id::text = (storage.foldername(name))[2]
    AND se.status = 'active'
  )
);

-- Alternative simpler policy (if the above is too restrictive):
-- Uncomment this and comment out the above policies if you want all authenticated users to read
-- CREATE POLICY "Authenticated users can read learning materials"
-- ON storage.objects
-- FOR SELECT
-- TO authenticated
-- USING (bucket_id = 'learning-materials');

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%materials%'
ORDER BY policyname;
