# 🎓 LearnED Platform - Complete System Architecture & Design Documentation

*Consolidated Technical Specification - October 12, 2025*

---

## 📋 **Document Overview**

This document serves as the comprehensive technical specification for the LearnED e-learning platform, consolidating system architecture, design patterns, user flows, and database schema into a single authoritative reference.

---

## 🏗️ **Core System Architecture**

### 1. User Management & Authentication Flow 👥

#### **Public User Signup Process** (Students & Parents Only)
```
auth.users (Supabase Auth) → public.users → [students/parents]
```

**Flow:**
1. **Supabase Authentication**: User signs up via `auth.users` with email/password
2. **Trigger Activation**: `handle_new_user_signup` trigger fires automatically
3. **User Creation**: Creates record in `public.users` with user_type (student/parent only)
   - Extended users table now includes profile fields (address, date_of_birth, etc.)
4. **Role-Specific Tables**: Based on user_type, creates record in:
   - `students` table (with auto-generated student_id)
   - `parents` table (with auto-generated parent_id)

#### **JWT-Based Teacher Invitation System** 🛡️ *(Updated October 18, 2025)*
```
Admin Panel → Create Invitation → Magic Link Email → JWT Authentication → Profile Completion
```

**Enhanced Security Flow:**
1. **Admin Creates Invitation**: Admin creates secure teacher invitation:
   - Email, first_name, last_name, subject, grade_levels
   - Record created in `teacher_invitations` table with 7-day expiration
   - Status set to 'pending', invitation ID generated
   - Logged in audit system for compliance

2. **Magic Link Email**: System sends professional email with magic link:
   - JWT-secured authentication link
   - Professional LearnED branding
   - Clear instructions for setup completion
   - 1-hour expiration for security

3. **JWT Authentication**: Teacher clicks link and system validates:
   - Supabase processes JWT from URL hash automatically
   - Validates invitation exists and is not expired
   - Authenticates user and creates session
   - Redirects to profile completion interface

4. **Profile Completion**: Teacher completes onboarding via web interface:
   - Bio, phone, additional subjects
   - System creates records in `auth.users`, `public.users`, and `teachers`
   - Auto-generates teacher_id
   - Marks invitation as 'accepted'

5. **Mobile App Access**: Teacher can now login to Flutter app:
   - Uses same credentials from web onboarding
   - Full access to teacher dashboard and features
   - Seamless transition from web setup to mobile usage

**Security Enhancements:**
- **No Direct Password Creation**: Only JWT-validated magic links
- **Email Verification**: Built-in email confirmation
- **Invitation Expiration**: Automatic cleanup of expired invitations
- **Admin-Only Creation**: RLS policies prevent unauthorized invitations
- **Audit Trail**: Complete logging of all invitation activities

**Tables Involved:**
- `auth.users` (Supabase managed)
- `public.users` (our main user table with extended profile fields)
- `students`, `parents` (self-signup roles)
- `teachers` (admin-created, teacher-completed)

---

### 2. Admin Panel & Teacher Management Flow 🛡️

#### **Admin Teacher Creation Process**
```
Admin Panel → teachers → teacher_verification → teacher_documents
```

**Flow:**
1. **Admin Creates Teacher Account**: 
   - Admin enters basic teacher info (email, name, contact)
   - System generates temporary password
   - Creates records in `auth.users`, `public.users`, `teachers`
   - Sets initial status as 'pending_completion'

2. **Teacher Profile Setup**: Teacher receives credentials and logs in to:
   - Complete bio, qualifications, experience
   - Upload required documents (certificates, ID, background check)
   - Set availability schedule
   - Upload profile photo

3. **Admin Verification Process**:
   - Admin reviews submitted documents
   - Conducts background verification
   - Approves or rejects teacher application
   - Sets `is_verified` to true and status to 'active'

#### **Teacher Profile Enhancement** (Post-Approval)
```
teachers → teacher_availability → teacher_documents → classrooms
```

**Flow:**
1. **Verified Teacher Access**: Only verified teachers can create classrooms
2. **Availability Management**: Teachers set their teaching schedule
3. **Document Management**: Ongoing document updates and renewals
4. **Classroom Creation**: Teachers create and manage their classrooms

**Key Design Decisions:**

---

## **📊 Table Analysis & Architecture Evolution**

### **🎯 Finalized MVP Schema (23 Core Tables)**

#### **Tables Included:**
1. ✅ **Core Entities**: users, students, teachers, parents, classrooms
2. ✅ **Business Logic**: payment_plans, classroom_pricing, student_enrollments, payments
3. ✅ **Learning**: class_sessions, assignments, assignment_questions, learning_materials, student_assignment_attempts
4. ✅ **Tracking**: session_attendance, student_progress, system_notifications
5. ✅ **Administration**: admin_activities, teacher_documents, teacher_verification
6. ✅ **Relationships**: parent_student_relations
7. ✅ **System**: trigger_logs, audit_logs

#### **Tables Removed (Redundant/MVP Simplification):**
1. ❌ **student_classroom_assignments** → Merged functionality with student_enrollments
2. ❌ **student_subscriptions** → Using student_enrollments for subscription tracking
3. ❌ **enrollment_requests** → Direct enrollment process for MVP
4. ❌ **user_profiles** → **Key fields merged into users table**
5. ❌ **student_material_access** → Removed analytics tracking for MVP
6. ❌ **teacher_availability** → Manual scheduling for MVP

### **Key Enhancements Made:**
1. **Extended users table** with profile fields (address, date_of_birth, etc.)
2. **Simplified enrollment flow** - direct payment → enrollment
3. **Streamlined subscription management** through student_enrollments
4. **Comprehensive audit logging** for all critical system activities
5. **Subscription expiry management** with automatic billing cycle handling
6. **Focused on core learning functionality** while maintaining flexibility

### **Benefits of This Architecture:**
- **Simplified Development**: Fewer tables to manage and maintain
- **Clear Data Flow**: Direct relationships without redundant mappings
- **Scalable Foundation**: Easy to add removed features back when needed
- **Production Ready**: All essential functionality preserved
- **Performance Optimized**: Reduced join complexity for common queries

### **Subscription Management Features:**
- **Automatic Expiry Calculation**: Based on billing cycle (monthly/quarterly/yearly)
- **Subscription Tracking**: Start date, end date, and next billing date
- **Expired Enrollment Handling**: Automatic status updates for expired subscriptions
- **Renewal Management**: Easy renewal process with date extension
- **Auto-Renewal Support**: Configurable auto-renewal for seamless experience
- **Billing Cycle Flexibility**: Support for different payment intervals

### **Key Business Logic:**
1. **Payment → Subscription**: Every payment creates a time-bound subscription
2. **Automatic Expiry**: System can identify and handle expired enrollments
3. **Renewal Process**: Extends subscription from current end date or now (whichever is later)
4. **Status Management**: Clear distinction between active, cancelled, and expired enrollments
5. **Billing Alignment**: Next billing date aligns with subscription cycles

### **Comprehensive Audit Logging:**
- **User Activity Tracking**: All critical user actions logged with context
- **Data Change Auditing**: Before/after values for data modifications
- **Security Monitoring**: IP addresses, user agents, session tracking
- **Admin Oversight**: Complete audit trail for administrative actions
- **Compliance Ready**: Detailed logging for regulatory requirements
- **Troubleshooting Support**: Rich metadata for debugging and support
- **Severity Classification**: Debug, info, warning, error, critical levels
- **Searchable History**: Tagged and indexed for efficient querying

### **Audit Event Types:**
- **Authentication**: Login, logout, password changes
- **Enrollment**: Student enrollments, renewals, cancellations
- **Payment**: Transaction processing, refunds, billing updates
- **Content**: Assignment submissions, material access, grading
- **Administration**: User management, system configuration changes
- **Security**: Failed login attempts, permission violations

---

## **👥 Complete User Flows**

### **🎓 STUDENT FLOW**

#### **Registration & Onboarding**
1. **Account Creation**
   - Student visits registration page
   - Enters email, password, first name, last name
   - Selects user type: "Student"
   - Submits registration form

2. **System Processing**
   - `handle_new_user_signup()` trigger fires
   - Creates record in `users` table with `user_type = 'student'`
   - Automatically generates `student_id` (STU + date + UUID)
   - Creates record in `students` table
   - Links `user_id` to student record

3. **Email Verification**
   - Student receives verification email
   - Clicks verification link
   - Account activated (`email_verified = true`)

#### **Classroom Discovery & Enrollment**
4. **Browse Classrooms**
   - Student logs in to dashboard
   - Views available classrooms from `classrooms` table
   - Filters by subject, grade level, board
   - Sees pricing from `classroom_pricing` + `payment_plans`

5. **Classroom Details**
   - Student clicks on specific classroom
   - Views detailed information, teacher profile, schedule
   - Sees available payment plans (monthly/quarterly/yearly)

6. **Enrollment Process**
   - Student clicks "Enroll Now"
   - Selects payment plan
   - Redirected to payment screen
   - Enters payment information

7. **Payment & Enrollment**
   - Payment processed (simulated or real gateway)
   - `enroll_student_with_payment()` function called
   - Creates record in `payments` table
   - Creates record in `student_enrollments` table
   - Updates `current_students` count in `classrooms`
   - Student receives confirmation

#### **Learning Experience**
8. **Dashboard Access**
   - Student sees enrolled classrooms in "My Classes"
   - Views upcoming sessions from `class_sessions`
   - Accesses learning materials from `learning_materials`

