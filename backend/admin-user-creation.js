// This would be in your backend (Node.js, Python, etc.)
// NOT in your Flutter app

import { createClient } from '@supabase/supabase-js'

// Use SERVICE ROLE KEY (not anon key) for admin operations
const supabase = createClient(
  'your-supabase-url',
  'your-service-role-key' // This can create users without signup
)

// Create user with admin API
async function createAdminUser(email, password, userData) {
  try {
    // This bypasses email confirmation and creates user directly
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Skip email verification
      user_metadata: {
        user_type: userData.user_type,
        first_name: userData.first_name,
        last_name: userData.last_name
      }
    })

    if (authError) throw authError

    // Create public.users record
    const { error: publicUserError } = await supabase
      .from('users')
      .insert({
        id: authUser.user.id,
        email: email,
        ...userData
      })

    if (publicUserError) throw publicUserError

    console.log('✅ Admin user created:', email)
    return authUser.user
  } catch (error) {
    console.error('❌ Error creating admin user:', error)
    throw error
  }
}

// Usage
await createAdminUser('admin@school.com', 'SecurePassword123!', {
  user_type: 'admin',
  first_name: 'System',
  last_name: 'Administrator'
})
