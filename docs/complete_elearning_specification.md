# Complete E-Learning Platform Development Specification

## 📋 Project Overview

### Business Requirements
**Platform Type**: One-to-one e-learning platform with video conferencing
**Target Platforms**: Flutter (iOS & Android)
**Backend**: Supabase (PostgreSQL)
**Key Users**: Students, Teachers, Parents, Admins

### Core Functionality
- Student registration and profile management
- One-to-one video sessions (Zoom/Google Meet integration)
- Teacher classroom management and content upload
- Admin assignment system (students to teachers)
- Payment processing and fee management
- Progress tracking and analytics
- Assessment and testing system
- Real-time communication and notifications

---

## 🗄️ Database Schema Design

### Core User Tables

#### users
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('student', 'teacher', 'parent', 'admin')),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### user_profiles
```sql
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date_of_birth DATE,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Student-Specific Tables

#### students
```sql
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    student_id VARCHAR(50) UNIQUE NOT NULL,
    grade_level INTEGER,
    school_name VARCHAR(200),
    learning_goals TEXT,
    special_requirements TEXT,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### parent_student_relations
```sql
CREATE TABLE parent_student_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES users(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    relationship VARCHAR(50) NOT NULL,
    is_primary_contact BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(parent_id, student_id)
);
```

### Teacher-Specific Tables

#### teachers
```sql
CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    teacher_id VARCHAR(50) UNIQUE NOT NULL,
    qualifications TEXT,
    experience_years INTEGER,
    specializations TEXT[],
    hourly_rate DECIMAL(10,2),
    bio TEXT,
    availability_timezone VARCHAR(50),
    is_verified BOOLEAN DEFAULT false,
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### teacher_availability
```sql
CREATE TABLE teacher_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(teacher_id, day_of_week, start_time)
);
```

### Classroom & Assignment Tables

#### classrooms
```sql
CREATE TABLE classrooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    subject VARCHAR(100) NOT NULL,
    grade_level INTEGER,
    description TEXT,
    max_students INTEGER DEFAULT 1,
    meeting_link TEXT,
    meeting_id VARCHAR(100),
    meeting_password VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### student_classroom_assignments
```sql
CREATE TABLE student_classroom_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES users(id),
    assigned_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'dropped')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, classroom_id)
);
```

### Session & Class Management

#### class_sessions
```sql
CREATE TABLE class_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    scheduled_start TIMESTAMP WITH TIME ZONE NOT NULL,
    scheduled_end TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_start TIMESTAMP WITH TIME ZONE,
    actual_end TIMESTAMP WITH TIME ZONE,
    session_status VARCHAR(20) DEFAULT 'scheduled' CHECK (session_status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show')),
    meeting_url TEXT,
    recording_url TEXT,
    notes TEXT,
    homework_assigned TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### session_attendance
```sql
CREATE TABLE session_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES class_sessions(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    attendance_status VARCHAR(20) NOT NULL CHECK (attendance_status IN ('present', 'absent', 'late', 'left_early')),
    join_time TIMESTAMP WITH TIME ZONE,
    leave_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    participation_score INTEGER CHECK (participation_score BETWEEN 1 AND 10),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(session_id, student_id)
);
```

### Content & Materials

#### learning_materials
```sql
CREATE TABLE learning_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    classroom_id UUID REFERENCES classrooms(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    material_type VARCHAR(50) NOT NULL CHECK (material_type IN ('note', 'video', 'document', 'presentation', 'assignment', 'recording')),
    file_url TEXT,
    file_size BIGINT,
    mime_type VARCHAR(100),
    is_public BOOLEAN DEFAULT false,
    tags TEXT[],
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### student_material_access
```sql
CREATE TABLE student_material_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    material_id UUID REFERENCES learning_materials(id) ON DELETE CASCADE,
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    download_count INTEGER DEFAULT 0,
    last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, material_id)
);
```

### Assessment & Progress

#### assessments
```sql
CREATE TABLE assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    assessment_type VARCHAR(50) NOT NULL CHECK (assessment_type IN ('quiz', 'test', 'assignment', 'project')),
    total_points INTEGER NOT NULL,
    time_limit_minutes INTEGER,
    due_date TIMESTAMP WITH TIME ZONE,
    is_published BOOLEAN DEFAULT false,
    instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### assessment_questions
```sql
CREATE TABLE assessment_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'short_answer', 'essay')),
    options JSONB,
    correct_answer TEXT,
    points INTEGER NOT NULL,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### student_assessment_attempts
