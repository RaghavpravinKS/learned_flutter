# Student Flow Verification Test Script

## Overview
This script provides a comprehensive testing pathway for the completed student flow in the LearnED Flutter application.

## Prerequisites
1. **Database Setup**: Ensure the database has been set up with teacher data using the migration files:
   - `quick_setup_with_teachers.sql` - Creates teacher accounts and classrooms
   - Ensure teacher auth accounts are created with matching UUIDs

2. **Flutter Environment**: Ensure the Flutter app can be built and run

## Complete Student Flow Test

### Phase 1: Student Registration
1. **Clear App Data** (if testing on device/emulator)
   - Clear app data or uninstall/reinstall the app
   - This ensures a clean testing environment

2. **Start Registration Process**
   - Open the app
   - Should show welcome/splash screen
   - Navigate to registration

3. **User Type Selection**
   - Select "Student" from user type options
   - Verify "Teacher" option is NOT available (admin-only creation)
   - Continue to registration form

4. **Complete Registration**
   - Fill in required fields:
     - First Name: "Test"
     - Last Name: "Student"
     - Email: "test.student.flow@example.com"
     - Password: "testpassword123"
     - Confirm Password: "testpassword123"
     - Grade Level: "Grade 11"
     - Board: "CBSE"
   - Accept terms and conditions
   - Submit registration

5. **Verify Registration Success**
   - Should show success message or navigate to dashboard
   - Check that authentication is working

### Phase 2: Profile Completion and Verification
1. **Access Profile Screen**
   - Navigate to Profile from dashboard
   - Verify real data is displayed (not hardcoded "John Doe")
   - Check that student information shows:
     - Name: "Test Student"
     - Email: "test.student.flow@example.com"
     - Grade Level: "Grade 11"
     - Board: "CBSE"

2. **Edit Profile**
   - Click "Edit" button in profile
   - Verify form is populated with real data
   - Add additional information:
     - Phone: "+1234567890"
     - School Name: "Test High School"
     - Learning Goals: "Master mathematics and physics"
   - Save changes
   - Verify success message

3. **Verify Profile Updates**
   - Return to profile view
   - Confirm all new information is displayed
   - Check enrollment statistics section (should show 0 enrollments initially)

### Phase 3: Classroom Discovery and Teacher Names
1. **Browse Classrooms**
   - Navigate to "Find Classrooms" or classroom list
   - Verify classrooms are displayed
   - **KEY TEST**: Check that teacher names are shown correctly:
     - Should see names like "Dr. Sarah Johnson", "Prof. Michael Chen", "Dr. Emily Rodriguez"
     - Should NOT see "Unknown Teacher" or "Teacher Info Unavailable"

2. **Filter and Search**
   - Test filtering by:
     - Grade Level: Select "Grade 11"
     - Board: Select "CBSE"
     - Subject: Try different subjects
   - Verify results update correctly

3. **View Classroom Details**
   - Click on a classroom to view details
   - Verify teacher name is displayed correctly in detail view
   - Check pricing information is shown
   - Verify "Enroll" or "Join" button is available

### Phase 4: Enrollment Flow
1. **Select Classroom for Enrollment**
   - Choose a classroom (e.g., "Intermediate Mathematics - Grade 11")
   - Click "Enroll" or "Join Class" button

2. **Payment Process**
   - Should navigate to payment screen
   - Verify classroom details and pricing are shown
   - Select payment method (card payment simulation)
   - Fill in mock payment details or use payment bypass
   - Process payment

3. **Verify Enrollment Success**
   - Should show success message/dialog
   - Should indicate enrollment completion
   - Check for confirmation details

### Phase 5: My Classes Verification
1. **Navigate to My Classes**
   - Go to "My Classes" or "My Sessions" from dashboard
   - Verify enrolled classroom appears in the list
   - **KEY TEST**: Confirm teacher name is displayed correctly (not "Unknown Teacher")

2. **Check Enrollment Details**
   - Verify classroom information:
     - Name: Should match enrolled classroom
     - Subject and grade level
     - Teacher name: Should be real name
     - Enrollment date: Should be recent
     - Status: Should be "active"

3. **Verify Progress Display**
   - Check if progress indicators are shown
   - Verify next session information (if available)

### Phase 6: Profile Statistics Update
1. **Return to Profile**
   - Go back to student profile screen
   - **KEY TEST**: Verify enrollment statistics have updated:
     - Total courses: Should show 1
     - Active courses: Should show 1
     - Completed courses: Should show 0