9. **Attend Sessions**
   - Student joins live sessions via meeting URL
   - Attendance tracked in `session_attendance`
   - Can access recorded sessions

10. **Complete Assignments**
    - Views assignments from `assignments` table
    - Submits work tracked in `student_assignment_attempts`
    - Receives grades and feedback
    - Progress updated in `student_progress`

11. **Track Progress**
    - Views academic progress and grades
    - Sees completion statistics
    - Accesses performance analytics

### **👨‍🏫 TEACHER FLOW** *(Updated October 18, 2025)*

#### **JWT-Based Invitation & Onboarding**
1. **Admin Creates Invitation**
   - **Teachers CANNOT self-register** (security measure)
   - Admin uses `create_teacher_invitation()` function
   - Creates secure invitation in `teacher_invitations` table
   - Status: `status = 'pending'`, expires in 7 days

2. **Magic Link Email**
   - Teacher receives professional invitation email
   - Email contains JWT-secured magic link
   - Link expires in 1 hour for security
   - Branded with LearnED identity and clear instructions

3. **Web-Based Onboarding**
   - Teacher clicks magic link → JWT authentication
   - Completes profile on web interface (`/teacher/onboard`)
   - Provides phone, bio, additional subjects
   - System calls `complete_teacher_onboarding()` function
   - Creates records in `auth.users`, `public.users`, and `teachers`
   - Invitation marked as `status = 'accepted'`

4. **Mobile App Access**
   - Teacher can now login to Flutter mobile app
   - Uses same credentials from web onboarding
   - Full access to teacher dashboard and features

#### **Teaching Activities**
4. **Classroom Assignment**
   - Admin assigns teacher to specific classrooms via `assign_teacher_to_classroom()` function
   - Updates `teacher_id` foreign key in `classrooms` table
   - Teacher gains access to classroom management

5. **Content Creation**
   - Teacher uploads learning materials to `learning_materials`
   - Creates assignments in `assignments` table
   - Adds questions to `assignment_questions`
   - Schedules sessions in `class_sessions`

6. **Session Management**
   - Conducts live teaching sessions
   - Marks attendance in `session_attendance`
   - Records sessions for later access
   - Manages student participation

7. **Assessment & Grading**
   - Reviews student submissions in `student_assignment_attempts`
   - Provides grades and feedback
   - Updates `student_progress` records
   - Generates progress reports

### **👨‍👩‍👧‍👦 PARENT FLOW**

#### **Registration & Child Linking**
1. **Account Creation**
   - Parent registers with user type: "Parent"
   - Creates record in `users` and `parents` tables
   - Receives unique `parent_id`

2. **Child Connection**
   - Parent provides student information
   - Admin verifies parent-child relationship
   - Creates record in `parent_student_relations`
   - Parent gains monitoring access

#### **Monitoring & Management**
3. **Child Oversight**
   - Views child's enrolled classrooms
   - Monitors attendance from `session_attendance`
   - Reviews academic progress from `student_progress`
   - Sees assignment grades and feedback

4. **Payment Management**
   - Makes payments for child's enrollments
   - Views payment history from `payments` table
   - Manages subscription renewals
   - Handles billing issues

5. **Communication**
   - Receives notifications about child's activities
   - Communicates with teachers
   - Gets progress reports and updates

### **👑 ADMIN FLOW**

#### **System Management**
1. **User Management**
   - Creates teacher accounts via `create_teacher_by_admin()`
   - Manages user verification and approval
   - Handles user issues and support

2. **Teacher Verification**
   - Reviews teacher applications
   - Verifies uploaded documents in `teacher_documents`
   - Updates `teacher_verification` status
   - Approves or rejects teacher applications

3. **Content Oversight**
   - Manages classroom creation and configuration
   - Sets pricing in `classroom_pricing`
   - Oversees content quality and compliance
   - Handles reported issues

4. **Analytics & Reporting**
   - Views platform usage statistics
   - Monitors financial performance
   - Generates compliance reports
   - Tracks system health via `trigger_logs`

5. **System Administration**
   - All activities logged in `admin_activities`
   - Manages platform settings and configuration
   - Handles technical issues and maintenance
   - Ensures security and compliance

---

## **📁 File Storage Architecture**

### **Supabase Storage Buckets Configuration**

LearnED uses Supabase Storage for all file management with a multi-bucket architecture for security and organization.

#### **Bucket Structure:**

| Bucket Name | Purpose | Access Level | Max File Size |
|-------------|---------|--------------|---------------|
| `learning-materials` | Teacher content uploads | Private | 100MB |
| `assignment-attachments` | Student submission files | Private | 50MB |
| `profile-images` | User profile pictures | Private | 5MB |

#### **Folder Structure Within Buckets:**

```
learning-materials/
├── {teacher_id}/
│   ├── {classroom_id}/
│   │   ├── documents/
│   │   ├── videos/
│   │   ├── presentations/
│   │   └── recordings/

assignment-attachments/
├── {student_id}/
│   ├── {assignment_id}/
│   │   ├── attempt_1/
│   │   ├── attempt_2/
│   │   └── ...

profile-images/
├── teachers/
│   └── {teacher_id}/
├── students/
│   └── {student_id}/
└── parents/
    └── {parent_id}/
```

### **Storage Bucket Creation SQL**

```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('learning-materials', 'learning-materials', false, 104857600, 
   ARRAY['application/pdf', 'video/mp4', 'video/webm', 'image/jpeg', 'image/png', 
         'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
         'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
  
  ('assignment-attachments', 'assignment-attachments', false, 52428800,
   ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'text/plain',
         'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
         
  ('profile-images', 'profile-images', false, 5242880,
   ARRAY['image/jpeg', 'image/png', 'image/webp']);
```

### **Row Level Security (RLS) Policies**

#### **Learning Materials Bucket Policies:**

```sql
-- Teachers can upload learning materials to their own folders
CREATE POLICY "Teachers can upload learning materials" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'learning-materials' 
  AND (storage.foldername(name))[1] IN (
    SELECT t.id::text FROM public.teachers t 
    JOIN public.users u ON t.user_id = u.id 
    WHERE u.id = auth.uid()
  )
);

-- Teachers can read their own learning materials
CREATE POLICY "Teachers can read own materials" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'learning-materials'
  AND (storage.foldername(name))[1] IN (
    SELECT t.id::text FROM public.teachers t 
    JOIN public.users u ON t.user_id = u.id 
    WHERE u.id = auth.uid()
  )
);

-- Students can read materials from their enrolled classrooms
CREATE POLICY "Students can read classroom materials" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'learning-materials'
  AND (storage.foldername(name))[2] IN (
    SELECT se.classroom_id FROM public.student_enrollments se
    JOIN public.students s ON se.student_id = s.id
    JOIN public.users u ON s.user_id = u.id
    WHERE u.id = auth.uid() AND se.status = 'active'
  )
);

-- Teachers can update/delete their own materials
CREATE POLICY "Teachers can manage own materials" ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'learning-materials'
  AND (storage.foldername(name))[1] IN (
    SELECT t.id::text FROM public.teachers t 
    JOIN public.users u ON t.user_id = u.id 
    WHERE u.id = auth.uid()
  )
);

CREATE POLICY "Teachers can delete own materials" ON storage.objects
FOR DELETE TO authenticated
USING (
  bucket_id = 'learning-materials'
  AND (storage.foldername(name))[1] IN (
    SELECT t.id::text FROM public.teachers t 
    JOIN public.users u ON t.user_id = u.id 
    WHERE u.id = auth.uid()
  )
);
```

#### **Assignment Attachments Bucket Policies:**

```sql
-- Students can upload assignment attachments to their own folders
CREATE POLICY "Students can upload assignment attachments" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'assignment-attachments'
  AND (storage.foldername(name))[1] IN (
    SELECT s.id::text FROM public.students s
    JOIN public.users u ON s.user_id = u.id
    WHERE u.id = auth.uid()
  )
);

-- Students can read their own attachments
CREATE POLICY "Students can read own attachments" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'assignment-attachments'
  AND (storage.foldername(name))[1] IN (
    SELECT s.id::text FROM public.students s
    JOIN public.users u ON s.user_id = u.id
    WHERE u.id = auth.uid()
  )
);

-- Teachers can read attachments from their assignments
CREATE POLICY "Teachers can read assignment attachments" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'assignment-attachments'
  AND (storage.foldername(name))[2] IN (
    SELECT a.id::text FROM public.assignments a
    JOIN public.teachers t ON a.teacher_id = t.id
    JOIN public.users u ON t.user_id = u.id
    WHERE u.id = auth.uid()
  )
);

-- Students can update their own attachments (before grading)
CREATE POLICY "Students can update own attachments" ON storage.objects
FOR UPDATE TO authenticated
USING (
  bucket_id = 'assignment-attachments'
  AND (storage.foldername(name))[1] IN (
    SELECT s.id::text FROM public.students s
    JOIN public.users u ON s.user_id = u.id
    WHERE u.id = auth.uid()
  )
  AND NOT EXISTS (
    SELECT 1 FROM public.student_assignment_attempts saa
    JOIN public.assignments a ON saa.assignment_id = a.id
    WHERE a.id::text = (storage.foldername(name))[2]
    AND saa.status = 'graded'
  )
);
```

#### **Profile Images Bucket Policies:**

