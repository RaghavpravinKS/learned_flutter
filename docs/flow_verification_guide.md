# Complete Flow Verification Guide
## Step-by-Step Database Reset and Testing

### Phase 1: Database Reset
1. **Reset Database Tables**
   ```sql
   -- Run this file in Supabase SQL Editor:
   /supabase/migrations/reset_for_verification.sql
   ```

2. **Delete Auth Users** (Manual step required)
   - Go to Supabase Dashboard > Authentication > Users
   - Select all users and delete them
   - This clears the auth.users table

### Phase 2: Setup Test Data
1. **Quick Setup with Generated Teacher IDs**
   ```sql
   -- Run this file in Supabase SQL Editor:
   /supabase/migrations/quick_setup_with_teachers.sql
   ```

2. **Create Teacher Auth Accounts** (Choose one method)
   
   **Method A: Supabase Dashboard**
   - Go to Authentication > Users > Add User
   - Create these exact accounts:
     - Email: `sarah.johnson@learned.com`, ID: `11111111-2222-3333-4444-555555555555`
     - Email: `michael.chen@learned.com`, ID: `22222222-3333-4444-5555-666666666666`
     - Email: `emily.rodriguez@learned.com`, ID: `33333333-4444-5555-6666-777777777777`
   
   **Method B: Flutter App AdminUserService**
   - Open Flutter app and use debug tools to create teacher accounts

### Phase 3: Verify Setup
1. **Check Database Population**
   ```sql
   -- Verify teachers exist
   SELECT COUNT(*) as teacher_count FROM public.teachers WHERE status = 'active';
   
   -- Verify classrooms exist  
   SELECT COUNT(*) as classroom_count FROM public.classrooms WHERE is_active = true;
   
   -- Verify payment plans exist
   SELECT COUNT(*) as plan_count FROM public.payment_plans WHERE is_active = true;
   ```

2. **Check Teacher-Classroom Relationships**
   ```sql
   SELECT 
       CONCAT(u.first_name, ' ', u.last_name) as teacher_name,
       COUNT(c.id) as classroom_count,
       STRING_AGG(c.name, ', ') as classrooms
   FROM public.teachers t
   JOIN public.users u ON t.user_id = u.id
   LEFT JOIN public.classrooms c ON c.teacher_id = t.id
   WHERE t.status = 'active'
   GROUP BY t.id, u.first_name, u.last_name;
   ```

### Phase 4: Complete Student Flow Testing

#### 4.1 Student Registration Flow
1. **Clear app data** and restart Flutter app
2. **Register new student account** using the app
3. **Complete profile setup** with all required fields
4. **Verify authentication persistence** by closing/reopening app

#### 4.2 Enrollment Flow Testing
1. **Browse available classrooms** - should show 6 classrooms from 3 teachers
2. **Select a classroom** and proceed to payment
3. **Use payment bypass** (development mode) to enroll
4. **Verify enrollment success** message

#### 4.3 Data Persistence Verification
1. **Check "My Classes" page** - enrolled classroom should appear
2. **Verify teacher information** - should show actual teacher name, not "Unknown Teacher"
3. **Close and reopen app** - verify enrolled classes persist
4. **Check profile page** - verify student data persists

#### 4.4 Debug Tools Verification
1. **Dashboard Debug** - Use drawer menu debug option to check auth state
2. **Profile Debug** - Use AppBar debug button to verify student data
3. **My Classes Debug** - Use floating debug button to verify enrollment data
4. **Flow Verification** - Use comprehensive flow verification tool

### Phase 5: Database Verification Queries

#### 5.1 Check Student Creation
```sql
-- Verify student was created
SELECT 
    u.email,
    u.first_name,
    u.last_name,
    s.student_id,
    s.grade_level,
    s.board,
    s.created_at
FROM public.students s
JOIN public.users u ON s.user_id = u.id
ORDER BY s.created_at DESC
LIMIT 5;
```

#### 5.2 Check Enrollment Data
```sql
-- Verify enrollment was recorded
SELECT 
    e.enrollment_id,
    CONCAT(u.first_name, ' ', u.last_name) as student_name,
    c.name as classroom_name,
    CONCAT(tu.first_name, ' ', tu.last_name) as teacher_name,
    p.payment_status,
    e.enrollment_date
FROM public.enrollments e
JOIN public.students s ON e.student_id = s.id
JOIN public.users u ON s.user_id = u.id
JOIN public.classrooms c ON e.classroom_id = c.id
JOIN public.teachers t ON c.teacher_id = t.id
JOIN public.users tu ON t.user_id = tu.id
LEFT JOIN public.payments p ON e.id = p.enrollment_id
ORDER BY e.enrollment_date DESC;
```

#### 5.3 Check Payment Records
```sql
-- Verify payment was processed
SELECT 
    p.payment_id,
    p.amount,
    p.currency,
    p.payment_method,
    p.payment_status,
    p.transaction_id,
    CONCAT(u.first_name, ' ', u.last_name) as student_name
FROM public.payments p
JOIN public.enrollments e ON p.enrollment_id = e.id
JOIN public.students s ON e.student_id = s.id
JOIN public.users u ON s.user_id = u.id
ORDER BY p.payment_date DESC;
```

### Expected Results After Complete Flow
- ✅ Student account created and authenticated
- ✅ Student profile completed and persisting
- ✅ Classroom enrollment successful
- ✅ Payment record created (bypass mode)
- ✅ "My Classes" shows enrolled classroom with correct teacher name
- ✅ All data persists across app restarts
- ✅ Debug tools show consistent authentication and data state

### Troubleshooting Common Issues

#### Issue: "Unknown Teacher" still showing
- Check that teacher auth accounts were created with exact UUIDs from quick_setup_with_teachers.sql
- Verify teacher_id in classrooms table matches teacher.id

#### Issue: Authentication not persisting
- Verify splash screen routing is working correctly
- Check that Supabase client is properly initialized

#### Issue: No enrolled classes showing
- Use debug tools to check authentication state
- Verify enrollment records exist in database
- Check ClassroomService.getEnrolledClassrooms is using correct student ID

### Success Criteria
✅ Complete student registration → profile → enrollment → persistence flow working  
✅ Teacher names displaying correctly instead of "Unknown Teacher"  
✅ Authentication persisting across app restarts  
✅ All database relationships properly established  
✅ Debug tools providing accurate state information