```sql
CREATE TABLE student_assessment_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    attempt_number INTEGER DEFAULT 1,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submitted_at TIMESTAMP WITH TIME ZONE,
    score INTEGER,
    percentage DECIMAL(5,2),
    time_taken_minutes INTEGER,
    status VARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted', 'graded')),
    feedback TEXT,
    answers JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(assessment_id, student_id, attempt_number)
);
```

### Payment & Billing

#### payment_plans
```sql
CREATE TABLE payment_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price_per_hour DECIMAL(10,2),
    price_per_month DECIMAL(10,2),
    price_per_session DECIMAL(10,2),
    billing_cycle VARCHAR(20) CHECK (billing_cycle IN ('hourly', 'weekly', 'monthly', 'per_session')),
    features JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### student_subscriptions
```sql
CREATE TABLE student_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    payment_plan_id UUID REFERENCES payment_plans(id),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'suspended')),
    auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### payments
```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES student_subscriptions(id),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method VARCHAR(50),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    transaction_id VARCHAR(200),
    payment_gateway VARCHAR(50),
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Analytics & Progress Tracking

#### student_progress
```sql
CREATE TABLE student_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    classroom_id UUID REFERENCES classrooms(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    classes_attended INTEGER DEFAULT 0,
    total_hours DECIMAL(5,2) DEFAULT 0,
    average_score DECIMAL(5,2),
    assignments_completed INTEGER DEFAULT 0,
    assignments_pending INTEGER DEFAULT 0,
    weak_areas TEXT[],
    strong_areas TEXT[],
    teacher_feedback TEXT,
    parent_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, classroom_id, week_start_date)
);
```

#### system_notifications
```sql
CREATE TABLE system_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN ('class_reminder', 'payment_due', 'assignment_due', 'progress_update', 'system_update')),
    is_read BOOLEAN DEFAULT false,
    scheduled_for TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Performance Indexes
```sql
-- User-related indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_type ON users(user_type);
CREATE INDEX idx_users_active ON users(is_active);

-- Student-related indexes
CREATE INDEX idx_students_user_id ON students(user_id);
CREATE INDEX idx_students_grade ON students(grade_level);
CREATE INDEX idx_parent_student_relations_parent ON parent_student_relations(parent_id);
CREATE INDEX idx_parent_student_relations_student ON parent_student_relations(student_id);

-- Teacher-related indexes
CREATE INDEX idx_teachers_user_id ON teachers(user_id);
CREATE INDEX idx_teachers_status ON teachers(status);
CREATE INDEX idx_teacher_availability_teacher ON teacher_availability(teacher_id);

-- Classroom and session indexes
CREATE INDEX idx_classrooms_teacher ON classrooms(teacher_id);
CREATE INDEX idx_student_assignments_student ON student_classroom_assignments(student_id);
CREATE INDEX idx_student_assignments_classroom ON student_classroom_assignments(classroom_id);
CREATE INDEX idx_class_sessions_classroom ON class_sessions(classroom_id);
CREATE INDEX idx_class_sessions_scheduled ON class_sessions(scheduled_start);
CREATE INDEX idx_session_attendance_session ON session_attendance(session_id);
CREATE INDEX idx_session_attendance_student ON session_attendance(student_id);

-- Material and assessment indexes
CREATE INDEX idx_learning_materials_teacher ON learning_materials(teacher_id);
CREATE INDEX idx_learning_materials_classroom ON learning_materials(classroom_id);
CREATE INDEX idx_assessments_classroom ON assessments(classroom_id);
CREATE INDEX idx_assessment_attempts_student ON student_assessment_attempts(student_id);

-- Payment indexes
CREATE INDEX idx_payments_student ON payments(student_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_subscriptions_student ON student_subscriptions(student_id);

-- Progress and notification indexes
CREATE INDEX idx_student_progress_student ON student_progress(student_id);
CREATE INDEX idx_notifications_user ON system_notifications(user_id);
CREATE INDEX idx_notifications_unread ON system_notifications(user_id, is_read);
```

---

## 🔄 System Architecture & State Flow

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Web Dashboard │    │  Admin Panel    │
│   (iOS/Android) │    │   (React/Vue)   │    │   (Web-based)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   API Gateway   │
                    │   (Supabase)    │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │  File Storage   │    │  Real-time      │