```sql
-- Users can upload their own profile images
CREATE POLICY "Users can upload own profile images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'profile-images'
  AND (
    (storage.foldername(name))[2] IN (
      SELECT t.id::text FROM public.teachers t 
      JOIN public.users u ON t.user_id = u.id 
      WHERE u.id = auth.uid()
    )
    OR (storage.foldername(name))[2] IN (
      SELECT s.id::text FROM public.students s
      JOIN public.users u ON s.user_id = u.id
      WHERE u.id = auth.uid()
    )
    OR (storage.foldername(name))[2] IN (
      SELECT p.id::text FROM public.parents p
      JOIN public.users u ON p.user_id = u.id
      WHERE u.id = auth.uid()
    )
  )
);

-- Users can read their own profile images
CREATE POLICY "Users can read own profile images" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'profile-images'
  AND (
    (storage.foldername(name))[2] IN (
      SELECT t.id::text FROM public.teachers t 
      JOIN public.users u ON t.user_id = u.id 
      WHERE u.id = auth.uid()
    )
    OR (storage.foldername(name))[2] IN (
      SELECT s.id::text FROM public.students s
      JOIN public.users u ON s.user_id = u.id
      WHERE u.id = auth.uid()
    )
    OR (storage.foldername(name))[2] IN (
      SELECT p.id::text FROM public.parents p
      JOIN public.users u ON p.user_id = u.id
      WHERE u.id = auth.uid()
    )
  )
);

-- Public read access for profile images (for display in UI)
CREATE POLICY "Public read access for profile images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'profile-images');
```

### **File Upload Workflow Integration**

#### **Teacher Learning Material Upload Process:**
1. **Frontend**: Teacher selects file and metadata
2. **Storage**: Upload to `learning-materials/{teacher_id}/{classroom_id}/`
3. **Database**: Call `upload_learning_material()` with generated file URL
4. **Result**: Material available to enrolled students

#### **Student Assignment Submission Process:**
1. **Frontend**: Student selects attachment files
2. **Storage**: Upload to `assignment-attachments/{student_id}/{assignment_id}/`
3. **Database**: Call `submit_assignment_attempt()` with file URLs array
4. **Result**: Attachments available to teacher for review

#### **Function Integration Points:**

##### **`upload_learning_material()` Function:**
- **Input**: `p_file_url` (from Supabase Storage upload)
- **Storage Path**: `learning-materials/{teacher_id}/{classroom_id}/{filename}`
- **Access**: Teacher uploads, enrolled students can view

##### **`submit_assignment_attempt()` Function:**
- **Input**: `p_attachment_urls[]` (array of file URLs)
- **Storage Path**: `assignment-attachments/{student_id}/{assignment_id}/{filename}`
- **Access**: Student uploads, teacher can view and download

### **File Type and Size Restrictions**

#### **Learning Materials:**
- **Max Size**: 100MB per file
- **Allowed Types**: PDF, MP4, WebM, JPEG, PNG, PowerPoint, Word documents
- **Use Cases**: Lecture videos, study materials, assignments, presentations

#### **Assignment Attachments:**
- **Max Size**: 50MB per file  
- **Allowed Types**: PDF, images, text files, Word documents
- **Use Cases**: Student homework, projects, essay submissions

#### **Profile Images:**
- **Max Size**: 5MB per file
- **Allowed Types**: JPEG, PNG, WebP
- **Use Cases**: User avatars, teacher profile photos

### **Storage Security Features**

#### **Access Control:**
- ✅ **Row Level Security**: All buckets protected by RLS policies
- ✅ **User Validation**: File access tied to user roles and enrollment status
- ✅ **Folder Isolation**: Users can only access their own folders
- ✅ **Assignment Context**: Teachers only see attachments from their assignments

#### **File Integrity:**
- ✅ **MIME Type Validation**: Server-side file type checking
- ✅ **Size Limits**: Automatic file size enforcement
- ✅ **Virus Scanning**: Supabase built-in security features
- ✅ **Audit Trail**: All file operations logged via existing audit system

---

**Key Design Decisions:**
- **Quality Control**: Admin approval ensures teacher quality
- **Security**: No public teacher signup prevents spam accounts
- **Compliance**: Document verification for legal requirements
- **Gradual Onboarding**: Step-by-step process reduces abandonment

---

### 3. Payment Plans & Pricing System 💰

#### **Payment Plan Architecture**
```
payment_plans ← classroom_pricing → classrooms
```

**Flow:**
1. **Global Payment Plans**: Admin creates reusable plans in `payment_plans`
   - `billing_cycle`: 'hourly', 'weekly', 'monthly', 'per_session'
   - Base pricing: `price_per_hour`, `price_per_month`, `price_per_session`
   - Features: JSON field for plan benefits

2. **Classroom-Specific Pricing**: Each classroom links to payment plans via `classroom_pricing`
   - **Customization**: Same plan, different prices per classroom
   - **Multiple Options**: One classroom can offer multiple payment plans

**Example:**
```sql
-- Payment Plan: "Standard Monthly"
payment_plans: {id: plan-1, name: "Standard Monthly", billing_cycle: "monthly", price_per_month: 100}

-- Classroom Pricing: Math class uses this plan but charges $120
classroom_pricing: {classroom_id: math-class-1, payment_plan_id: plan-1, price: 120}
```

---

### 4. Student Discovery & Enrollment Flow 🔍

#### **Classroom Discovery**
```
classrooms + classroom_pricing + teachers + payment_plans → Browse Results
```

**Student Flow:**
1. **Browse Classrooms**: Students see available classrooms with:
   - Teacher information from `teachers` + `users` tables
   - Pricing options from `classroom_pricing` + `payment_plans`
   - Classroom details (subject, grade, board)

2. **Filtering**: Students filter by grade, board, subject, price range

---

### 5. Complete Enrollment & Payment Flow 💳

#### **The Multi-Stage Enrollment Process**

```
enrollment_requests → payments → student_classroom_assignments → student_subscriptions
```

**Detailed Flow:**

##### **Stage 1: Intent to Enroll**
- **Table**: `enrollment_requests`
- **Status**: 'pending'
- **Purpose**: Track student interest before payment
- **Data**: student_id, classroom_id, timestamp

##### **Stage 2: Payment Processing**
- **Table**: `payments`
- **Integration**: External gateway (Razorpay, Stripe)
- **Data**: amount, currency, payment_method, transaction_id, status
- **Statuses**: 'pending' → 'completed' → 'failed'

##### **Stage 3: Official Enrollment**
- **Table**: `student_classroom_assignments`
- **Status**: 'active'
- **Purpose**: Official student-classroom relationship
- **Features**: Progress tracking, assignment history

##### **Stage 4: Subscription Management** (if applicable)
- **Table**: `student_subscriptions`
- **Purpose**: Handle recurring payments, plan renewals
- **Status**: 'active', 'expired', 'cancelled', 'suspended'

---

### 6. Class Session Management 📅 *(Future Implementation)*

#### **Session Lifecycle**
```
class_sessions → session_attendance → student_progress
```

**Flow:**
1. **Session Creation**: Teachers create `class_sessions` with scheduled times
2. **Student Attendance**: Track in `session_attendance` with join/leave times
3. **Progress Tracking**: Aggregate data in `student_progress` weekly

**Features:**
- Meeting URLs for virtual classes
- Recording storage
- Attendance scoring
- Participation metrics

---

### 7. Assignment & Assessment System 📝 *(MVP Priority)*

#### **Assignment Flow**
```
assignments → assignment_questions → student_assignment_attempts
```

**Flow:**
1. **Assignment Creation**: Teachers create assignments with questions
2. **Question Bank**: `assignment_questions` stores MCQ, essays, etc.
3. **Student Attempts**: Track attempts, scores, time taken
4. **Grading**: Auto-grading for MCQ, manual for essays

**MVP Functions Available:**
- `create_assignment()` - Teachers create assignments
- `get_teacher_assignments()` - List teacher's assignments
- `submit_assignment_attempt()` - Students submit work
- `grade_assignment()` - Teachers provide grades and feedback

---

### 8. Learning Materials & Resources 📚 *(MVP Priority)*

#### **Content Management**
```
learning_materials → student_material_access
```

**Flow:**
1. **Upload**: Teachers upload materials (videos, documents, presentations)
2. **Access Control**: Public/private materials per classroom
3. **Tracking**: Monitor student downloads and access patterns

**MVP Functions Available:**
- `upload_learning_material()` - Teachers upload content
- `get_classroom_materials()` - List classroom materials
- `track_material_access()` - Track student material usage

---

### 9. Communication & Notification System 📢 *(Future Implementation)*

#### **Notification Pipeline**
```
system_notifications + email_queue + audit_log
```

**Flow:**
1. **Event Triggers**: Enrollment, payment, class reminders
2. **Multi-Channel**: In-app notifications + email
3. **Audit Trail**: All actions logged for compliance

---

### 10. Family & Parent Integration 👨‍👩‍👧‍👦 *(Future Implementation)*

#### **Parent-Student Relationships**
```
parents → parent_student_relations → students
```

**Flow:**
1. **Parent Signup**: Parents create accounts separately
2. **Child Linking**: Connect to student accounts via invite/code
3. **Progress Monitoring**: Parents view child's progress, payments, attendance

---

## 📊 **Database Architecture & Table Analysis**

### 🔴 **Core Entity Tables**

#### 1. **users** (Essential)
**Purpose**: Central authentication and basic profile data for all user types
**Justification**: 
- Single source of truth for authentication
- Integrates with Supabase Auth
- Contains common fields shared by all user types
- Base table for all other user-specific tables