### Phase 7: Data Persistence Testing
1. **App Restart Test**
   - Close the app completely
   - Restart the app
   - Verify automatic login (session persistence)
   - Check that all data is still present:
     - Profile information
     - Enrolled classrooms
     - Teacher names still correct

2. **Navigation Testing**
   - Test navigation between all student screens:
     - Dashboard → Profile → Edit Profile → Save → Back
     - Dashboard → My Classes → Classroom Details
     - Dashboard → Browse Classrooms → Classroom Details

### Phase 8: Debug Tools Verification
1. **Use Debug Tools**
   - Access debug tools from various screens:
     - Dashboard: Side menu → "Debug Authentication"
     - Profile: AppBar → Bug icon
     - My Classes: Floating debug button
   - Verify debug information shows correct:
     - User authentication status
     - Student ID
     - Database connection status
     - Enrollment data

## Expected Success Criteria

### ✅ Registration and Authentication
- Student can successfully register
- Authentication persists across app restarts
- Profile shows real student data (not hardcoded)

### ✅ Teacher Name Resolution
- All classroom screens show real teacher names
- No "Unknown Teacher" messages appear
- Teacher names are consistent across all screens

### ✅ Profile Management
- Profile displays real student information
- Profile editing works and saves changes
- Enrollment statistics update correctly

### ✅ Enrollment Flow
- Classroom discovery works with proper filtering
- Payment simulation completes successfully
- Enrollment records are created properly

### ✅ Data Persistence
- All student data persists across app sessions
- Enrolled classrooms remain visible
- Profile information is maintained

## Troubleshooting Common Issues

### Issue: "Teacher Info Unavailable" Still Showing
**Solution**: Check that:
- Teacher data was properly created using `quick_setup_with_teachers.sql`
- Teacher auth accounts exist with matching UUIDs
- Database relationships are properly established

### Issue: Authentication Not Persisting
**Solution**: 
- Verify Supabase client initialization
- Check splash screen routing logic
- Ensure session management is working

### Issue: Profile Shows Loading/Error
**Solution**:
- Use debug tools to check authentication state
- Verify student record exists in database
- Check StudentService.getCurrentStudentProfile() method

### Issue: No Enrolled Classes Showing
**Solution**:
- Verify enrollment records in database
- Check student_classroom_assignments table
- Use My Classes debug tools to inspect data

## Database Verification Queries

If testing reveals issues, use these SQL queries in Supabase to verify data:

```sql
-- Check student record
SELECT s.*, u.first_name, u.last_name, u.email 
FROM students s 
JOIN users u ON s.user_id = u.id 
WHERE u.email = 'test.student.flow@example.com';

-- Check teacher records and names
SELECT t.*, u.first_name, u.last_name 
FROM teachers t 
JOIN users u ON t.user_id = u.id 
WHERE t.status = 'active';

-- Check classroom-teacher relationships
SELECT c.name, c.subject, c.grade_level,
       CONCAT(u.first_name, ' ', u.last_name) as teacher_name
FROM classrooms c
JOIN teachers t ON c.teacher_id = t.id
JOIN users u ON t.user_id = u.id
WHERE c.is_active = true;

-- Check enrollment records
SELECT sca.*, c.name as classroom_name,
       CONCAT(tu.first_name, ' ', tu.last_name) as teacher_name,
       CONCAT(su.first_name, ' ', su.last_name) as student_name
FROM student_classroom_assignments sca
JOIN classrooms c ON sca.classroom_id = c.id
JOIN teachers t ON c.teacher_id = t.id
JOIN users tu ON t.user_id = tu.id
JOIN students s ON sca.student_id = s.id
JOIN users su ON s.user_id = su.id
WHERE sca.status = 'active';
```

## Success Confirmation

The student flow is complete and working correctly when:
1. ✅ Student can register and login successfully
2. ✅ Profile shows real data and can be edited
3. ✅ All classrooms show real teacher names (no "Unknown Teacher")
4. ✅ Enrollment process works end-to-end
5. ✅ My Classes shows enrolled classrooms with correct information
6. ✅ Profile statistics reflect actual enrollments
7. ✅ All data persists across app restarts
8. ✅ Debug tools provide accurate information

This completes the comprehensive student flow as specified in the requirements.