│   Database      │    │   (Supabase)    │    │  Subscriptions  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
┌─────────────────┐
│  External APIs  │
│ • Zoom/Meet API │
│ • Payment       │
│ • Notifications │
└─────────────────┘
```

### Main Application State Flow

**App Start Flow:**
```
App Launch → Check Authentication → Route to Dashboard → Load User Data
```

**Authentication Flow:**
```
Login Screen → Validate Credentials → Set Session → Dashboard Router → User-Specific Dashboard
```

**Session Flow:**
```
Session Scheduled → Pre-session Reminder → Join Session → Active Session → Session Complete → Feedback Collection → Attendance Record
```

**Payment Flow:**
```
Payment Dashboard → Select Amount → Payment Gateway → Process Payment → Success/Failure → Update Records
```

**Assessment Flow:**
```
Assessment List → Start Assessment → Answer Questions → Submit Assessment → Grade Assessment → Show Results
```

---

## 📱 Complete Page Structure

### 🔐 Authentication & Onboarding (8 pages)
1. **Splash Screen** (`/splash`) - App loading and initialization
2. **Welcome/Onboarding** (`/welcome`) - App introduction slides
3. **Login Page** (`/login`) - Email/password authentication
4. **Registration Page** (`/register`) - New user signup
5. **Forgot Password** (`/forgot-password`) - Password reset request
6. **Reset Password** (`/reset-password`) - New password setup
7. **Email Verification** (`/verify-email`) - Email confirmation
8. **User Type Selection** (`/select-user-type`) - Role selection

### 👨‍🎓 Student Pages (27 pages)
9. **Student Dashboard** (`/student/dashboard`) - Main student overview
10. **Student Profile** (`/student/profile`) - Personal information view
11. **Edit Student Profile** (`/student/profile/edit`) - Profile editing
12. **My Classes** (`/student/classes`) - Enrolled classes list
13. **Class Details** (`/student/classes/:classId`) - Individual class info
14. **Schedule** (`/student/schedule`) - Calendar view of sessions
15. **Join Session** (`/student/session/join/:sessionId`) - Session waiting room
16. **Session Active** (`/student/session/active/:sessionId`) - Live video session
17. **Session Feedback** (`/student/session/feedback/:sessionId`) - Post-session rating
18. **My Progress** (`/student/progress`) - Learning analytics dashboard
19. **Learning Materials** (`/student/materials`) - Content library
20. **Material Viewer** (`/student/materials/:materialId`) - Content viewer
21. **My Tests** (`/student/tests`) - Assessment overview
22. **Take Test** (`/student/test/:testId`) - Assessment interface
23. **Test Results** (`/student/test/:testId/results`) - Score and feedback
24. **Payment Dashboard** (`/student/payments`) - Billing overview
25. **Make Payment** (`/student/payments/new`) - Payment processing
26. **Payment Success** (`/student/payments/success`) - Confirmation page
27. **Payment Failed** (`/student/payments/failed`) - Error handling
28. **Messages** (`/student/messages`) - Communication center
29. **Chat Window** (`/student/messages/:conversationId`) - Real-time chat
30. **Help & Support** (`/student/support`) - FAQ and support
31. **Student Settings** (`/student/settings`) - Preferences and configuration

### 👨‍🏫 Teacher Pages (21 pages)
32. **Teacher Dashboard** (`/teacher/dashboard`) - Teaching overview
33. **Teacher Profile** (`/teacher/profile`) - Professional profile
34. **Edit Teacher Profile** (`/teacher/profile/edit`) - Profile management
35. **My Classrooms** (`/teacher/classrooms`) - Classroom management
36. **Create Classroom** (`/teacher/classrooms/new`) - New classroom setup
37. **Classroom Details** (`/teacher/classrooms/:classroomId`) - Classroom overview
38. **Manage Students** (`/teacher/students`) - Student roster
39. **Student Profile View** (`/teacher/students/:studentId`) - Individual student details
40. **Schedule Session** (`/teacher/sessions/new`) - Session planning
41. **My Schedule** (`/teacher/schedule`) - Teaching calendar
42. **Start Session** (`/teacher/session/start/:sessionId`) - Pre-session setup
43. **Session Active** (`/teacher/session/active/:sessionId`) - Live teaching interface
44. **Session Summary** (`/teacher/session/summary/:sessionId`) - Post-session notes
45. **My Materials** (`/teacher/materials`) - Content library
46. **Upload Material** (`/teacher/materials/upload`) - Content upload
47. **Material Editor** (`/teacher/materials/:materialId/edit`) - Content editing
48. **My Assessments** (`/teacher/assessments`) - Assessment management
49. **Create Assessment** (`/teacher/assessments/new`) - Test builder
50. **Assessment Results** (`/teacher/assessments/:assessmentId/results`) - Performance analytics
51. **Teaching Analytics** (`/teacher/analytics`) - Teaching insights
52. **Generate Reports** (`/teacher/reports`) - Student progress reports

### 👨‍👩‍👧‍👦 Parent Pages (9 pages)
53. **Parent Dashboard** (`/parent/dashboard`) - Family overview
54. **Parent Profile** (`/parent/profile`) - Parent information
55. **My Children** (`/parent/children`) - Children list
56. **Child Progress** (`/parent/children/:childId/progress`) - Individual child analytics
57. **Child Schedule** (`/parent/children/:childId/schedule`) - Child's timetable
58. **Teacher Communication** (`/parent/messages`) - Parent-teacher messaging
59. **Parent-Teacher Meetings** (`/parent/meetings`) - Meeting scheduler
60. **Payment Management** (`/parent/payments`) - Family billing
61. **Child Payment Details** (`/parent/payments/:childId`) - Individual billing

### 👨‍💼 Admin Pages (15 pages)
62. **Admin Dashboard** (`/admin/dashboard`) - System overview
63. **Admin Profile** (`/admin/profile`) - Administrator settings
64. **All Users** (`/admin/users`) - User management
65. **User Details** (`/admin/users/:userId`) - Individual user management
66. **Create User** (`/admin/users/new`) - New user creation
67. **Student Management** (`/admin/students`) - Student oversight
68. **Teacher Management** (`/admin/teachers`) - Teacher management
69. **Parent Management** (`/admin/parents`) - Parent oversight
70. **Teacher-Student Assignment** (`/admin/assignments`) - Assignment management
71. **Create Assignment** (`/admin/assignments/new`) - New assignments
72. **Classroom Oversight** (`/admin/classrooms`) - System-wide classroom view
73. **System Settings** (`/admin/settings`) - Platform configuration
74. **Payment Administration** (`/admin/payments`) - Financial oversight
75. **Reports & Analytics** (`/admin/reports`) - System analytics
76. **Support & Tickets** (`/admin/support`) - User support management

### 🔧 Shared/Common Pages (9 pages)
77. **App Settings** (`/settings`) - Application preferences
78. **Notification Settings** (`/settings/notifications`) - Notification management
79. **Privacy Settings** (`/settings/privacy`) - Privacy controls
80. **Search Results** (`/search`) - Global search
81. **Notifications** (`/notifications`) - Notification center
82. **Calendar View** (`/calendar`) - Unified calendar
83. **File Manager** (`/files`) - File storage and management
84. **Video Player** (`/video/:videoId`) - Custom video player
85. **About App** (`/about`) - App information and legal

---

## 🚀 Development Roadmap (48 Weeks)

### Phase 1: Foundation (Weeks 1-4)
**Goal**: Core infrastructure and authentication
- Set up Supabase project and database schema
- Create Flutter project structure
- Implement complete authentication system
- Basic user session management
- User type routing

**Pages to implement**: 1-8 (Authentication pages)

### Phase 2: User Management (Weeks 5-8)
**Goal**: User profiles and basic dashboards
- Complete user profile systems for all user types
- Basic dashboard layouts
- User onboarding flows
- Profile editing functionality

**Pages to implement**: 9-11, 32-34, 53-54, 62-63 (Basic profiles and dashboards)...........

### Phase 3: Core Learning Features (Weeks 9-16)
**Goal**: Classroom and session management
- Teacher classroom creation and management
- Student-teacher assignment system (admin)
- Session scheduling and calendar integration
- Basic video conferencing integration
- Session attendance tracking

**Pages to implement**: 12-17, 35-43, 69-71 (Core classroom and session pages)

### Phase 4: Content & Assessment (Weeks 17-24)
**Goal**: Learning materials and testing system
- File upload and content management
- Learning materials organization and sharing
- Assessment creation tools
- Quiz/test taking interface
- Automated grading system

**Pages to implement**: 18-23, 44-50, 77-81 (Content and assessment pages)

### Phase 5: Payment & Analytics (Weeks 25-32)
**Goal**: Payment processing and analytics
- Payment gateway integration
- Subscription management
- Detailed progress tracking and analytics
- Report generation system
- Parent dashboards

**Pages to implement**: 24-31, 51-52, 55-61, 72-76 (Payment and analytics pages)

### Phase 6: Communication & Advanced Features (Weeks 33-40)
**Goal**: Enhanced user experience
- Real-time messaging system
- Push notifications
- Advanced analytics and reporting
- System administration tools
- Performance optimization

**Pages to implement**: 82-85 (Remaining shared pages and advanced features)

### Phase 7: Testing & Launch (Weeks 41-48)
**Goal**: Quality assurance and deployment
- Comprehensive testing (unit, integration, UI)
- Performance optimization
- Security auditing
- App store preparation and submission
- Production deployment

---

## 🛠️ Technical Implementation Guidelines

### Flutter Project Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   └── route_constants.dart
│   ├── error/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/
│   │   ├── supabase_client.dart
│   │   └── api_client.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── helpers.dart
│   └── models/
│       ├── user_model.dart
│       ├── student_model.dart
│       ├── teacher_model.dart
│       └── session_model.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── providers/
│   ├── dashboard/
│   ├── classroom/
│   ├── session/
│   ├── assessment/
│   ├── payment/
│   └── profile/
└── shared/
    ├── widgets/
    │   ├── buttons/
    │   ├── forms/
    │   ├── cards/
    │   └── dialogs/
    ├── services/
    │   ├── auth_service.dart
    │   ├── storage_service.dart
    │   ├── notification_service.dart
    │   └── payment_service.dart
    └── providers/
        ├── auth_provider.dart
        ├── user_provider.dart
        └── app_provider.dart
```