#### 2. **students** (Essential)
**Purpose**: Student-specific data and academic information
**Justification**:
- Stores student ID, grade level, school information
- Links to parent contact information
- Required for enrollment tracking and academic progress
- Core entity for the primary user base

#### 3. **teachers** (Essential)
**Purpose**: Teacher profiles, qualifications, and professional data
**Justification**:
- Stores teaching credentials and experience
- Manages verification status and ratings
- Required for classroom assignment and quality assurance
- Professional profile for parents/students to evaluate

#### 4. **parents** (Essential)
**Purpose**: Parent profiles for monitoring and payment management
**Justification**:
- Many students are minors requiring parent oversight
- Parents handle payments and monitor progress
- Legal guardian relationships need tracking
- Communication and authorization requirements

#### 5. **classrooms** (Essential)
**Purpose**: Course/class definitions and basic information
**Justification**:
- Core product offering - the classes students enroll in
- Contains subject, grade level, capacity management
- Links to pricing and teacher assignment
- Foundation for the entire learning platform

### 🟡 **Business Logic Tables**

#### 6. **payment_plans** (Essential)
**Purpose**: Flexible pricing models (monthly, quarterly, yearly)
**Justification**:
- Business requirement for different billing cycles
- Allows dynamic pricing strategies
- Supports promotional pricing and discounts
- Scalable monetization model

#### 7. **classroom_pricing** (Essential)
**Purpose**: Links classrooms to their payment plans and prices
**Justification**:
- Allows different pricing for different classrooms
- Supports multiple payment options per classroom
- Essential for the enrollment and payment flow
- Business flexibility for pricing strategies

#### 8. **student_enrollments** (Essential)
**Purpose**: Tracks which students are enrolled in which classrooms
**Justification**:
- Core business relationship - enrollment is the primary transaction
- Tracks enrollment status and progress
- Required for access control and billing
- Foundation for all learning activities

#### 9. **payments** (Essential)
**Purpose**: Financial transaction records
**Justification**:
- Legal and business requirement for payment tracking
- Supports refunds, disputes, and accounting
- Integration with payment gateways
- Required for subscription management

### 🟢 **Learning & Academic Tables**

#### 10. **class_sessions** (Essential)
**Purpose**: Individual class meetings and scheduling
**Justification**:
- Core learning delivery mechanism
- Scheduling and attendance tracking
- Recording and content delivery
- Student and teacher coordination

#### 11. **assignments** (Important - MVP)
**Purpose**: Academic work assigned to students
**Justification**:
- Essential for academic progress tracking
- Grading and assessment capabilities
- Student engagement and learning outcomes
- Teacher workflow management

#### 12. **assignment_questions** (Important - MVP)
**Purpose**: Individual questions within assignments/quizzes
**Justification**:
- Detailed assessment creation
- Supports various question types
- Granular scoring and analytics
- Enhanced learning experience

#### 13. **learning_materials** (Important - MVP)
**Purpose**: Educational content and resources
**Justification**:
- Content delivery for students
- Teacher resource sharing
- Study materials and references
- Enhanced learning experience

#### 14. **student_assignment_attempts** (Important - MVP)
**Purpose**: Track student work and grading
**Justification**:
- Academic record keeping
- Progress tracking and analytics
- Multiple attempt support
- Grading workflow for teachers

### 🔵 **Tracking & Analytics Tables**

#### 15. **session_attendance** (Important)
**Purpose**: Track student participation in live sessions
**Justification**:
- Academic requirement for attendance tracking
- Parent reporting and monitoring
- Teacher insights for engagement
- Billing accuracy for attended sessions

#### 16. **student_progress** (Important)
**Purpose**: Academic progress and performance tracking
**Justification**:
- Parent and student dashboards
- Teacher insights for instruction
- Academic analytics and reporting
- Progress-based recommendations

#### 17. **student_material_access** (Optional - Analytics)
**Purpose**: Track which materials students access
**Justification**:
- Learning analytics and insights
- Content effectiveness measurement
- Student engagement tracking
- **Could be simplified or removed for MVP**

#### 18. **system_notifications** (Important)
**Purpose**: Platform-wide messaging and alerts
**Justification**:
- User engagement and communication
- Important updates and announcements
- Assignment deadlines and reminders
- Payment and enrollment notifications

### 🟠 **Administrative Tables**

#### 19. **admin_activities** (Important)
**Purpose**: Audit trail for administrative actions
**Justification**:
- Security and compliance requirements
- Troubleshooting and support
- Administrative oversight
- Legal and audit requirements

#### 20. **teacher_documents** (Important)
**Purpose**: Store teacher verification documents
**Justification**:
- Quality assurance and safety
- Legal compliance for education providers
- Trust building with parents
- Professional verification process

#### 21. **teacher_verification** (Important)
**Purpose**: Track teacher approval workflow
**Justification**:
- Quality control process
- Admin workflow management
- Teacher onboarding pipeline
- Trust and safety requirements

#### 22. **teacher_availability** (Optional - Future)
**Purpose**: Teacher schedule and availability
**Justification**:
- Advanced scheduling features
- Automatic session scheduling
- **Could be simplified for MVP - manual scheduling**

### 🟣 **Relationship & Profile Tables**

#### 23. **parent_student_relations** (Important - Future)
**Purpose**: Link parents to their children
**Justification**:
- Legal guardian relationships
- Multi-child families support
- Access control and permissions
- Communication routing

### ⚪ **System Tables**

#### 24. **trigger_logs** (Essential)
**Purpose**: System debugging and monitoring
**Justification**:
- Development and troubleshooting
- System health monitoring
- Error tracking and resolution

#### 25. **audit_logs** (Essential)
**Purpose**: Comprehensive audit trail for all user actions
**Justification**:
- Security and compliance requirements
- Legal audit trail
- User action tracking
- System debugging and support

---

## 👥 **Complete User Flows**

### 🎓 **STUDENT FLOW** *(MVP Complete)*

#### **Registration & Onboarding**
1. **Account Creation**
   - Student visits registration page
   - Enters email, password, first name, last name
   - Selects user type: "Student"
   - Submits registration form

2. **System Processing**
   - `handle_new_user_signup()` trigger fires
   - Creates record in `users` table with `user_type = 'student'`
   - Automatically generates `student_id` (STU + date + UUID)
   - Creates record in `students` table
   - Links `user_id` to student record

3. **Email Verification**
   - Student receives verification email
   - Clicks verification link
   - Account activated (`email_verified = true`)

#### **Classroom Discovery & Enrollment**
4. **Browse Classrooms**
   - Student logs in to dashboard
   - Views available classrooms from `classrooms` table
   - Filters by subject, grade level, board
   - Sees pricing from `classroom_pricing` + `payment_plans`

5. **Classroom Details**
   - Student clicks on specific classroom
   - Views detailed information, teacher profile, schedule
   - Sees available payment plans (monthly/quarterly/yearly)

6. **Enrollment Process**
   - Student clicks "Enroll Now"
   - Selects payment plan
   - Redirected to payment screen
   - Enters payment information

7. **Payment & Enrollment**
   - Payment processed (simulated or real gateway)
   - `enroll_student_with_payment()` function called
   - Creates record in `payments` table
   - Creates record in `student_enrollments` table
   - Updates `current_students` count in `classrooms`
   - Student receives confirmation

#### **Learning Experience**
8. **Dashboard Access**
   - Student sees enrolled classrooms in "My Classes"
   - Views upcoming sessions from `class_sessions`
   - Accesses learning materials from `learning_materials`

9. **Complete Assignments** *(MVP Ready)*
   - Views assignments from `assignments` table
   - Submits work using `submit_assignment_attempt()`
   - Receives grades and feedback
   - Progress updated in `student_progress`

10. **Access Learning Materials** *(MVP Ready)*
    - Downloads/views materials using `get_classroom_materials()`
    - Access tracked via `track_material_access()`
    - Views progress and completion statistics

### 👨‍🏫 **TEACHER FLOW** *(MVP Priority)*

#### **Registration & Verification**
1. **Admin-Created Account**
   - **Teachers CANNOT self-register** (security measure)
   - Admin uses `create_teacher_by_admin()` function
   - Creates records in `users` and `teachers` tables
   - Initial status: `verification_status = 'pending'`

2. **Account Activation**
   - Teacher receives email with login credentials
   - Logs in and completes profile information
   - Status updated to active for MVP (verification skipped)

#### **Teaching Activities** *(MVP Functions)*
3. **Content Creation**
   - Teacher uploads learning materials using `upload_learning_material()`
   - Creates assignments using `create_assignment()`
   - Manages classroom content and resources

4. **Assignment Management**
   - Creates assignments with `create_assignment()`
   - Views all assignments with `get_teacher_assignments()`
   - Grades student work with `grade_assignment()`
   - Provides feedback and tracks progress

5. **Material Management**
   - Uploads documents, videos, presentations
   - Organizes materials by type and visibility
   - Tracks student access and engagement

### 👑 **ADMIN FLOW** *(Core Functions Complete)*

#### **System Management**
1. **User Management**
   - Creates teacher accounts via `create_teacher_by_admin()`
   - Assigns teachers to classrooms via `assign_teacher_to_classroom()`
   - Manages user issues and support

2. **Platform Oversight**
   - Views comprehensive audit logs via `get_user_audit_history()`
   - Monitors system activities through `admin_activities`
   - Handles enrollment and payment issues

3. **System Administration**
   - All activities logged in `admin_activities`
   - Manages platform settings and configuration
   - Handles technical issues and maintenance
   - Ensures security and compliance

---

## 📋 **Detailed Database Schema**

