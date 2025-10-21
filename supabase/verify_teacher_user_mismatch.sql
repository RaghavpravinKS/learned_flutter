-- Check if the authenticated user has a teacher record
-- Use the user_id from the Flutter app debug output

SELECT 
    'User from app:' as source,
    'd7be67fb-1a90-4184-b27c-d86357cc6648' as user_id;

-- Check what teacher records exist
SELECT 
    'Teachers in database:' as source,
    t.id as teacher_id,
    t.user_id,
    u.email,
    u.first_name,
    u.last_name
FROM teachers t
JOIN users u ON u.id = t.user_id;

-- Check if THIS specific user has a teacher record
SELECT 
    'Does app user have teacher record?' as question,
    t.id as teacher_id,
    t.user_id,
    u.email
FROM teachers t
JOIN users u ON u.id = t.user_id
WHERE t.user_id = 'd7be67fb-1a90-4184-b27c-d86357cc6648';

-- If no result above, we need to create a teacher record for this user
-- Check the user exists
SELECT 
    'User exists in users table?' as question,
    id,
    email,
    first_name,
    last_name
FROM users
WHERE id = 'd7be67fb-1a90-4184-b27c-d86357cc6648';
