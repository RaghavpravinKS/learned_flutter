# LearnED Complete Flow Verification Checklist

## 🎯 **Overview**
This document outlines the complete verification process for the LearnED app user registration and enrollment flow.

## 📋 **Verification Steps**

### **Phase 1: User Registration Flow**

#### **1.1 Student Registration**
- [ ] User selects "Student" during registration
- [ ] User provides: email, password, first name, last name
- [ ] User is created in `auth.users` (Supabase Auth)
- [ ] User record is created in `public.users` table with `user_type = 'student'`
- [ ] Student record is created in `public.students` table
- [ ] User receives email verification (if enabled)

**Database Checks:**
```sql
-- Verify user in auth.users
SELECT id, email, email_confirmed_at FROM auth.users WHERE email = 'test.email@example.com';

-- Verify user in public.users
SELECT id, first_name, last_name, email, user_type FROM public.users WHERE email = 'test.email@example.com';

-- Verify student record
SELECT id, user_id, student_id, grade_level, school_name, status FROM public.students WHERE user_id = 'user_id_here';
```

#### **1.2 Teacher Registration**
- [ ] User selects "Teacher" during registration
- [ ] User provides: email, password, first name, last name
- [ ] User is created in `auth.users` (Supabase Auth)
- [ ] User record is created in `public.users` table with `user_type = 'teacher'`
- [ ] Teacher record is created in `public.teachers` table
- [ ] User receives email verification (if enabled)

**Database Checks:**
```sql
-- Verify teacher record
SELECT id, user_id, teacher_id, qualifications, experience_years, status FROM public.teachers WHERE user_id = 'user_id_here';
```

#### **1.3 Parent Registration**
- [ ] User selects "Parent" during registration
- [ ] User provides: email, password, first name, last name
- [ ] User is created in `auth.users` (Supabase Auth)
- [ ] User record is created in `public.users` table with `user_type = 'parent'`
- [ ] Parent record is created in `public.parents` table (if exists)
- [ ] User receives email verification (if enabled)

### **Phase 2: Profile Completion**

#### **2.1 Student Profile Completion**
- [ ] Student can access profile edit page
- [ ] Student can add/edit: phone number, school name, grade level
- [ ] Changes are saved to `public.students` table
- [ ] Profile shows real data (not hardcoded)

**Database Checks:**
```sql
-- Verify profile data
SELECT student_id, grade_level, school_name, phone FROM public.students 
JOIN public.users ON students.user_id = users.id 
WHERE users.email = 'student.email@example.com';
```

#### **2.2 Teacher Profile Completion**
- [ ] Teacher can access profile edit page
- [ ] Teacher can add/edit: phone number, qualifications, experience
- [ ] Changes are saved to `public.teachers` table
- [ ] Profile shows real data (not hardcoded)

### **Phase 3: Authentication & Session Management**

#### **3.1 Login Flow**
- [ ] User can login with email/password
- [ ] Session is created and persisted
- [ ] User is redirected to appropriate dashboard based on user_type
- [ ] Session persists across app restarts (splash screen check)

#### **3.2 Logout Flow**
- [ ] User can logout successfully
- [ ] Session is cleared from local storage
- [ ] User is redirected to welcome/login screen
- [ ] Next app start shows login screen (not dashboard)

### **Phase 4: Classroom & Enrollment Flow**

#### **4.1 Classroom Discovery**
- [ ] Student can browse available classrooms
- [ ] Classrooms show real teacher names (not "Unknown Teacher")
- [ ] Classroom details are populated from database

#### **4.2 Payment Integration**
- [ ] Student can initiate classroom enrollment
- [ ] Payment flow works (simulation mode)
- [ ] Payment record is created in `public.payments` table
- [ ] Payment status is tracked correctly

**Database Checks:**
```sql
-- Verify payment record
SELECT id, student_id, amount, payment_status, payment_method, created_at 
FROM public.payments 
WHERE student_id = 'student_id_here' 
ORDER BY created_at DESC;
```

