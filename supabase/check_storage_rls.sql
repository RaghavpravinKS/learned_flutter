-- Step 1: Check current storage policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
ORDER BY policyname;

-- Step 2: Check if there are any restrictive (non-permissive) policies
SELECT 
  policyname,
  permissive,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND permissive = 'RESTRICTIVE';

-- Step 3: Temporarily disable RLS on storage.objects for testing
-- WARNING: This removes all security - only for debugging!
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- After testing, re-enable it:
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