### State Management Strategy
- **Primary**: Riverpod for complex state management
- **Local**: useState for simple widget state
- **Persistence**: SharedPreferences + Hive for local storage
- **Real-time**: Supabase real-time subscriptions

### Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  riverpod: ^2.0.0
  go_router: ^12.0.0
  json_annotation: ^4.8.0
  freezed_annotation: ^2.4.1
  hive: ^2.2.3
  shared_preferences: ^2.2.0
  image_picker: ^1.0.0
  file_picker: ^6.0.0
  video_player: ^2.7.0
  agora_rtc_engine: ^6.3.0  # For video calls
  firebase_messaging: ^14.7.0
  razorpay_flutter: ^1.3.6  # For payments
  dio: ^5.3.0
  cached_network_image: ^3.3.0
  permission_handler: ^11.0.0
```

### API Design Patterns
```dart
// Example API service structure
abstract class ApiService {
  Future<ApiResponse<T>> get<T>(String endpoint);
  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic> data);
  Future<ApiResponse<T>> put<T>(String endpoint, Map<String, dynamic> data);
  Future<ApiResponse<T>> delete<T>(String endpoint);
}

// Repository pattern
abstract class UserRepository {
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, User>> updateProfile(User user);
  Future<Either<Failure, void>> deleteAccount();
}
```

### Security Implementation
- JWT token-based authentication via Supabase
- Row Level Security (RLS) policies in PostgreSQL
- Input validation on both client and server
- File upload security with type and size restrictions
- API rate limiting and request throttling
- Secure storage for sensitive data

### Row Level Security (RLS) Policies Examples
```sql
-- Users can only see their own data
CREATE POLICY user_access_policy ON users
    FOR ALL USING (auth.uid() = id);

