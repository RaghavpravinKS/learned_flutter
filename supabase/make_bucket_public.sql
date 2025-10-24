-- Make profile-images bucket public so images can be displayed
-- The bucket needs to be public for public URLs to work

-- Check current bucket configuration
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets 
WHERE id = 'profile-images';

-- Update bucket to be public
UPDATE storage.buckets
SET public = true
WHERE id = 'profile-images';

-- Verify the change
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets 
WHERE id = 'profile-images';
