-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.assignment_questions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  assignment_id uuid,
  question_text text NOT NULL,
  question_type character varying NOT NULL CHECK (question_type::text = ANY (ARRAY['multiple_choice'::character varying, 'true_false'::character varying, 'short_answer'::character varying, 'essay'::character varying]::text[])),
  options jsonb,
  correct_answer text,
  points integer NOT NULL,
  order_index integer NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT assignment_questions_pkey PRIMARY KEY (id),
  CONSTRAINT assignment_questions_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id)
);
CREATE TABLE public.assignments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id uuid,
  teacher_id uuid,
  title character varying NOT NULL,
  description text,
  assignment_type character varying NOT NULL CHECK (assignment_type::text = ANY (ARRAY['quiz'::character varying, 'test'::character varying, 'assignment'::character varying, 'project'::character varying]::text[])),
  total_points integer NOT NULL,
  time_limit_minutes integer,
  due_date timestamp with time zone,
  is_published boolean DEFAULT false,
  instructions text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT assignments_pkey PRIMARY KEY (id),
  CONSTRAINT assignments_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id),
  CONSTRAINT assignments_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id)
);
CREATE TABLE public.class_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id uuid,
  teacher_id uuid,
  title character varying NOT NULL,
  description text,
  scheduled_start timestamp with time zone NOT NULL,
  scheduled_end timestamp with time zone NOT NULL,
  actual_start timestamp with time zone,
  actual_end timestamp with time zone,
  session_status character varying DEFAULT 'scheduled'::character varying CHECK (session_status::text = ANY (ARRAY['scheduled'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'no_show'::character varying]::text[])),
  meeting_url text,
  recording_url text,
  notes text,
  homework_assigned text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT class_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT class_sessions_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id),
  CONSTRAINT class_sessions_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id)
);
CREATE TABLE public.classroom_pricing (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id uuid,
  payment_plan_id uuid,
  price numeric NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT classroom_pricing_pkey PRIMARY KEY (id),
  CONSTRAINT classroom_pricing_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT classroom_pricing_payment_plan_id_fkey FOREIGN KEY (payment_plan_id) REFERENCES public.payment_plans(id)
);
CREATE TABLE public.classrooms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid,
  name character varying NOT NULL,
  subject character varying NOT NULL,
  board character varying,
  grade_level integer,
  description text,
  max_students integer DEFAULT 1,
  meeting_link text,
  meeting_id character varying,
  meeting_password character varying,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  next_session_date timestamp with time zone,
  CONSTRAINT classrooms_pkey PRIMARY KEY (id),
  CONSTRAINT classrooms_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id)
);
CREATE TABLE public.enrollment_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid,
  classroom_id uuid,
  request_status character varying DEFAULT 'pending'::character varying CHECK (request_status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'paid'::character varying]::text[])),
  payment_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT enrollment_requests_pkey PRIMARY KEY (id),
  CONSTRAINT enrollment_requests_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(id),
  CONSTRAINT enrollment_requests_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT enrollment_requests_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id)
);
CREATE TABLE public.learning_materials (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid,
  classroom_id uuid,
  title character varying NOT NULL,
  description text,
  material_type character varying NOT NULL CHECK (material_type::text = ANY (ARRAY['note'::character varying, 'video'::character varying, 'document'::character varying, 'presentation'::character varying, 'assignment'::character varying, 'recording'::character varying]::text[])),
  file_url text,
  file_size bigint,
  mime_type character varying,
  is_public boolean DEFAULT false,
  tags ARRAY,
  upload_date timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT learning_materials_pkey PRIMARY KEY (id),
  CONSTRAINT learning_materials_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id),
  CONSTRAINT learning_materials_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id)
);
CREATE TABLE public.parent_student_relations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  parent_id uuid,
  student_id uuid,
  relationship character varying NOT NULL,
  is_primary_contact boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT parent_student_relations_pkey PRIMARY KEY (id),
  CONSTRAINT parent_student_relations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT parent_student_relations_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.users(id)
);
CREATE TABLE public.parents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  parent_id text NOT NULL UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT parents_pkey PRIMARY KEY (id),
  CONSTRAINT parents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.payment_plans (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL,
  description text,
  price_per_hour numeric,
  price_per_month numeric,
  price_per_session numeric,
  billing_cycle character varying CHECK (billing_cycle::text = ANY (ARRAY['hourly'::character varying, 'weekly'::character varying, 'monthly'::character varying, 'per_session'::character varying]::text[])),
  features jsonb,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT payment_plans_pkey PRIMARY KEY (id)
);
CREATE TABLE public.payments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid,
  subscription_id uuid,
  amount numeric NOT NULL,
  currency character varying DEFAULT 'USD'::character varying,
  payment_method character varying,
  payment_status character varying DEFAULT 'pending'::character varying CHECK (payment_status::text = ANY (ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'refunded'::character varying]::text[])),
  transaction_id character varying,
  payment_gateway character varying,
  payment_date timestamp with time zone DEFAULT now(),
  description text,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now(),
  classroom_id uuid,
  status character varying DEFAULT 'pending'::character varying CHECK (status::text = ANY (ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'refunded'::character varying, 'cancelled'::character varying]::text[])),
  CONSTRAINT payments_pkey PRIMARY KEY (id),
  CONSTRAINT payments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT payments_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.student_subscriptions(id),
  CONSTRAINT payments_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id)
);
CREATE TABLE public.session_attendance (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid,
  student_id uuid,
  attendance_status character varying NOT NULL CHECK (attendance_status::text = ANY (ARRAY['present'::character varying, 'absent'::character varying, 'late'::character varying, 'left_early'::character varying]::text[])),
  join_time timestamp with time zone,
  leave_time timestamp with time zone,
  duration_minutes integer,
  participation_score integer CHECK (participation_score >= 1 AND participation_score <= 10),
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT session_attendance_pkey PRIMARY KEY (id),
  CONSTRAINT session_attendance_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id),
  CONSTRAINT session_attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id)
);
CREATE TABLE public.student_assignment_attempts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  assignment_id uuid,
  student_id uuid,
  attempt_number integer DEFAULT 1,
  started_at timestamp with time zone DEFAULT now(),
  submitted_at timestamp with time zone,
  score integer,
  percentage numeric,
  time_taken_minutes integer,
  status character varying DEFAULT 'in_progress'::character varying CHECK (status::text = ANY (ARRAY['in_progress'::character varying, 'submitted'::character varying, 'graded'::character varying]::text[])),
  feedback text,
  answers jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_assignment_attempts_pkey PRIMARY KEY (id),
  CONSTRAINT student_assignment_attempts_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_assignment_attempts_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id)
);
CREATE TABLE public.student_classroom_assignments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid,
  classroom_id uuid,
  teacher_id uuid,
  assigned_by uuid,
  assigned_date date DEFAULT CURRENT_DATE,
  status character varying DEFAULT 'active'::character varying CHECK (status::text = ANY (ARRAY['active'::character varying, 'completed'::character varying, 'dropped'::character varying]::text[])),
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  enrolled_date timestamp with time zone DEFAULT now(),
  progress numeric DEFAULT 0.0,
  CONSTRAINT student_classroom_assignments_pkey PRIMARY KEY (id),
  CONSTRAINT student_classroom_assignments_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id),
  CONSTRAINT student_classroom_assignments_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT student_classroom_assignments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_classroom_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(id)
);
CREATE TABLE public.student_material_access (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid,
  material_id uuid,
  accessed_at timestamp with time zone DEFAULT now(),
  download_count integer DEFAULT 0,
  last_accessed timestamp with time zone DEFAULT now(),
  CONSTRAINT student_material_access_pkey PRIMARY KEY (id),
  CONSTRAINT student_material_access_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_material_access_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.learning_materials(id)
);
CREATE TABLE public.student_progress (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid,
  classroom_id uuid,
  week_start_date date NOT NULL,
  classes_attended integer DEFAULT 0,
  total_hours numeric DEFAULT 0,
  average_score numeric,
  assignments_completed integer DEFAULT 0,
  assignments_pending integer DEFAULT 0,
  weak_areas ARRAY,
  strong_areas ARRAY,
  teacher_feedback text,
  parent_notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_progress_pkey PRIMARY KEY (id),
  CONSTRAINT student_progress_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT student_progress_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id)
);
CREATE TABLE public.student_subscriptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid,
  payment_plan_id uuid,
  start_date date NOT NULL,
  end_date date,
  status character varying DEFAULT 'active'::character varying CHECK (status::text = ANY (ARRAY['active'::character varying, 'expired'::character varying, 'cancelled'::character varying, 'suspended'::character varying]::text[])),
  auto_renew boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_subscriptions_pkey PRIMARY KEY (id),
  CONSTRAINT student_subscriptions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_subscriptions_payment_plan_id_fkey FOREIGN KEY (payment_plan_id) REFERENCES public.payment_plans(id)
);
CREATE TABLE public.students (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE,
  student_id character varying NOT NULL UNIQUE,
  grade_level integer,
  school_name character varying,
  learning_goals text,
  board character varying,
  special_requirements text,
  enrollment_date date DEFAULT CURRENT_DATE,
  status character varying DEFAULT 'active'::character varying CHECK (status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying, 'suspended'::character varying]::text[])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT students_pkey PRIMARY KEY (id),
  CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.system_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title character varying NOT NULL,
  message text NOT NULL,
  notification_type character varying NOT NULL CHECK (notification_type::text = ANY (ARRAY['class_reminder'::character varying, 'payment_due'::character varying, 'assignment_due'::character varying, 'progress_update'::character varying, 'system_update'::character varying]::text[])),
  is_read boolean DEFAULT false,
  scheduled_for timestamp with time zone,
  sent_at timestamp with time zone,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT system_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT system_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.teacher_availability (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid,
  day_of_week integer NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  is_available boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT teacher_availability_pkey PRIMARY KEY (id),
  CONSTRAINT teacher_availability_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id)
);
CREATE TABLE public.teachers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE,
  teacher_id character varying NOT NULL UNIQUE,
  qualifications text,
  experience_years integer,
  specializations ARRAY,
  hourly_rate numeric,
  bio text,
  availability_timezone character varying,
  is_verified boolean DEFAULT false,
  rating numeric DEFAULT 0.00,
  total_reviews integer DEFAULT 0,
  hire_date date,
  status character varying DEFAULT 'active'::character varying CHECK (status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying, 'on_leave'::character varying]::text[])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT teachers_pkey PRIMARY KEY (id),
  CONSTRAINT teachers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.trigger_logs (
  id integer NOT NULL DEFAULT nextval('trigger_logs_id_seq'::regclass),
  event_time timestamp with time zone DEFAULT now(),
  message text,
  error_message text,
  metadata jsonb,
  CONSTRAINT trigger_logs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_profiles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  date_of_birth date,
  address text,
  city character varying,
  state character varying,
  country character varying,
  postal_code character varying,
  emergency_contact_name character varying,
  emergency_contact_phone character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email character varying NOT NULL UNIQUE,
  password_hash character varying NOT NULL,
  user_type USER-DEFINED NOT NULL CHECK (user_type::text = ANY (ARRAY['student'::character varying::text, 'teacher'::character varying::text, 'parent'::character varying::text, 'admin'::character varying::text])),
  first_name character varying NOT NULL,
  last_name character varying NOT NULL,
  phone character varying,
  profile_image_url text,
  is_active boolean DEFAULT true,
  email_verified boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);