### **Complete Table Structures**

#### **Core Entity Tables**

##### 1. **users** (Essential)
```sql
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email character varying NOT NULL UNIQUE,
  password_hash character varying,
  user_type user_type NOT NULL,
  first_name character varying NOT NULL,
  last_name character varying NOT NULL,
  phone character varying,
  profile_image_url text,
  date_of_birth date,
  address text,
  city character varying,
  state character varying,
  country character varying,
  postal_code character varying,
  is_active boolean DEFAULT true,
  email_verified boolean DEFAULT false,
  email_confirmed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);
```

##### 2. **students** (Essential)
```sql
CREATE TABLE public.students (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  student_id character varying NOT NULL UNIQUE,
  grade_level integer,
  school_name character varying,
  parent_contact text,
  emergency_contact_name character varying,
  emergency_contact_phone character varying,
  board character varying,
  status character varying DEFAULT 'active',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT students_pkey PRIMARY KEY (id),
  CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);
```

##### 3. **teachers** (Essential)
```sql
CREATE TABLE public.teachers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  teacher_id character varying NOT NULL UNIQUE,
  qualifications text,
  experience_years integer,
  specializations text[],
  hourly_rate numeric,
  bio text,
  availability_timezone character varying,
  is_verified boolean DEFAULT false,
  rating numeric DEFAULT 0.00,
  total_reviews integer DEFAULT 0,
  hire_date date,
  status character varying DEFAULT 'active',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT teachers_pkey PRIMARY KEY (id),
  CONSTRAINT teachers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);
```

##### 3a. **teacher_invitations** (JWT Invitation System) *(Added October 18, 2025)*
```sql
CREATE TABLE IF NOT EXISTS public.teacher_invitations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL UNIQUE,
    first_name text NOT NULL,
    last_name text NOT NULL,
    subject text,
    grade_levels integer[],
    invited_by uuid REFERENCES public.users(id),
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
    expires_at timestamp with time zone DEFAULT (now() + interval '7 days'),
    accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_email ON public.teacher_invitations(email);
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_status ON public.teacher_invitations(status);
CREATE INDEX IF NOT EXISTS idx_teacher_invitations_expires ON public.teacher_invitations(expires_at);
```

**Purpose**: Manages secure teacher invitation system with JWT-based authentication.
- **id**: Unique invitation identifier
- **email**: Teacher's email for magic link delivery
- **first_name, last_name**: Pre-filled teacher information
- **subject**: Primary teaching subject (optional)
- **grade_levels**: Array of grades teacher will teach
- **invited_by**: Admin user who created the invitation
- **status**: Invitation state (pending/accepted/expired/cancelled)
- **expires_at**: Automatic 7-day expiration for security
- **accepted_at**: Timestamp when teacher completed onboarding

##### 4. **parents** (Essential)
```sql
CREATE TABLE public.parents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  parent_id text NOT NULL UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT parents_pkey PRIMARY KEY (id),
  CONSTRAINT parents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE
);
```

##### 5. **classrooms** (Essential)
```sql
CREATE TABLE public.classrooms (
  id character varying NOT NULL,
  name character varying NOT NULL,
  description text,
  subject character varying NOT NULL,
  grade_level integer NOT NULL,
  board character varying,
  max_students integer DEFAULT 30,
  current_students integer DEFAULT 0,
  is_active boolean DEFAULT true,
  teacher_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT classrooms_pkey PRIMARY KEY (id),
  CONSTRAINT classrooms_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id)
);
```

#### **Business Logic Tables**

##### 6. **payment_plans** (Essential)
```sql
CREATE TABLE public.payment_plans (
  id character varying NOT NULL,
  name character varying NOT NULL,
  description text,
  billing_cycle character varying NOT NULL,
  features text[],
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT payment_plans_pkey PRIMARY KEY (id)
);
```

##### 7. **classroom_pricing** (Essential)
```sql
CREATE TABLE public.classroom_pricing (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id character varying NOT NULL,
  payment_plan_id character varying NOT NULL,
  price numeric NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT classroom_pricing_pkey PRIMARY KEY (id),
  CONSTRAINT classroom_pricing_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT classroom_pricing_payment_plan_id_fkey FOREIGN KEY (payment_plan_id) REFERENCES public.payment_plans(id)
);
```

##### 8. **student_enrollments** (Essential)
```sql
CREATE TABLE public.student_enrollments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  classroom_id character varying NOT NULL,
  payment_plan_id character varying NOT NULL,
  status enrollment_status DEFAULT 'pending',
  enrollment_date timestamp with time zone DEFAULT now(),
  start_date timestamp with time zone DEFAULT now(),
  end_date timestamp with time zone,
  next_billing_date timestamp with time zone,
  auto_renew boolean DEFAULT true,
  progress numeric DEFAULT 0.0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_enrollments_pkey PRIMARY KEY (id),
  CONSTRAINT student_enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_enrollments_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT student_enrollments_payment_plan_id_fkey FOREIGN KEY (payment_plan_id) REFERENCES public.payment_plans(id),
  CONSTRAINT unique_student_classroom UNIQUE (student_id, classroom_id)
);
```

##### 9. **payments** (Essential)
```sql
CREATE TABLE public.payments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  classroom_id character varying NOT NULL,
  payment_plan_id character varying NOT NULL,
  amount numeric NOT NULL,
  currency character varying DEFAULT 'USD',
  payment_method character varying,
  transaction_id character varying,
  status payment_status DEFAULT 'pending',
  payment_gateway character varying,
  gateway_response jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT payments_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT payments_payment_plan_id_fkey FOREIGN KEY (payment_plan_id) REFERENCES public.payment_plans(id)
);
```

#### **Learning & Academic Tables**

##### 10. **class_sessions** (Essential)
```sql
CREATE TABLE public.class_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id character varying NOT NULL,
  title character varying NOT NULL,
  description text,
  session_date date,
  start_time time,
  end_time time,
  session_type character varying DEFAULT 'live',
  meeting_url text,
  recording_url text,
  is_recorded boolean DEFAULT false,
  status session_status DEFAULT 'scheduled',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT class_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT class_sessions_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id)
);
```

##### 11. **assignments** (Important - MVP)
```sql
CREATE TABLE public.assignments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id character varying NOT NULL,
  teacher_id uuid NOT NULL,
  title character varying NOT NULL,
  description text,
  assignment_type character varying NOT NULL CHECK (assignment_type IN ('quiz', 'test', 'assignment', 'project')),
  total_points integer NOT NULL,
  time_limit_minutes integer,
  due_date timestamp with time zone,
  instructions text,
  status character varying DEFAULT 'active',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT assignments_pkey PRIMARY KEY (id),
  CONSTRAINT assignments_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT assignments_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id)
);
```

##### 12. **assignment_questions** (Important - MVP)
```sql
CREATE TABLE public.assignment_questions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  assignment_id uuid NOT NULL,
  question_text text NOT NULL,
  question_type character varying NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'short_answer', 'essay')),
  options jsonb,
  correct_answer text,
  points integer NOT NULL,
  order_index integer NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT assignment_questions_pkey PRIMARY KEY (id),
  CONSTRAINT assignment_questions_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id) ON DELETE CASCADE
);
```

##### 13. **learning_materials** (Important - MVP)
```sql
CREATE TABLE public.learning_materials (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  classroom_id character varying NOT NULL,
  title character varying NOT NULL,
  description text,
  material_type character varying NOT NULL CHECK (material_type IN ('note', 'video', 'document', 'presentation', 'assignment', 'recording')),
  file_url text,
  file_size bigint,
  file_type character varying,
  is_public boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT learning_materials_pkey PRIMARY KEY (id),
  CONSTRAINT learning_materials_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id),
  CONSTRAINT learning_materials_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id)
);
```

##### 14. **student_assignment_attempts** (Important - MVP)
```sql
CREATE TABLE public.student_assignment_attempts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  assignment_id uuid NOT NULL,
  student_id uuid NOT NULL,
  submission_text text,
  attachment_urls text[],
  score numeric,
  feedback text,
  status character varying DEFAULT 'draft',
  submitted_at timestamp with time zone,
  graded_at timestamp with time zone,
  graded_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_assignment_attempts_pkey PRIMARY KEY (id),
  CONSTRAINT student_assignment_attempts_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id),
  CONSTRAINT student_assignment_attempts_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_assignment_attempts_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES public.teachers(id)
);
```

#### **Tracking & Analytics Tables**

##### 15. **session_attendance** (Important)
```sql
CREATE TABLE public.session_attendance (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  student_id uuid NOT NULL,
  attendance_status character varying DEFAULT 'absent' CHECK (attendance_status IN ('present', 'absent', 'late', 'excused')),
  join_time timestamp with time zone,
  leave_time timestamp with time zone,
  total_duration interval,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT session_attendance_pkey PRIMARY KEY (id),
  CONSTRAINT session_attendance_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id),
  CONSTRAINT session_attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT unique_session_student UNIQUE (session_id, student_id)
);
```

##### 16. **student_progress** (Important)
```sql
CREATE TABLE public.student_progress (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  classroom_id character varying NOT NULL,
  assignment_id uuid,
  progress_type character varying NOT NULL CHECK (progress_type IN ('assignment', 'quiz', 'test', 'overall')),
  score numeric,
  max_score numeric,
  percentage numeric,
  grade character varying,
  feedback text,
  completed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_progress_pkey PRIMARY KEY (id),
  CONSTRAINT student_progress_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_progress_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT student_progress_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id)
);
```

