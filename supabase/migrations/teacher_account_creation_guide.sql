-- ========================================================================
-- TEACHER AUTH ACCOUNT CREATION GUIDE
-- ========================================================================
-- Since you don't have an admin console yet, here's how to create teacher accounts
-- ========================================================================

-- STEP 1: Create Teacher Auth Accounts
-- You have 3 options to create these accounts:

-- OPTION 1: Use Supabase Dashboard (Recommended)
-- 1. Go to Supabase Dashboard > Authentication > Users
-- 2. Click "Add User"
-- 3. Create these accounts:

/*
Teacher 1:
Email: sarah.johnson@learned.com
Password: TeacherSarah123!
User Metadata: {"user_type": "teacher", "first_name": "Dr. Sarah", "last_name": "Johnson"}

Teacher 2:
Email: michael.chen@learned.com  
Password: TeacherMichael123!
User Metadata: {"user_type": "teacher", "first_name": "Prof. Michael", "last_name": "Chen"}

Teacher 3:
Email: emily.rodriguez@learned.com
Password: TeacherEmily123!
User Metadata: {"user_type": "teacher", "first_name": "Dr. Emily", "last_name": "Rodriguez"}
*/

-- OPTION 2: Use the AdminUserService we created
-- Add this to your Flutter app debug menu and call it:

/*
await AdminUserService.createUserWithPassword(
  email: 'sarah.johnson@learned.com',
  password: 'TeacherSarah123!',
  userType: 'teacher',
  firstName: 'Dr. Sarah',
  lastName: 'Johnson',
);

await AdminUserService.createUserWithPassword(
  email: 'michael.chen@learned.com',
  password: 'TeacherMichael123!',
  userType: 'teacher',
  firstName: 'Prof. Michael',
  lastName: 'Chen',
);

await AdminUserService.createUserWithPassword(
  email: 'emily.rodriguez@learned.com',
  password: 'TeacherEmily123!',
  userType: 'teacher',
  firstName: 'Dr. Emily',
  lastName: 'Rodriguez',
);
*/

-- STEP 2: Get the Auth User IDs
-- After creating the auth accounts, run this query to get their IDs:

SELECT 
    'Auth User IDs for Teachers' as info,
    id as auth_user_id,
    email,
    user_metadata->>'first_name' as first_name,
    user_metadata->>'last_name' as last_name
FROM auth.users 
WHERE email IN (
    'sarah.johnson@learned.com',
    'michael.chen@learned.com', 
    'emily.rodriguez@learned.com'
)
ORDER BY email;

-- STEP 3: Update the setup script
-- Replace the placeholder IDs in setup_after_reset.sql with the actual IDs from above
-- Example replacements:
-- 'teacher-1-replace-with-auth-id' → actual ID for sarah.johnson@learned.com
-- 'teacher-2-replace-with-auth-id' → actual ID for michael.chen@learned.com  
-- 'teacher-3-replace-with-auth-id' → actual ID for emily.rodriguez@learned.com

-- ========================================================================
-- QUICK TEACHER CREATION SCRIPT (After getting real IDs)
-- ========================================================================
-- Use this template after you have the real auth user IDs:

/*
-- Example with real IDs (replace with your actual IDs):
UPDATE setup_after_reset.sql by replacing:

'teacher-1-replace-with-auth-id' WITH 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
'teacher-2-replace-with-auth-id' WITH 'b2c3d4e5-f6g7-8901-bcde-f23456789012' 
'teacher-3-replace-with-auth-id' WITH 'c3d4e5f6-g7h8-9012-cdef-345678901234'

Then run the updated setup_after_reset.sql script.
*/

SELECT 'Teacher account creation guide ready!' as status;
