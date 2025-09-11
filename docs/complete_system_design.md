# 🎓 LearnED Platform - Complete System Design

## Overview
This document outlines the complete flow of the LearnED e-learning platform, covering user management, classroom creation, pricing, enrollment, payments, subscriptions, and all supporting systems.

---

## 🏗️ Core System Architecture

### 1. User Management & Authentication Flow 👥

#### **Public User Signup Process** (Students & Parents Only)
```
auth.users (Supabase Auth) → public.users → user_profiles → [students/parents]
```

**Flow:**
1. **Supabase Authentication**: User signs up via `auth.users` with email/password
2. **Trigger Activation**: `handle_new_user_signup` trigger fires automatically
3. **User Creation**: Creates record in `public.users` with user_type (student/parent only)
4. **Profile Creation**: Automatically creates `user_profiles` entry for additional details
5. **Role-Specific Tables**: Based on user_type, creates record in:
   - `students` table (with auto-generated student_id)
   - `parents` table (with auto-generated parent_id)

#### **Admin-Controlled Teacher Onboarding** 🛡️
```
Admin Panel → Create Teacher Account → Teacher Profile Completion
```

**Flow:**
1. **Admin Creates Account**: Admin manually creates teacher account with basic info:
   - Email, temporary password, first_name, last_name
   - Sets user_type as 'teacher'
   - Creates record in `auth.users` and `public.users`
   - Auto-generates teacher_id in `teachers` table
   
2. **Teacher Profile Completion**: Teacher logs in and completes their profile:
   - Bio, qualifications, experience
   - Document uploads (certificates, ID proof)
   - Availability settings
   - Profile photo

3. **Admin Verification**: Admin reviews and approves teacher profile:
   - Document verification
   - Background checks
   - Sets `is_verified` flag to true

**Tables Involved:**
- `auth.users` (Supabase managed)
- `public.users` (our main user table)
- `user_profiles` (extended user information)
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

### 6. Class Session Management 📅

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

### 7. Assignment & Assessment System 📝

#### **Assignment Flow**
```
assignments → assignment_questions → student_assignment_attempts
```

**Flow:**
1. **Assignment Creation**: Teachers create assignments with questions
2. **Question Bank**: `assignment_questions` stores MCQ, essays, etc.
3. **Student Attempts**: Track attempts, scores, time taken
4. **Grading**: Auto-grading for MCQ, manual for essays

---

### 8. Learning Materials & Resources 📚

#### **Content Management**
```
learning_materials → student_material_access
```

**Flow:**
1. **Upload**: Teachers upload materials (videos, documents, presentations)
2. **Access Control**: Public/private materials per classroom
3. **Tracking**: Monitor student downloads and access patterns

---

### 9. Communication & Notification System 📢

#### **Notification Pipeline**
```
system_notifications + email_queue + audit_log
```

**Flow:**
1. **Event Triggers**: Enrollment, payment, class reminders
2. **Multi-Channel**: In-app notifications + email
3. **Audit Trail**: All actions logged for compliance

---

### 10. Family & Parent Integration 👨‍👩‍👧‍👦

#### **Parent-Student Relationships**
```
parents → parent_student_relations → students
```

**Flow:**
1. **Parent Signup**: Parents create accounts separately
2. **Child Linking**: Connect to student accounts via invite/code
3. **Progress Monitoring**: Parents view child's progress, payments, attendance

---

## 🔧 Missing Tables & Enhancements

### **Proposed Additional Tables:**

#### **1. Teacher Document Management**
```sql
CREATE TABLE teacher_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES teachers(id),
  document_type VARCHAR NOT NULL, -- 'certificate', 'id_proof', 'background_check', 'resume'
  document_name VARCHAR NOT NULL,
  file_url TEXT NOT NULL,
  file_size BIGINT,
  mime_type VARCHAR,
  verification_status VARCHAR DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
  verified_by UUID REFERENCES users(id), -- Admin who verified
  verified_at TIMESTAMPTZ,
  rejection_reason TEXT,
  expires_at TIMESTAMPTZ, -- For documents that expire
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **2. Admin Activity Log**
```sql
CREATE TABLE admin_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES users(id),
  activity_type VARCHAR NOT NULL, -- 'create_teacher', 'verify_document', 'approve_teacher'
  target_user_id UUID REFERENCES users(id),
  description TEXT,
  metadata JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **3. Teacher Verification Workflow**
```sql
CREATE TABLE teacher_verification (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES teachers(id) UNIQUE,
  verification_stage VARCHAR DEFAULT 'documents_pending' CHECK (verification_stage IN (
    'documents_pending', 'documents_submitted', 'under_review', 'approved', 'rejected'
  )),
  documents_submitted_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES users(id),
  reviewed_at TIMESTAMPTZ,
  approval_notes TEXT,
  rejection_reason TEXT,
  background_check_status VARCHAR CHECK (background_check_status IN ('pending', 'clear', 'flagged')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **4. Email Queue System**
```sql
CREATE TABLE email_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_email VARCHAR NOT NULL,
  subject VARCHAR NOT NULL,
  template_name VARCHAR,
  template_data JSONB,
  status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  retry_count INTEGER DEFAULT 0,
  scheduled_for TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **2. Audit Log System**