##### 17. **student_material_access** (Optional - Analytics)
```sql
CREATE TABLE public.student_material_access (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  material_id uuid NOT NULL,
  access_time timestamp with time zone DEFAULT now(),
  access_duration integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_material_access_pkey PRIMARY KEY (id),
  CONSTRAINT student_material_access_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_material_access_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.learning_materials(id)
);
```

##### 18. **system_notifications** (Important)
```sql
CREATE TABLE public.system_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  notification_type character varying NOT NULL CHECK (notification_type IN ('system', 'payment', 'class', 'assignment', 'grade')),
  title character varying NOT NULL,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  priority character varying DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  action_url text,
  expires_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  read_at timestamp with time zone,
  CONSTRAINT system_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT system_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
```

#### **Administrative Tables**

##### 19. **admin_activities** (Important)
```sql
CREATE TABLE public.admin_activities (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  admin_id uuid NOT NULL,
  activity_type character varying NOT NULL,
  target_user_id uuid,
  target_table character varying,
  target_record_id uuid,
  description text,
  metadata jsonb,
  ip_address inet,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT admin_activities_pkey PRIMARY KEY (id),
  CONSTRAINT admin_activities_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id),
  CONSTRAINT admin_activities_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public.users(id)
);
```

##### 20. **teacher_documents** (Important)
```sql
CREATE TABLE public.teacher_documents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  document_type character varying NOT NULL,
  document_url text NOT NULL,
  file_name character varying,
  file_size integer,
  uploaded_by uuid NOT NULL,
  verification_status character varying DEFAULT 'pending',
  verified_by uuid,
  verified_at timestamp with time zone,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT teacher_documents_pkey PRIMARY KEY (id),
  CONSTRAINT teacher_documents_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id),
  CONSTRAINT teacher_documents_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id),
  CONSTRAINT teacher_documents_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(id)
);
```

##### 21. **teacher_verification** (Important)
```sql
CREATE TABLE public.teacher_verification (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  verification_status teacher_status DEFAULT 'pending',
  submitted_at timestamp with time zone DEFAULT now(),
  reviewed_by uuid,
  reviewed_at timestamp with time zone,
  approval_notes text,
  rejection_reason text,
  background_check_status character varying DEFAULT 'pending',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT teacher_verification_pkey PRIMARY KEY (id),
  CONSTRAINT teacher_verification_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id),
  CONSTRAINT teacher_verification_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(id)
);
```

#### **Relationship Tables**

##### 22. **parent_student_relations** (Important - Future)
```sql
CREATE TABLE public.parent_student_relations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  parent_id uuid NOT NULL,
  student_id uuid NOT NULL,
  relationship character varying NOT NULL,
  is_primary_contact boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT parent_student_relations_pkey PRIMARY KEY (id),
  CONSTRAINT parent_student_relations_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parents(id),
  CONSTRAINT parent_student_relations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id)
);
```

#### **System Tables**

##### 23. **trigger_logs** (Essential)
```sql
CREATE TABLE public.trigger_logs (
  id integer NOT NULL DEFAULT nextval('trigger_logs_id_seq'),
  event_time timestamp with time zone DEFAULT now(),
  message text,
  error_message text,
  metadata jsonb,
  CONSTRAINT trigger_logs_pkey PRIMARY KEY (id)
);
```

##### 24. **audit_logs** (Essential)
```sql
CREATE TABLE public.audit_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  user_type user_type,
  action_type character varying NOT NULL,
  table_name character varying,
  record_id uuid,
  old_values jsonb,
  new_values jsonb,
  description text,
  ip_address inet,
  user_agent text,
  session_id text,
  request_id text,
  severity character varying DEFAULT 'info' CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical')),
  tags text[],
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT audit_logs_pkey PRIMARY KEY (id),
  CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
```

### **Database Enums & Types**

```sql
-- Custom types/enums
CREATE TYPE user_type AS ENUM ('student', 'teacher', 'parent', 'admin');
CREATE TYPE teacher_status AS ENUM ('pending', 'approved', 'rejected', 'suspended');
CREATE TYPE enrollment_status AS ENUM ('pending', 'active', 'completed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE session_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');

-- Sequence for trigger logs
CREATE SEQUENCE trigger_logs_id_seq;
```

---

## 🔧 **Complete Database Functions & API Specification**

### **Complete Database Function Specifications**

#### **1. User Management Functions**

##### **handle_new_user_signup()** - Trigger Function
```sql
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER AS $$
```
**Purpose**: Automatically creates user records when someone signs up via Supabase Auth
**Trigger**: AFTER INSERT ON auth.users
**Parameters**: Uses NEW record from trigger
**Returns**: NEW record or raises exception
**Functionality**:
- Blocks teacher registration (admin-only creation)
- Creates record in `public.users` table
- Creates student record if user_type is 'student'
- Generates unique student_id (STU + date + UUID substring)
- Logs all activities to `trigger_logs`
**Security**: Prevents unauthorized teacher accounts

##### **JWT Teacher Invitation System Functions** *(Added October 18, 2025)*

##### **create_teacher_invitation()** - Admin Function
```sql
CREATE OR REPLACE FUNCTION create_teacher_invitation(
    p_email TEXT,
    p_first_name TEXT,
    p_last_name TEXT,
    p_subject TEXT DEFAULT NULL,  
    p_grade_levels INTEGER[] DEFAULT NULL,
    p_admin_id UUID
) RETURNS JSONB
```
**Purpose**: Creates secure teacher invitation with 7-day expiration
**Parameters**:
- `p_email`: Teacher's email for magic link delivery
- `p_first_name`: Teacher's first name  
- `p_last_name`: Teacher's last name
- `p_subject`: Primary teaching subject (optional)
- `p_grade_levels`: Array of grades to teach (optional)
- `p_admin_id`: Admin user creating invitation
**Returns**: JSON with invitation_id, email, expires_at timestamp
**Security**: Validates admin permissions, checks for duplicate invitations
**Logging**: Complete audit trail with expiration tracking

##### **complete_teacher_onboarding()** - JWT-Validated Function  
```sql
CREATE OR REPLACE FUNCTION complete_teacher_onboarding(
    p_phone TEXT DEFAULT NULL,
    p_bio TEXT DEFAULT NULL,
    p_additional_subjects TEXT[] DEFAULT NULL
) RETURNS JSONB
```
**Purpose**: JWT-authenticated teacher profile completion
**Authentication**: Uses `auth.uid()` to get current user from JWT token
**Parameters**:
- `p_phone`: Teacher's phone number (optional)
- `p_bio`: Teacher biography (optional)  
- `p_additional_subjects`: Extra subjects beyond invitation (optional)
**Returns**: JSON with teacher_id, user_id, email, success confirmation
**Process**: Validates invitation, creates user/teacher records, marks invitation accepted
**Security**: JWT-only access, automatic email verification

##### **get_teacher_invitations()** - Admin Query Function
```sql  
CREATE OR REPLACE FUNCTION get_teacher_invitations(p_admin_id UUID)
RETURNS TABLE (id, email, first_name, last_name, subject, status, created_at, expires_at, accepted_at)
```
**Purpose**: Admin dashboard for invitation management
**Returns**: All teacher invitations with status tracking
**Security**: Admin-only access with permission validation

##### **cancel_teacher_invitation()** - Admin Function
```sql
CREATE OR REPLACE FUNCTION cancel_teacher_invitation(p_invitation_id UUID, p_admin_id UUID) RETURNS JSONB
```
**Purpose**: Admin cancellation of pending invitations
**Security**: Admin-only with audit logging
**Returns**: Success/error status with message

##### **cleanup_expired_invitations()** - Maintenance Function
```sql
CREATE OR REPLACE FUNCTION cleanup_expired_invitations() RETURNS INTEGER
```
**Purpose**: Automated cleanup job for expired invitations  
**Returns**: Count of invitations marked as expired
**Scheduling**: Run daily via cron job or Supabase scheduler

##### **create_teacher_by_admin()** - ⚠️ DEPRECATED
**Status**: Now returns deprecation error message
**Replacement**: Use `create_teacher_invitation()` for secure JWT-based onboarding

#### **2. Enrollment & Payment Functions**

##### **enroll_student_with_payment()** - Core Business Function
```sql
CREATE OR REPLACE FUNCTION enroll_student_with_payment(
    p_student_id UUID,
    p_classroom_id UUID,
    p_payment_plan_id VARCHAR,
    p_amount_paid NUMERIC
) RETURNS JSONB
```
**Purpose**: Complete student enrollment with payment processing
**Parameters**:
- `p_student_id`: Student enrolling
- `p_classroom_id`: Target classroom
- `p_payment_plan_id`: Selected payment plan
- `p_amount_paid`: Payment amount
**Returns**: JSON with success status, enrollment details, and subscription dates
**Functionality**:
- Validates student, classroom, and payment plan
- Prevents duplicate enrollments
- Calculates subscription dates based on billing cycle
- Creates payment record with 'simulation' status
- Creates enrollment with start/end dates
- Updates classroom student count
- Logs comprehensive audit trail
**Business Logic**: Handles monthly, quarterly, yearly billing cycles

##### **get_student_classrooms()** - Query Function
```sql
CREATE OR REPLACE FUNCTION get_student_classrooms(p_student_id uuid)
RETURNS TABLE(...)
```
**Purpose**: Retrieve all classrooms for a specific student
**Parameters**: `p_student_id` - Student ID to query
**Returns**: Table with classroom details, teacher names, enrollment status, pricing
**Columns Returned**:
- classroom_id, classroom_name, subject, grade_level
- teacher_name, enrollment_status, enrollment_date
- start_date, end_date, next_billing_date, auto_renew
- progress, price, billing_cycle, is_expired
**Joins**: Combines enrollments, classrooms, teachers, users, pricing, payment plans