-- Students can only see their own records
CREATE POLICY student_access_policy ON students
    FOR ALL USING (auth.uid() = user_id);

-- Teachers can see students assigned to them
CREATE POLICY teacher_student_access ON students
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM student_classroom_assignments sca
            JOIN classrooms c ON sca.classroom_id = c.id
            WHERE sca.student_id = students.id 
            AND c.teacher_id IN (
                SELECT id FROM teachers WHERE user_id = auth.uid()
            )
        )
    );

-- Parents can see their children's data
CREATE POLICY parent_child_access ON students
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM parent_student_relations psr
            WHERE psr.student_id = students.id 
            AND psr.parent_id = auth.uid()
        )
    );
```

---

## 📋 API Endpoints Specification

### Authentication Endpoints
```
POST /auth/register
POST /auth/login
POST /auth/logout
POST /auth/refresh-token
POST /auth/forgot-password
POST /auth/reset-password
POST /auth/verify-email
```

### User Management Endpoints
```
GET    /api/users/profile
PUT    /api/users/profile
DELETE /api/users/account
POST   /api/users/upload-avatar
GET    /api/users/:userId (admin only)
```

### Student Endpoints
```
GET    /api/students/dashboard
GET    /api/students/classes
GET    /api/students/:studentId/progress
GET    /api/students/:studentId/schedule
POST   /api/students/:studentId/sessions/:sessionId/join
GET    /api/students/:studentId/materials
GET    /api/students/:studentId/assessments
POST   /api/students/:studentId/assessments/:assessmentId/attempt
```

### Teacher Endpoints
```
GET    /api/teachers/dashboard
GET    /api/teachers/classrooms
POST   /api/teachers/classrooms
PUT    /api/teachers/classrooms/:classroomId
GET    /api/teachers/students
GET    /api/teachers/sessions
POST   /api/teachers/sessions
PUT    /api/teachers/sessions/:sessionId
POST   /api/teachers/materials/upload
GET    /api/teachers/materials
POST   /api/teachers/assessments
GET    /api/teachers/assessments/:assessmentId/results
```

### Parent Endpoints
```
GET    /api/parents/dashboard
GET    /api/parents/children
GET    /api/parents/children/:childId/progress
GET    /api/parents/children/:childId/schedule
GET    /api/parents/payments
POST   /api/parents/payments
```

### Admin Endpoints
```
GET    /api/admin/dashboard
GET    /api/admin/users
POST   /api/admin/users
PUT    /api/admin/users/:userId
DELETE /api/admin/users/:userId
POST   /api/admin/assignments
GET    /api/admin/assignments
GET    /api/admin/reports
GET    /api/admin/payments
```

### Session Management Endpoints
```
GET    /api/sessions/:sessionId
POST   /api/sessions/:sessionId/start
POST   /api/sessions/:sessionId/end
POST   /api/sessions/:sessionId/attendance
GET    /api/sessions/:sessionId/recording
```

### Payment Endpoints
```
GET    /api/payments/plans
POST   /api/payments/create-order
POST   /api/payments/verify
GET    /api/payments/history
POST   /api/payments/refund
```

---

## 🎨 UI/UX Design Guidelines

### Design System
```dart
// Color Scheme
class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF10B981);
  static const Color accent = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF97316);
  static const Color success = Color(0xFF22C55E);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E293B);
}

