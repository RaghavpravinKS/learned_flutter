-- Complete fix for storage policies
-- If you can't run this directly, you may need to:
-- 1. Use Supabase CLI: supabase db push
-- 2. Contact Supabase support to run this
-- 3. Delete all policies via UI and recreate them

-- Drop all existing policies on storage.objects for learning-materials
DROP POLICY IF EXISTS "Teachers can upload learning materials ud4rbt_0" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can read own materials ud4rbt_0" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can delete own materials ud4rbt_0" ON storage.objects;
DROP POLICY IF EXISTS "Students can read classroom materials ud4rbt_0" ON storage.objects;

-- Create new simplified policy for teachers to upload
CREATE POLICY "Teachers upload to learning-materials"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'learning-materials' AND
  auth.role() = 'authenticated'
);

-- Policy for teachers to read
CREATE POLICY "Teachers read learning-materials"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'learning-materials' AND
  auth.role() = 'authenticated'
);

-- Policy for teachers to delete
CREATE POLICY "Teachers delete learning-materials"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'learning-materials' AND
  auth.role() = 'authenticated'
);

-- Verify policies
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%learning-materials%';