##### **renew_student_enrollment()** - Subscription Function
```sql
CREATE OR REPLACE FUNCTION renew_student_enrollment(
    p_enrollment_id UUID
) RETURNS JSONB
```
**Purpose**: Renew expired or expiring student enrollments
**Parameters**: `p_enrollment_id` - Enrollment to renew
**Returns**: JSON with success status and new subscription dates
**Business Logic**:
- Calculates new dates from current end_date or now (whichever is later)
- Updates status to 'active'
- Extends subscription based on original billing cycle
- Handles monthly, quarterly, yearly renewals

##### **update_expired_enrollments()** - Maintenance Function
```sql
CREATE OR REPLACE FUNCTION update_expired_enrollments()
RETURNS JSONB
```
**Purpose**: Batch update expired enrollments to 'cancelled' status
**Parameters**: None
**Returns**: JSON with success status and count of updated records
**Automation**: Can be called via scheduled job or cron
**Logging**: Records operation in trigger_logs

#### **3. Assignment & Assessment Functions** *(NEW MVP)*

##### **create_assignment()** - Teacher Function
```sql
CREATE OR REPLACE FUNCTION create_assignment(
    p_teacher_id UUID,
    p_classroom_id UUID,
    p_title VARCHAR,
    p_description TEXT,
    p_due_date TIMESTAMPTZ,
    p_total_points INTEGER DEFAULT 100,
    p_instructions TEXT DEFAULT NULL,
    p_assignment_type VARCHAR DEFAULT 'homework',
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
```
**Purpose**: Teachers create assignments for their classrooms
**Parameters**:
- `p_teacher_id`: Creating teacher
- `p_classroom_id`: Target classroom
- `p_title`: Assignment title
- `p_description`: Assignment description
- `p_due_date`: Due date timestamp
- `p_total_points`: Maximum points (default 100)
- `p_instructions`: Detailed instructions
- `p_assignment_type`: Type of assignment
- `p_metadata`: Additional metadata
**Returns**: JSON with assignment_id, title, due_date, success message
**Validation**: 
- Verifies teacher exists and is active
- Confirms classroom belongs to teacher
- Creates audit log entry
**Logging**: Function entry/exit, validation steps, audit events

##### **get_teacher_assignments()** - Query Function
```sql
CREATE OR REPLACE FUNCTION get_teacher_assignments(
    p_teacher_id UUID,
    p_classroom_id UUID DEFAULT NULL
) RETURNS TABLE(...)
```
**Purpose**: Retrieve assignments created by a teacher
**Parameters**:
- `p_teacher_id`: Teacher to query
- `p_classroom_id`: Optional classroom filter
**Returns**: Table with assignment details and submission statistics
**Columns Returned**:
- assignment_id, classroom_id, classroom_name
- title, description, due_date, total_points
- assignment_type, status, created_at
- total_submissions, graded_submissions (counts)
**Aggregation**: Counts submission statistics per assignment

##### **submit_assignment_attempt()** - Student Function
```sql
CREATE OR REPLACE FUNCTION submit_assignment_attempt(
    p_student_id UUID,
    p_assignment_id UUID,
    p_submission_text TEXT DEFAULT NULL,
    p_attachment_urls TEXT[] DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
```
**Purpose**: Students submit work for assignments
**Parameters**:
- `p_student_id`: Submitting student
- `p_assignment_id`: Target assignment
- `p_submission_text`: Text submission
- `p_attachment_urls`: File attachments
- `p_metadata`: Additional data
**Returns**: JSON with attempt_id, status, submission timestamp
**Functionality**:
- Validates student enrollment in classroom
- Handles late submissions (warns but allows)
- Updates existing attempts or creates new ones
- Tracks submission timestamp
**Business Logic**: Prevents submissions from non-enrolled students

##### **grade_assignment()** - Teacher Function
```sql
CREATE OR REPLACE FUNCTION grade_assignment(
    p_teacher_id UUID,
    p_attempt_id UUID,
    p_score NUMERIC,
    p_feedback TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
```
**Purpose**: Teachers grade student assignment submissions
**Parameters**:
- `p_teacher_id`: Grading teacher
- `p_attempt_id`: Student submission to grade
- `p_score`: Numeric score
- `p_feedback`: Written feedback
- `p_metadata`: Additional grading data
**Returns**: JSON with score, percentage, graded timestamp
**Validation**:
- Verifies teacher owns the assignment
- Validates score within range (0 to total_points)
- Confirms attempt exists and belongs to student
**Calculation**: Automatically calculates percentage score

#### **4. Learning Materials Functions** *(NEW MVP)*

##### **upload_learning_material()** - Teacher Function
```sql
CREATE OR REPLACE FUNCTION upload_learning_material(
    p_teacher_id UUID,
    p_classroom_id UUID,
    p_title VARCHAR,
    p_description TEXT DEFAULT NULL,
    p_file_url TEXT,
    p_file_type VARCHAR,
    p_file_size BIGINT DEFAULT NULL,
    p_material_type VARCHAR DEFAULT 'document',
    p_is_public BOOLEAN DEFAULT false,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
```
**Purpose**: Teachers upload learning materials to classrooms
**Parameters**:
- `p_teacher_id`: Uploading teacher
- `p_classroom_id`: Target classroom
- `p_title`: Material title
- `p_description`: Material description
- `p_file_url`: Storage URL
- `p_file_type`: MIME type
- `p_file_size`: File size in bytes
- `p_material_type`: Type of material
- `p_is_public`: Public access flag
- `p_metadata`: Additional metadata
**Returns**: JSON with material_id, title, file_url, success message
**Access Control**: Public materials visible to all, private to enrolled students
**File Types**: Supports documents, videos, presentations, recordings

##### **get_classroom_materials()** - Query Function
```sql
CREATE OR REPLACE FUNCTION get_classroom_materials(
    p_classroom_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_user_type VARCHAR DEFAULT NULL
) RETURNS TABLE(...)
```
**Purpose**: Retrieve learning materials for a classroom
**Parameters**:
- `p_classroom_id`: Target classroom
- `p_user_id`: Requesting user
- `p_user_type`: User type for access control
**Returns**: Table with material details and access statistics
**Columns Returned**:
- material_id, title, description, file_url
- file_type, file_size, material_type
- teacher_name, created_at, access_count
**Access Control**: 
- Public materials: All users
- Private materials: Teachers and enrolled students only
**Statistics**: Shows access count per material

##### **track_material_access()** - Analytics Function
```sql
CREATE OR REPLACE FUNCTION track_material_access(
    p_student_id UUID,
    p_material_id UUID,
    p_access_duration INTEGER DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS JSONB
```
**Purpose**: Track student access to learning materials
**Parameters**:
- `p_student_id`: Accessing student
- `p_material_id`: Accessed material
- `p_access_duration`: Time spent (optional)
- `p_metadata`: Additional tracking data
**Returns**: JSON with access_id, access_time, success message
**Validation**: Ensures student is enrolled in material's classroom
**Analytics**: Provides data for engagement analysis

#### **5. Administrative Functions**

##### **assign_teacher_to_classroom()** - Admin Function
```sql
CREATE OR REPLACE FUNCTION assign_teacher_to_classroom(
    p_admin_id UUID,
    p_classroom_id UUID,
    p_teacher_id UUID
) RETURNS JSONB
```
**Purpose**: Admin assigns teachers to classrooms
**Parameters**:
- `p_admin_id`: Admin performing assignment
- `p_classroom_id`: Target classroom
- `p_teacher_id`: Teacher to assign (NULL to remove)
**Returns**: JSON with assignment details and teacher name
**Functionality**:
- Validates admin permissions
- Confirms classroom and teacher exist
- Updates classroom teacher assignment
- Logs administrative activity
- Supports teacher removal (p_teacher_id = NULL)

##### **log_audit_event()** - System Function
```sql
CREATE OR REPLACE FUNCTION log_audit_event(
    p_user_id UUID DEFAULT NULL,
    p_action_type VARCHAR,
    p_table_name VARCHAR DEFAULT NULL,
    p_record_id UUID DEFAULT NULL,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_session_id TEXT DEFAULT NULL,
    p_request_id TEXT DEFAULT NULL,
    p_severity VARCHAR DEFAULT 'info',
    p_tags TEXT[] DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS UUID
```
**Purpose**: Comprehensive audit logging for all system activities
**Parameters**: Extensive parameter set for complete audit trail
**Returns**: UUID of created audit log record
**Features**:
- User action tracking with context
- Before/after value logging
- Security metadata (IP, user agent)
- Severity classification
- Tagging system for categorization
**Reliability**: Fails gracefully, logs to trigger_logs if audit fails

##### **get_user_audit_history()** - Query Function
```sql
CREATE OR REPLACE FUNCTION get_user_audit_history(
    p_user_id UUID,
    p_action_filter VARCHAR DEFAULT NULL,
    p_severity_filter VARCHAR DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE(...)
```
**Purpose**: Retrieve audit history for a specific user
**Parameters**:
- `p_user_id`: User to query
- `p_action_filter`: Optional action type filter
- `p_severity_filter`: Optional severity filter
- `p_limit`: Result limit
- `p_offset`: Pagination offset
**Returns**: Table with audit log records
**Columns**: id, action_type, table_name, description, severity, ip_address, created_at, metadata
**Use Cases**: User activity review, security investigation, compliance reporting