// Typography
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurface,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );
}

// Spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

### Component Library
```dart
// Custom Button Widget
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  
  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
  }) : super(key: key);
}

// Custom Input Field
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  
  const AppTextField({
    Key? key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.obscureText = false,
  }) : super(key: key);
}

// Dashboard Card Widget
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  
  const DashboardCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);
}
```

### Navigation Structure
```dart
// Bottom Navigation for each user type
class StudentBottomNav {
  static const List<NavigationItem> items = [
    NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/student/dashboard'),
    NavigationItem(icon: Icons.schedule, label: 'Schedule', route: '/student/schedule'),
    NavigationItem(icon: Icons.trending_up, label: 'Progress', route: '/student/progress'),
    NavigationItem(icon: Icons.message, label: 'Messages', route: '/student/messages'),
    NavigationItem(icon: Icons.person, label: 'Profile', route: '/student/profile'),
  ];
}

class TeacherBottomNav {
  static const List<NavigationItem> items = [
    NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/teacher/dashboard'),
    NavigationItem(icon: Icons.people, label: 'Students', route: '/teacher/students'),
    NavigationItem(icon: Icons.schedule, label: 'Schedule', route: '/teacher/schedule'),
    NavigationItem(icon: Icons.folder, label: 'Materials', route: '/teacher/materials'),
    NavigationItem(icon: Icons.person, label: 'Profile', route: '/teacher/profile'),
  ];
}
```

---

## 🔄 Real-time Features Implementation

### Supabase Real-time Subscriptions
```dart
class RealtimeService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  // Listen to session status changes
  static Stream<List<ClassSession>> watchSessionUpdates(String userId) {
    return _client
        .from('class_sessions')
        .stream(primaryKey: ['id'])
        .eq('student_id', userId)
        .map((data) => data.map((json) => ClassSession.fromJson(json)).toList());
  }
  
  // Listen to new messages
  static Stream<List<Message>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }
  
  // Listen to attendance updates
  static Stream<List<SessionAttendance>> watchAttendance(String sessionId) {
    return _client
        .from('session_attendance')
        .stream(primaryKey: ['id'])
        .eq('session_id', sessionId)
        .map((data) => data.map((json) => SessionAttendance.fromJson(json)).toList());
  }
}
```