#### **4.3 Enrollment Process**
- [ ] After successful payment, enrollment is created
- [ ] Record is added to `public.student_classroom_assignments`
- [ ] Enrollment shows in "My Classes" immediately
- [ ] Teacher name is displayed correctly
- [ ] Progress tracking is initialized

**Database Checks:**
```sql
-- Verify enrollment
SELECT sca.id, sca.enrolled_date, sca.status, sca.progress,
       c.name as classroom_name,
       CONCAT(u.first_name, ' ', u.last_name) as teacher_name
FROM public.student_classroom_assignments sca
JOIN public.classrooms c ON sca.classroom_id = c.id
JOIN public.teachers t ON sca.teacher_id = t.id
JOIN public.users u ON t.user_id = u.id
WHERE sca.student_id = 'student_id_here';
```

### **Phase 5: Data Consistency Checks**

#### **5.1 User Type Consistency**
- [ ] User type in `auth.users.user_metadata` matches `public.users.user_type`
- [ ] Appropriate role-specific record exists (student/teacher/parent)
- [ ] User can only access features appropriate to their role

#### **5.2 Foreign Key Integrity**
- [ ] All `user_id` references point to valid users
- [ ] All `classroom_id` references point to valid classrooms
- [ ] All `teacher_id` references point to valid teachers
- [ ] All `student_id` references point to valid students

#### **5.3 Authentication State**
- [ ] Current user detection works across all screens
- [ ] Debug tools show correct authentication status
- [ ] User data is fetched based on authenticated user (not hardcoded)

## 🧪 **Testing Tools We've Built**

### **Debug Authentication (Available on all screens)**
- Dashboard: Side menu → "Debug Authentication"
- Profile: AppBar → Bug icon
- Edit Profile: AppBar → Bug icon  
- My Classes: Floating action button (bug icon)

### **Database Debug Queries**
```sql
-- Complete user verification
SELECT 
  au.id as auth_id,
  au.email as auth_email,
  au.user_metadata,
  pu.id as public_user_id,
  pu.user_type,
  pu.first_name,
  pu.last_name,
  CASE 
    WHEN pu.user_type = 'student' THEN (SELECT COUNT(*) FROM public.students WHERE user_id = pu.id)
    WHEN pu.user_type = 'teacher' THEN (SELECT COUNT(*) FROM public.teachers WHERE user_id = pu.id)
    WHEN pu.user_type = 'parent' THEN (SELECT COUNT(*) FROM public.parents WHERE user_id = pu.id)
  END as role_record_exists
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE au.email = 'user.email@example.com';
```

## 🚀 **Verification Execution Plan**

### **Step 1: Registration Testing**
1. Test student registration with new email
2. Verify database records are created
3. Test teacher registration
4. Test parent registration

### **Step 2: Profile Testing**
1. Complete student profile with real data
2. Verify profile data persistence
3. Check profile display (no hardcoded data)

### **Step 3: Authentication Testing**
1. Test login/logout cycle
2. Verify session persistence
3. Test authentication state detection

### **Step 4: Enrollment Testing**
1. Browse classrooms as student
2. Complete payment simulation
3. Verify enrollment creation
4. Check "My Classes" display

### **Step 5: Data Integrity Testing**
1. Run database consistency checks
2. Verify foreign key relationships
3. Test user type routing

## 📊 **Success Criteria**

✅ **Complete Success**: All checkboxes above are checked
✅ **No hardcoded data**: All user-specific data comes from database
✅ **Proper user routing**: Users see appropriate features for their role
✅ **Data persistence**: Changes are saved and retrieved correctly
✅ **Authentication flow**: Login state is properly managed

## 🔄 **Next Steps After Verification**

1. Fix any issues found during verification
2. Add missing profile fields collection
3. Enhance user type specific features
4. Add proper error handling for edge cases
5. Implement proper user role permissions

---

*Last Updated: September 6, 2025*
