# Attendance Page Errors - Fix Guide

## Issues Found

### 1. **Column Name Error** ❌
**Error**: `column student_enrollments.enrollment_status does not exist`

**Root Cause**: The Flutter code was using `.eq('enrollment_status', 'active')` but the actual column name in the database is `status` (with type `enrollment_status`).

**Fix Applied**: Changed the query in `attendance_marking_screen.dart` from:
```dart
.eq('enrollment_status', 'active')
```
to:
```dart
.eq('status', 'active')
```

### 2. **Permission Denied Error** ❌
**Error**: `permission denied for table session_attendance`

**Root Cause**: The `session_attendance` table has Row Level Security (RLS) enabled but **no policies were defined**, so teachers couldn't read or write attendance records.

**Fix Created**: SQL file `fix_attendance_issues.sql` with comprehensive RLS policies.

---

## How to Apply the Fix

### Step 1: Run the SQL Fix on Supabase

1. **Open your Supabase Dashboard**
2. **Navigate to**: SQL Editor
3. **Copy and paste** the contents of: `supabase/fix_attendance_issues.sql`
4. **Click "Run"** to execute the SQL

This will:
- ✅ Add RLS policies for teachers to view/insert/update/delete attendance
- ✅ Add RLS policies for students to view their own attendance
- ✅ Grant proper permissions to authenticated users

### Step 2: Flutter Code Already Fixed ✅

The Flutter code has been automatically updated:
- File: `lib/features/teacher/screens/attendance_marking_screen.dart`
- Change: Line 66 - Changed `enrollment_status` → `status`

### Step 3: Test the Fix

1. **Hot Restart** your Flutter app (or restart the app completely)
2. **Navigate** to a classroom
3. **Open** a session
4. **Click** "Mark Attendance"
5. **Verify**:
   - ✅ Student list loads without errors
   - ✅ You can mark attendance (present/absent/late/excused)
   - ✅ You can save attendance successfully

---

## What the SQL Fix Does

### RLS Policies Created

#### For Teachers:
- **SELECT**: View attendance for sessions in their classrooms
- **INSERT**: Mark attendance for sessions in their classrooms
- **UPDATE**: Update attendance for sessions in their classrooms
- **DELETE**: Delete attendance records for their sessions

#### For Students:
- **SELECT**: View their own attendance records only

### Verification Queries

The SQL file includes queries at the end to verify:
- All policies were created successfully
- Permissions were granted correctly

---

## Database Schema Reference

### `student_enrollments` Table
```sql
student_enrollments (
  id uuid,
  student_id uuid,
  classroom_id varchar,
  payment_plan_id varchar,
  status enrollment_status,  -- ← This is the correct column name!
  -- (values: 'pending', 'active', 'completed', 'cancelled')
  ...
)
```

### `session_attendance` Table
```sql
session_attendance (
  id uuid,
  session_id uuid,
  student_id uuid,
  attendance_status varchar,  -- 'present', 'absent', 'late', 'excused'
  join_time timestamptz,
  leave_time timestamptz,
  total_duration interval,
  notes text,
  created_at timestamptz,
  updated_at timestamptz
)
```

---

## Troubleshooting

### If you still see errors:

1. **Clear App Cache**: Restart the Flutter app completely
2. **Check Supabase Logs**: Go to Supabase Dashboard → Logs → API
3. **Verify SQL Execution**: Run the verification queries at the end of `fix_attendance_issues.sql`
4. **Check User Role**: Ensure you're logged in as a teacher with classrooms

### Common Issues:

- **"Still getting permission denied"**: Make sure the SQL was executed successfully
- **"Student list is empty"**: Check that students are enrolled with `status = 'active'`
- **"Can't save attendance"**: Verify that INSERT/UPDATE policies were created

---

## Summary

✅ **Fixed Column Name**: Changed `enrollment_status` → `status`
✅ **Added RLS Policies**: Complete policies for `session_attendance` table
✅ **Granted Permissions**: Authenticated users can now access attendance

**Files Modified**:
1. `lib/features/teacher/screens/attendance_marking_screen.dart` - Fixed query
2. `supabase/fix_attendance_issues.sql` - New SQL fix file (needs to be run)

**Next Step**: Run the SQL file in Supabase Dashboard → SQL Editor