### Push Notifications
```dart
class NotificationService {
  static Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission();
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }
  
  static Future<void> subscribeToUserNotifications(String userId) async {
    await FirebaseMessaging.instance.subscribeToTopic('user_$userId');
  }
  
  static Future<void> sendSessionReminder(String studentId, ClassSession session) async {
    // Implementation for sending session reminders
  }
}
```

---

## 📊 Analytics & Monitoring

### Key Metrics to Track
```dart
class AnalyticsEvents {
  // User engagement
  static const String userLogin = 'user_login';
  static const String sessionJoined = 'session_joined';
  static const String sessionCompleted = 'session_completed';
  static const String assessmentStarted = 'assessment_started';
  static const String assessmentCompleted = 'assessment_completed';
  
  // Business metrics
  static const String paymentInitiated = 'payment_initiated';
  static const String paymentCompleted = 'payment_completed';
  static const String subscriptionCreated = 'subscription_created';
  
  // Performance metrics
  static const String appCrash = 'app_crash';
  static const String apiError = 'api_error';
  static const String slowResponse = 'slow_response';
}

class AnalyticsService {
  static void trackEvent(String eventName, Map<String, dynamic> parameters) {
    // Firebase Analytics implementation
    FirebaseAnalytics.instance.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }
  
  static void trackUserProperty(String name, String value) {
    FirebaseAnalytics.instance.setUserProperty(
      name: name,
      value: value,
    );
  }
}
```

---

## 🧪 Testing Strategy

### Test Structure
```
test/
├── unit/
│   ├── models/
│   ├── services/
│   ├── repositories/
│   └── usecases/
├── widget/
│   ├── auth/
│   ├── dashboard/
│   └── shared/
├── integration/
│   ├── auth_flow_test.dart
│   ├── session_flow_test.dart
│   └── payment_flow_test.dart
└── helpers/
    ├── test_data.dart
    ├── mock_services.dart
    └── test_utils.dart
```

### Example Test Cases
```dart
// Unit Test Example
class AuthServiceTest {
  group('AuthService', () {
    late AuthService authService;
    late MockSupabaseClient mockClient;
    
    setUp(() {
      mockClient = MockSupabaseClient();
      authService = AuthService(mockClient);
    });
    
    test('should login user successfully', () async {
      // Arrange
      when(mockClient.auth.signInWithPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => AuthResponse(/* mock data */));
      
      // Act
      final result = await authService.login('test@example.com', 'password123');
      
      // Assert
      expect(result.isRight(), true);
    });
  });
}

// Widget Test Example
testWidgets('Login page should show validation errors', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LoginPage(),
    ),
  );
  
  // Find and tap login button without entering data
  final loginButton = find.byKey(Key('login_button'));
  await tester.tap(loginButton);
  await tester.pump();
  
  // Verify validation errors are shown
  expect(find.text('Email is required'), findsOneWidget);
  expect(find.text('Password is required'), findsOneWidget);
});
```

---

## 🚀 Deployment & DevOps

### CI/CD Pipeline (GitHub Actions)
```yaml
name: Flutter CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Analyze code
        run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Build iOS
        run: flutter build ios --release --no-codesign
```

### Environment Configuration
```dart
// Environment configuration
class Environment {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String razorpayKey = String.fromEnvironment('RAZORPAY_KEY');
  static const String agoraAppId = String.fromEnvironment('AGORA_APP_ID');
  
  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
}
```

---

## 📱 Performance Optimization

### Image Loading & Caching
```dart
class ImageManager {
  static Widget networkImage(String url, {double? width, double? height}) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }
}
```

### Database Query Optimization
```sql
-- Optimized queries for dashboard data
CREATE OR REPLACE FUNCTION get_student_dashboard_data(student_uuid UUID)
RETURNS JSON AS $
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'upcoming_sessions', (
      SELECT json_agg(
        json_build_object(
          'id', cs.id,
          'title', cs.title,
          'scheduled_start', cs.scheduled_start,
          'teacher_name', u.first_name || ' ' || u.last_name
        )
      )
      FROM class_sessions cs
      JOIN classrooms c ON cs.classroom_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      JOIN users u ON t.user_id = u.id
      JOIN student_classroom_assignments sca ON c.id = sca.classroom_id
      WHERE sca.student_id = student_uuid
        AND cs.scheduled_start > NOW()
        AND cs.session_status = 'scheduled'
      ORDER BY cs.scheduled_start
      LIMIT 5
    ),
    'recent_progress', (
      SELECT json_build_object(
        'total_hours', COALESCE(SUM(sp.total_hours), 0),
        'classes_attended', COALESCE(SUM(sp.classes_attended), 0),
        'average_score', COALESCE(AVG(sp.average_score), 0)
      )
      FROM student_progress sp
      WHERE sp.student_id = student_uuid
        AND sp.week_start_date >= CURRENT_DATE - INTERVAL '30 days'
    )
  ) INTO result;
  
  RETURN result;
END;
$ LANGUAGE plpgsql;
```

