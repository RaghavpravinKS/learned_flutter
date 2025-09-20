# Database Reset and Testing Instructions

## 🔄 Complete Database Reset Process

### Step 1: Reset the Database
1. Open your Supabase project dashboard
2. Go to the SQL Editor
3. Run the following scripts **in this exact order**:

#### A. First, run `complete_database_reset.sql`
```sql
-- This will clear ALL data and tables
-- Copy and paste the contents of complete_database_reset.sql
```

#### B. Then, run `complete_schema_with_functions.sql`
```sql
-- This will recreate all tables, functions, triggers, and policies
-- Copy and paste the contents of complete_schema_with_functions.sql
```

#### C. Finally, run `basic_test_data.sql`
```sql
-- This will add test classrooms and data for testing
-- Copy and paste the contents of basic_test_data.sql
```

### Step 2: Verify Database Setup
After running all scripts, check if everything is working:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check test data
SELECT 
    c.name as classroom_name,
    c.subject,
    c.grade_level,
    cp.price,
    pp.billing_cycle
FROM classrooms c
JOIN classroom_pricing cp ON c.id = cp.classroom_id
JOIN payment_plans pp ON cp.payment_plan_id = pp.id
LIMIT 10;
```

## 🧪 Testing the Student Flow

### Step 3: Test Student Registration
1. Open your Flutter app
2. Register a new student account:
   - Email: `test.student@example.com`
   - Password: `password123`
   - First Name: `John`
   - Last Name: `Doe`
   - User Type: `Student`

### Step 4: Test Classroom Discovery
1. Navigate to "Browse Classrooms"
2. You should see 5 test classrooms:
   - Advanced Mathematics - Grade 11
   - Physics Mastery - Grade 12
   - Chemistry Fundamentals - Grade 10
   - Biology Excellence - Grade 11
   - English Literature - Grade 12

### Step 5: Test Enrollment Flow
1. Click on any classroom (e.g., "Advanced Mathematics - Grade 11")
2. View classroom details and pricing
3. Click "Enroll Now"
4. Complete the payment process (simulated)
5. Verify enrollment success

### Step 6: Test My Classes
1. Navigate to "My Classes"
2. Should show the enrolled classroom
3. Check enrollment status and progress

### Step 7: Test Student Profile
1. Go to student profile
2. Verify personal information
3. Check enrollment statistics
4. Test profile editing

## 🔍 Verification Queries

Use these SQL queries to verify the student flow is working:

```sql
-- Check students created through app
SELECT 
    u.email,
    u.first_name,
    u.last_name,
    u.user_type,
    u.created_at
FROM users u
WHERE u.user_type = 'student'
ORDER BY u.created_at DESC;

-- Check student enrollments
SELECT 
    s.user_id,
    c.name as classroom_name,
    se.status,
    se.created_at
FROM student_enrollments se
JOIN students s ON se.student_id = s.id
JOIN classrooms c ON se.classroom_id = c.id
ORDER BY se.created_at DESC;

-- Check payment records
SELECT 
    p.amount,
    p.status,
    p.payment_method,
    c.name as classroom_name,
    p.created_at
FROM payments p
JOIN classrooms c ON p.classroom_id = c.id
ORDER BY p.created_at DESC;
```

## 🎯 Expected Results

After successful testing, you should have:
- ✅ Clean database with only current schema
- ✅ Student registration working
- ✅ Classroom browsing functional
- ✅ Payment and enrollment process complete
- ✅ Student profile and my classes working
- ✅ All data properly stored in database

## 📁 File Structure After Cleanup

```
supabase/
├── complete_database_reset.sql       # Database reset script
├── complete_schema_with_functions.sql # Complete schema with functions & triggers
├── basic_test_data.sql              # Test data for verification
└── migrations/
    └── current_schema.sql           # Table definitions only (reference)
```

This setup gives you a clean, fresh start for testing all the student flow features! 🚀