##### **get_enrollment_logs()** - Debug Function
```sql
CREATE OR REPLACE FUNCTION get_enrollment_logs(
    p_limit INTEGER DEFAULT 100
) RETURNS TABLE(...)
```
**Purpose**: Retrieve enrollment-related log entries for debugging
**Parameters**: `p_limit` - Maximum records to return
**Returns**: Table with trigger log entries related to enrollment
**Columns**: id, event_time, message, error_message, metadata
**Usage**: Troubleshooting enrollment issues, system debugging

### **Function Categories & Usage**

#### **Trigger Functions** (Automatic)
- `handle_new_user_signup()` - Fires on auth.users INSERT

#### **Core Business Functions** (High Volume)
- `enroll_student_with_payment()` - Student enrollments
- `submit_assignment_attempt()` - Student submissions
- `track_material_access()` - Learning analytics

#### **Teacher Functions** (Moderate Volume)
- `create_assignment()` - Assignment creation
- `upload_learning_material()` - Content upload
- `grade_assignment()` - Student grading

#### **Admin Functions** (Low Volume)
- `create_teacher_by_admin()` - Teacher onboarding
- `assign_teacher_to_classroom()` - Teacher management

#### **Query Functions** (Read-Only)
- `get_student_classrooms()` - Student dashboard
- `get_teacher_assignments()` - Teacher dashboard
- `get_classroom_materials()` - Material listing
- `get_user_audit_history()` - Audit queries

#### **Maintenance Functions** (System)
- `update_expired_enrollments()` - Subscription cleanup
- `renew_student_enrollment()` - Subscription renewal
- `get_enrollment_logs()` - System debugging

### **Current MVP Functions Available**

#### **User Management Functions** ✅
- `handle_new_user_signup()` - Automatic user creation trigger
- `create_teacher_by_admin()` - Admin-controlled teacher creation
- `log_audit_event()` - Comprehensive audit logging
- `get_user_audit_history()` - Audit trail retrieval

#### **Enrollment & Payment Functions** ✅
- `enroll_student_with_payment()` - Complete enrollment flow
- `get_student_classrooms()` - Student classroom lookup
- `renew_student_enrollment()` - Subscription renewal
- `update_expired_enrollments()` - Cleanup expired enrollments

#### **Assignment & Assessment Functions** ✅ *(NEW - MVP Priority)*
- `create_assignment()` - Teachers create assignments
- `get_teacher_assignments()` - List teacher's assignments
- `submit_assignment_attempt()` - Students submit work
- `grade_assignment()` - Teachers provide grades and feedback

#### **Learning Materials Functions** ✅ *(NEW - MVP Priority)*
- `upload_learning_material()` - Teachers upload content
- `get_classroom_materials()` - List classroom materials
- `track_material_access()` - Track student material usage

#### **Administrative Functions** ✅
- `assign_teacher_to_classroom()` - Teacher-classroom management
- `get_enrollment_logs()` - Troubleshooting enrollment issues

### **Comprehensive Logging Implementation** 🔍

All functions now include comprehensive logging:

#### **Function Entry/Exit Logging**
- Every function logs start and completion
- Parameters and user context captured
- Execution time and success/failure status

#### **Error Handling & Recovery**
- All exceptions caught and logged with context
- Detailed error messages with function state
- Recovery recommendations where applicable

#### **Audit Trail Integration**
- User actions logged via `log_audit_event()`
- Administrative activities tracked in `admin_activities`
- Security events captured with IP and user agent

#### **Performance Monitoring**
- Function execution times tracked
- Database query performance logged
- System health metrics captured

#### **Debug Support**
- Detailed metadata for troubleshooting
- Context preservation across function calls
- Integration with trigger logs for system debugging

---

## 🎯 **MVP Implementation Status**

### ✅ **COMPLETED MVP FEATURES**

#### **Student Experience (100% Complete)**
- User registration and authentication
- Classroom discovery and enrollment
- Payment processing (mock/simulation)
- Dashboard with real data
- Profile management
- Enrollment tracking and progress

#### **Teacher Experience (MVP Core - 90% Complete)**
- Admin-created teacher accounts ✅
- Assignment creation and management ✅
- Learning material upload and organization ✅
- Student work grading and feedback ✅
- Classroom content management ✅

#### **Administrative Functions (100% Complete)**
- Teacher account creation ✅
- Teacher-classroom assignment ✅
- Comprehensive audit logging ✅
- System monitoring and debugging ✅

### 🔄 **MVP IMPLEMENTATION PRIORITY**

#### **Phase 1: Teacher Portal Enhancement**
1. **UI Integration** - Connect new functions to Flutter UI
2. **Assignment Management** - Teacher assignment creation screen
3. **Material Upload** - File upload and management interface
4. **Grading Interface** - Student work review and grading UI

#### **Phase 2: Student Learning Experience**
1. **Assignment Submission** - Student assignment interface
2. **Material Access** - Learning material viewer
3. **Progress Tracking** - Academic progress dashboard
4. **Grade Viewing** - Student grade and feedback display

### 🚫 **EXCLUDED FROM MVP**

#### **Features Deferred to Later Phases**
- **Live Class Sessions** - Video conferencing integration
- **Parent Portal** - Parent monitoring and communication
- **Teacher Verification Workflow** - Document verification system
- **Advanced Analytics** - Detailed reporting and analytics
- **Real-time Notifications** - Push notification system

---

## 📊 **System Performance & Scalability**

### **Database Optimization**
- **Indexed Queries**: All foreign keys and frequently queried fields indexed
- **Efficient Joins**: Optimized table relationships minimize join complexity
- **Query Performance**: Complex queries using CTEs and efficient subqueries
- **Connection Pooling**: Supabase connection pooling configured

### **API Performance**
- **Function Efficiency**: Database functions minimize round trips
- **Bulk Operations**: Batch processing for multiple records
- **Caching Strategy**: Frequently accessed data cached appropriately
- **Rate Limiting**: API endpoints protected against abuse

### **Scalability Considerations**
- **Horizontal Scaling**: Database design supports read replicas
- **File Storage**: Supabase Storage for scalable file management
- **CDN Integration**: Static assets served via CDN
- **Background Jobs**: Heavy operations queued for background processing

---

## 🔐 **Security & Compliance**

### **Authentication & Authorization**
- **Supabase Auth**: Secure authentication with JWT tokens
- **Row Level Security**: Database-level access control
- **Role-Based Access**: User type-based permissions
- **Session Management**: Secure session handling

### **Data Protection**
- **Audit Logging**: Comprehensive activity logging
- **Data Encryption**: Sensitive data encrypted at rest
- **PII Handling**: Personal information protected
- **GDPR Compliance**: Data protection regulations compliance

### **Input Validation**
- **SQL Injection Prevention**: Parameterized queries throughout
- **XSS Protection**: Input sanitization and validation
- **File Upload Security**: File type and size validation
- **Rate Limiting**: API abuse prevention

---

## 🚀 **Deployment & DevOps**

### **Current Deployment Status**
- **Production APK**: 23.7MB builds successfully
- **Environment Variables**: Secure configuration management
- **Build Automation**: Automated build scripts available
- **Testing**: Integration testing via debug helpers

### **Infrastructure**
- **Database**: Supabase PostgreSQL with RLS
- **Authentication**: Supabase Auth
- **File Storage**: Supabase Storage
- **CDN**: Automatic CDN for static assets

### **Monitoring & Maintenance**
- **Logging**: Comprehensive application and system logs
- **Error Tracking**: Automated error detection and reporting
- **Performance Monitoring**: Database and API performance tracking
- **Backup Strategy**: Automated database backups

---

## 📈 **Future Roadmap**

### **Phase 2: Enhanced Teacher Experience**
- Live session management with video integration
- Advanced assignment types (multimedia, interactive)
- Student performance analytics and reporting
- Parent communication tools

### **Phase 3: Parent Portal**
- Child progress monitoring dashboard
- Payment management and billing history
- Teacher communication interface
- Educational resource recommendations

### **Phase 4: Advanced Features**
- Real-time messaging and notifications
- Mobile application development
- AI-powered learning recommendations
- Advanced analytics and reporting

### **Phase 5: Platform Expansion**
- Multi-language support
- Third-party integrations (calendar, email)
- Advanced assessment tools
- Certification and achievement systems

---

## 📞 **Technical Support & Documentation**

### **Key Technical Resources**
- **Database Schema**: Complete table definitions with relationships
- **API Documentation**: Function signatures and usage examples
- **Security Guidelines**: Authentication and authorization patterns
- **Deployment Guide**: Step-by-step deployment instructions

### **Development Standards**
- **Code Quality**: Consistent coding standards and documentation
- **Testing**: Comprehensive testing strategy and coverage
- **Security**: Security-first development approach
- **Performance**: Performance optimization guidelines

### **Support Contacts**
- **Developer**: Ragha (raghavpravinks@gmail.com)
- **Repository**: https://github.com/RaghavpravinKS/learned_flutter
- **Documentation**: PROJECT_STATUS.md for current progress

---

*This consolidated documentation serves as the single source of truth for the LearnED platform architecture and design. All system components, user flows, and technical specifications are captured in this comprehensive reference.*

**Last Updated**: October 12, 2025  
**Version**: MVP 1.0  
**Status**: Teacher Functions Ready for Implementation