---

## 🔐 Security Checklist

### Client-Side Security
- [ ] Input validation on all forms
- [ ] Secure storage of tokens using flutter_secure_storage
- [ ] Certificate pinning for API calls
- [ ] Obfuscation of sensitive code
- [ ] Root/jailbreak detection
- [ ] Screen recording prevention during sessions

### Server-Side Security
- [ ] Row Level Security policies implemented
- [ ] API rate limiting configured
- [ ] Input sanitization on all endpoints
- [ ] SQL injection prevention
- [ ] File upload security (type, size, scanning)
- [ ] CORS configuration
- [ ] SSL/TLS enforcement

### Data Protection
- [ ] Encryption at rest for sensitive data
- [ ] Secure backup procedures
- [ ] GDPR compliance implementation
- [ ] Data retention policies
- [ ] Right to deletion implementation
- [ ] Audit logging for sensitive operations

---

## 📞 Integration Specifications

### Video Conferencing Integration
```dart
class VideoCallService {
  static Future<void> initializeAgora() async {
    await RtcEngine.createWithContext(RtcEngineContext(agoraAppId));
  }
  
  static Future<String> generateToken(String channelName, String uid) async {
    // Server call to generate Agora token
    final response = await ApiService.post('/api/agora/token', {
      'channelName': channelName,
      'uid': uid,
    });
    return response.data['token'];
  }
}

// Alternative: Zoom SDK Integration
class ZoomService {
  static Future<void> joinMeeting(String meetingId, String password) async {
    var meetingOptions = ZoomMeetingOptions(
      meetingId: meetingId,
      meetingPassword: password,
      disableDialIn: false,
      disableDrive: true,
      disableInvite: true,
      disableShare: false,
      noAudio: false,
      noVideo: false,
    );
    
    await ZoomPlatform.instance.joinMeeting(meetingOptions);
  }
}
```

### Payment Gateway Integration
```dart
class PaymentService {
  static Future<PaymentResult> processPayment({
    required double amount,
    required String studentId,
    required String description,
  }) async {
    try {
      // Create order on server
      final orderResponse = await ApiService.post('/api/payments/create-order', {
        'amount': amount * 100, // Convert to paise
        'student_id': studentId,
        'description': description,
      });
      
      // Initialize Razorpay
      final razorpay = Razorpay();
      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      
      var options = {
        'key': Environment.razorpayKey,
        'amount': orderResponse.data['amount'],
        'order_id': orderResponse.data['order_id'],
        'name': 'E-Learning Platform',
        'description': description,
        'timeout': 300, // 5 minutes
      };
      
      razorpay.open(options);
    } catch (e) {
      return PaymentResult.failure(e.toString());
    }
  }
}
```

---

## 📋 Final Implementation Notes

### Development Best Practices
1. **Code Organization**: Follow clean architecture principles
2. **Error Handling**: Implement comprehensive error handling with user-friendly messages
3. **Logging**: Add detailed logging for debugging and monitoring
4. **Documentation**: Document all major functions and API endpoints
5. **Code Review**: Implement mandatory code reviews before merging
6. **Version Control**: Use semantic versioning and maintain changelog

### Deployment Considerations
1. **Environment Separation**: Maintain separate environments for dev, staging, and production
2. **Database Migrations**: Use version-controlled database migrations
3. **Feature Flags**: Implement feature toggles for gradual rollouts
4. **Monitoring**: Set up comprehensive application monitoring
5. **Backup Strategy**: Implement automated backups with recovery testing
6. **Scalability Planning**: Design for horizontal scaling from the beginning

### Success Metrics
- **Technical KPIs**: App crash rate < 0.1%, API response time < 200ms, 99.9% uptime
- **Business KPIs**: User retention > 80%, Session completion > 90%, Payment success > 95%
- **User Experience**: App store rating > 4.5, Support ticket volume < 5% of users

This comprehensive specification provides everything needed to build a robust, scalable e-learning platform. Each section can be expanded based on specific requirements and feedback during development.