```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action VARCHAR NOT NULL,
  table_name VARCHAR NOT NULL,
  record_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **3. Transaction Tracking**
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  payment_id UUID REFERENCES payments(id),
  amount NUMERIC NOT NULL,
  currency VARCHAR DEFAULT 'USD',
  gateway VARCHAR,
  gateway_transaction_id VARCHAR,
  status VARCHAR CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
  gateway_response JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **4. Student Performance Analytics**
```sql
CREATE TABLE student_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES students(id),
  classroom_id UUID REFERENCES classrooms(id),
  metric_type VARCHAR NOT NULL, -- 'attendance', 'assignment_score', 'participation'
  metric_value NUMERIC,
  measurement_date DATE,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **5. Teacher Reviews & Ratings**
```sql
CREATE TABLE teacher_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id UUID REFERENCES teachers(id),
  student_id UUID REFERENCES students(id),
  classroom_id UUID REFERENCES classrooms(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  is_anonymous BOOLEAN DEFAULT false,
  is_approved BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **6. Refund Management**
```sql
CREATE TABLE refunds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID REFERENCES payments(id),
  amount NUMERIC NOT NULL,
  reason TEXT,
  status VARCHAR CHECK (status IN ('pending', 'approved', 'rejected', 'processed')),
  processed_by UUID REFERENCES users(id),
  gateway_refund_id VARCHAR,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🔄 Complete User Journey Examples

### **Student Enrollment Journey** (Self-Signup)
1. Student signs up → `users`, `user_profiles`, `students` created
2. Student browses → Query `classrooms` + `classroom_pricing` + `teachers`
3. Student selects classroom → Create `enrollment_requests` (pending)
4. Student pays → Create `payments` (completed)
5. System processes → Create `student_classroom_assignments` (active)
6. If monthly plan → Create `student_subscriptions` (active)
7. System sends emails → Add to `email_queue`
8. Log everything → Add to `audit_log`

### **Teacher Onboarding Journey** (Admin-Controlled)
1. **Admin creates teacher** → `users`, `teachers`, `teacher_verification` created
2. **Email sent to teacher** → Login credentials via `email_queue`
3. **Teacher completes profile** → Updates `teachers`, uploads to `teacher_documents`
4. **Admin reviews** → Updates `teacher_verification`, approves documents
5. **Teacher approved** → `teachers.is_verified = true`, can create classrooms
6. **Teacher creates classes** → `classrooms`, `classroom_pricing` setup
7. **All actions logged** → `admin_activities`, `audit_log`

### **Parent Monitoring Journey** (Self-Signup + Child Linking)
1. Parent account → `parents` table
2. Link to student → `parent_student_relations`
3. View progress → Query `student_progress`, `session_attendance`
4. Payment oversight → View `payments` for student
5. Communication → Receive `system_notifications`

### **Admin Management Journey**
1. **Teacher Management** → Create accounts, verify documents, approve teachers
2. **Platform Oversight** → Monitor payments, resolve disputes, manage refunds
3. **Quality Control** → Review teacher performance, handle complaints
4. **Analytics** → Platform metrics, revenue reports, user engagement

---

## 🚀 Implementation Priority

### **Phase 1: Core Platform (Current + Admin Features)**
- ✅ Student signup flow
- ✅ Basic enrollment function
- ✅ Payment processing
- 🆕 Admin panel for teacher creation
- 🆕 Teacher document upload system
- 🆕 Teacher verification workflow

### **Phase 2: Enhanced Teacher Experience**
- 📧 Email notification system
- 📊 Admin activity logging
- 💰 Teacher revenue tracking
- 📋 Classroom management tools

### **Phase 3: Advanced Platform Features**
- 📈 Analytics dashboard
- ⭐ Teacher rating system
- 💸 Refund management
- 🔄 Subscription renewals

### **Phase 4: Family & Community Features**
- 👨‍👩‍👧‍👦 Parent portal
- 📱 Mobile notifications
- 📋 Progress reports
- 💬 Communication tools

---

## 🎯 Updated Next Steps

1. **Update signup trigger** - Remove automatic teacher creation
2. **Create admin functions** - Teacher account creation, verification
3. **Build teacher document system** - Upload, review, approval workflow
4. **Implement verification process** - Admin approval before classroom creation
5. **Test complete teacher flow** - Admin creates → Teacher completes → Admin verifies

### **Key Changes from Original Design:**

#### **🔒 Security Improvements:**
- **No public teacher signup** - Prevents spam/fake teachers
- **Document verification** - Ensures teacher credentials
- **Admin approval** - Quality control gate

#### **🎯 Quality Control:**
- **Staged onboarding** - Step-by-step teacher setup
- **Document management** - Centralized credential storage
- **Verification workflow** - Clear approval process

#### **📊 Better Tracking:**
- **Admin activities** - All teacher management actions logged
- **Verification stages** - Track progress through approval
- **Document status** - Monitor compliance and renewals

This admin-controlled approach ensures only qualified, verified teachers can create classrooms and teach students. Would you like me to proceed with creating the SQL migration files for these new teacher management tables?
