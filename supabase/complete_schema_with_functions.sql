-- =============================================
-- COMPLETE SCHEMA WITH FUNCTIONS AND TRIGGERS
-- This file includes tables, functions, triggers, and policies
-- =============================================

-- First, create custom types/enums
CREATE TYPE user_type AS ENUM ('student', 'teacher', 'parent', 'admin');
CREATE TYPE teacher_status AS ENUM ('pending', 'approved', 'rejected', 'suspended');
CREATE TYPE enrollment_status AS ENUM ('pending', 'active', 'completed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE session_status AS ENUM ('scheduled', 'in_progress', 'completed', 'cancelled');

-- Create sequence for trigger logs
CREATE SEQUENCE trigger_logs_id_seq;

-- =============================================
-- TABLES
-- =============================================

-- Users table (base for all user types)
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

-- Students table
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

-- Teachers table
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

-- Payment plans table
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

-- Classrooms table
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

-- Classroom pricing table
CREATE TABLE public.classroom_pricing (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id character varying NOT NULL,
  payment_plan_id character varying NOT NULL,
  price numeric NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT classroom_pricing_pkey PRIMARY KEY (id),
  CONSTRAINT classroom_pricing_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id) ON DELETE CASCADE,
  CONSTRAINT classroom_pricing_payment_plan_id_fkey FOREIGN KEY (payment_plan_id) REFERENCES public.payment_plans(id)
);

-- Student enrollments table
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
  CONSTRAINT student_enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE,
  CONSTRAINT student_enrollments_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT student_enrollments_payment_plan_id_fkey FOREIGN KEY (payment_plan_id) REFERENCES public.payment_plans(id),
  CONSTRAINT unique_student_classroom UNIQUE (student_id, classroom_id)
);

-- Payments table
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

-- Class sessions table
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

-- Admin activities table
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

-- Teacher documents table
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

-- Teacher verification table
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

-- Trigger logs table
CREATE TABLE public.trigger_logs (
  id integer NOT NULL DEFAULT nextval('trigger_logs_id_seq'::regclass),
  event_time timestamp with time zone DEFAULT now(),
  message text,
  error_message text,
  metadata jsonb,
  CONSTRAINT trigger_logs_pkey PRIMARY KEY (id)
);

-- Audit logs table (comprehensive system activity tracking)
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

-- Create index for common audit log queries
CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_action_type ON public.audit_logs(action_type);
CREATE INDEX idx_audit_logs_table_name ON public.audit_logs(table_name);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs(created_at);
CREATE INDEX idx_audit_logs_severity ON public.audit_logs(severity);

-- Parent student relations table
CREATE TABLE public.parents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  parent_id text NOT NULL UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT parents_pkey PRIMARY KEY (id),
  CONSTRAINT parents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- Parent student relations table
CREATE TABLE public.parent_student_relations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  parent_id uuid NOT NULL,
  student_id uuid NOT NULL,
  relationship character varying NOT NULL,
  is_primary_contact boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT parent_student_relations_pkey PRIMARY KEY (id),
  CONSTRAINT parent_student_relations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT parent_student_relations_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parents(id)
);

-- Assignments table
CREATE TABLE public.assignments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  classroom_id character varying NOT NULL,
  teacher_id uuid NOT NULL,
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

-- Assignment questions table
CREATE TABLE public.assignment_questions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  assignment_id uuid NOT NULL,
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

-- Learning materials table
CREATE TABLE public.learning_materials (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  classroom_id character varying NOT NULL,
  title character varying NOT NULL,
  description text,
  material_type character varying NOT NULL CHECK (material_type::text = ANY (ARRAY['note'::character varying, 'video'::character varying, 'document'::character varying, 'presentation'::character varying, 'assignment'::character varying, 'recording'::character varying]::text[])),
  file_url text,
  file_size bigint,
  mime_type character varying,
  is_public boolean DEFAULT false,
  tags text[],
  upload_date timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT learning_materials_pkey PRIMARY KEY (id),
  CONSTRAINT learning_materials_classroom_id_fkey FOREIGN KEY (classroom_id) REFERENCES public.classrooms(id),
  CONSTRAINT learning_materials_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id)
);

-- Session attendance table
CREATE TABLE public.session_attendance (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  student_id uuid NOT NULL,
  attendance_status character varying DEFAULT 'absent'::character varying CHECK (attendance_status::text = ANY (ARRAY['present'::character varying, 'absent'::character varying, 'late'::character varying, 'excused'::character varying]::text[])),
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

-- Student assignment attempts table
CREATE TABLE public.student_assignment_attempts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  assignment_id uuid NOT NULL,
  student_id uuid NOT NULL,
  attempt_number integer DEFAULT 1,
  started_at timestamp with time zone DEFAULT now(),
  submitted_at timestamp with time zone,
  score numeric,
  max_score numeric,
  percentage numeric,
  time_taken interval,
  answers jsonb,
  feedback text,
  is_graded boolean DEFAULT false,
  graded_by uuid,
  graded_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT student_assignment_attempts_pkey PRIMARY KEY (id),
  CONSTRAINT student_assignment_attempts_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id),
  CONSTRAINT student_assignment_attempts_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id),
  CONSTRAINT student_assignment_attempts_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES public.teachers(id)
);

-- Student progress table
CREATE TABLE public.student_progress (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL,
  classroom_id character varying NOT NULL,
  assignment_id uuid,
  progress_type character varying NOT NULL CHECK (progress_type::text = ANY (ARRAY['assignment'::character varying, 'quiz'::character varying, 'test'::character varying, 'overall'::character varying]::text[])),
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

-- System notifications table
CREATE TABLE public.system_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  notification_type character varying NOT NULL CHECK (notification_type::text = ANY (ARRAY['system'::character varying, 'payment'::character varying, 'class'::character varying, 'assignment'::character varying, 'grade'::character varying]::text[])),
  title character varying NOT NULL,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  priority character varying DEFAULT 'normal'::character varying CHECK (priority::text = ANY (ARRAY['low'::character varying, 'normal'::character varying, 'high'::character varying, 'urgent'::character varying]::text[])),
  action_url text,
  expires_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  read_at timestamp with time zone,
  CONSTRAINT system_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT system_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function: Handle new user signup (creates student/teacher records)
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER AS $$
DECLARE
    user_type_val text;
    student_id_val text;
    teacher_id_val text;
BEGIN
    -- Log the trigger execution
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES ('handle_new_user_signup triggered', jsonb_build_object('user_id', NEW.id, 'email', NEW.email));

    -- Get user type from raw_user_meta_data
    user_type_val := COALESCE(NEW.raw_user_meta_data->>'user_type', 'student');
    
    -- Block teacher registration for security
    IF user_type_val = 'teacher' THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES ('Teacher registration blocked', 'Teachers must be created by admin', jsonb_build_object('user_id', NEW.id, 'email', NEW.email));
        
        RAISE EXCEPTION 'Teacher registration is not allowed. Teachers must be created by an administrator.';
    END IF;

    -- Update users table with proper user_type
    UPDATE auth.users 
    SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('user_type', user_type_val)
    WHERE id = NEW.id;

    -- Insert into public.users table
    INSERT INTO public.users (
        id, email, user_type, first_name, last_name, 
        email_confirmed_at, created_at, updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        user_type_val::public.user_type,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'Unknown'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
        NEW.email_confirmed_at,
        NEW.created_at,
        NEW.updated_at
    );

    -- Create student record if user_type is student
    IF user_type_val = 'student' THEN
        student_id_val := 'STU' || to_char(now(), 'YYYYMMDD') || substr(NEW.id::text, 1, 6);
        
        INSERT INTO public.students (
            user_id, 
            student_id, 
            grade_level,
            board,
            status,
            created_at, 
            updated_at
        ) VALUES (
            NEW.id, 
            student_id_val, 
            (NEW.raw_user_meta_data->>'grade_level')::integer,
            NEW.raw_user_meta_data->>'board',
            'active',
            now(), 
            now()
        );
        
        INSERT INTO public.trigger_logs (message, metadata)
        VALUES ('Student record created', jsonb_build_object('user_id', NEW.id, 'student_id', student_id_val));
    END IF;

    -- Log successful completion
    INSERT INTO public.trigger_logs (message, metadata)
    VALUES ('User signup completed successfully', jsonb_build_object('user_id', NEW.id, 'user_type', user_type_val));

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO public.trigger_logs (message, error_message, metadata)
        VALUES ('Error in handle_new_user_signup', SQLERRM, jsonb_build_object('user_id', NEW.id, 'email', NEW.email));
        RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Enroll student with payment
CREATE OR REPLACE FUNCTION enroll_student_with_payment(
    p_student_id uuid,
    p_classroom_id text,
    p_payment_plan_id text,
    p_amount_paid numeric
)
RETURNS jsonb AS $$
DECLARE
    v_enrollment_id uuid;
    v_payment_id uuid;
    v_student_record students%ROWTYPE;
    v_classroom_record classrooms%ROWTYPE;
    v_payment_plan_record payment_plans%ROWTYPE;
    v_start_date timestamp with time zone;
    v_end_date timestamp with time zone;
    v_next_billing_date timestamp with time zone;
    v_step text;
BEGIN
    v_step := 'initialization';
    
    -- Log function start
    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Starting enrollment process',
        jsonb_build_object(
            'function_name', 'enroll_student_with_payment',
            'step', 'initialization',
            'parameters', jsonb_build_object(
                'p_student_id', p_student_id,
                'p_classroom_id', p_classroom_id,
                'p_payment_plan_id', p_payment_plan_id,
                'p_amount_paid', p_amount_paid
            ),
            'user_id', auth.uid()
        )
    );

    v_step := 'validating_student';
    -- Validate student exists
    SELECT * INTO v_student_record FROM students WHERE id = p_student_id;
    IF NOT FOUND THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Student validation failed',
            'Student not found',
            jsonb_build_object('student_id', p_student_id, 'step', v_step)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Student not found');
    END IF;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Student validation successful',
        jsonb_build_object('step', v_step, 'student_id', v_student_record.student_id)
    );

    v_step := 'validating_classroom';
    -- Validate classroom exists
    SELECT * INTO v_classroom_record FROM classrooms WHERE id = p_classroom_id;
    IF NOT FOUND THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Classroom validation failed',
            'Classroom not found',
            jsonb_build_object('classroom_id', p_classroom_id, 'step', v_step)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Classroom not found');
    END IF;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Classroom validation successful',
        jsonb_build_object('step', v_step, 'classroom_name', v_classroom_record.name)
    );

    v_step := 'validating_payment_plan';
    -- Validate payment plan exists
    SELECT * INTO v_payment_plan_record FROM payment_plans WHERE id = p_payment_plan_id;
    IF NOT FOUND THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Payment plan validation failed',
            'Payment plan not found',
            jsonb_build_object('payment_plan_id', p_payment_plan_id, 'step', v_step)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Payment plan not found');
    END IF;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Payment plan validation successful',
        jsonb_build_object('step', v_step, 'plan_name', v_payment_plan_record.name, 'billing_cycle', v_payment_plan_record.billing_cycle)
    );

    v_step := 'checking_existing_enrollment';
    -- Check if already enrolled
    IF EXISTS (SELECT 1 FROM student_enrollments WHERE student_id = p_student_id AND classroom_id = p_classroom_id) THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Duplicate enrollment check failed',
            'Student already enrolled',
            jsonb_build_object('student_id', p_student_id, 'classroom_id', p_classroom_id, 'step', v_step)
        );
        RETURN jsonb_build_object('success', false, 'error', 'Student already enrolled in this classroom');
    END IF;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Duplicate enrollment check passed',
        jsonb_build_object('step', v_step)
    );

    v_step := 'calculating_dates';
    -- Calculate subscription dates based on billing cycle
    v_start_date := now();
    CASE v_payment_plan_record.billing_cycle
        WHEN 'monthly' THEN
            v_end_date := v_start_date + INTERVAL '1 month';
            v_next_billing_date := v_start_date + INTERVAL '1 month';
        WHEN 'quarterly' THEN
            v_end_date := v_start_date + INTERVAL '3 months';
            v_next_billing_date := v_start_date + INTERVAL '3 months';
        WHEN 'yearly' THEN
            v_end_date := v_start_date + INTERVAL '1 year';
            v_next_billing_date := v_start_date + INTERVAL '1 year';
        ELSE
            -- Default to monthly if billing cycle is not recognized
            v_end_date := v_start_date + INTERVAL '1 month';
            v_next_billing_date := v_start_date + INTERVAL '1 month';
    END CASE;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Subscription dates calculated',
        jsonb_build_object(
            'step', v_step,
            'start_date', v_start_date,
            'end_date', v_end_date,
            'next_billing_date', v_next_billing_date,
            'billing_cycle', v_payment_plan_record.billing_cycle
        )
    );

    v_step := 'creating_payment';
    -- Create payment record
    INSERT INTO payments (
        student_id, classroom_id, payment_plan_id, amount, 
        payment_method, status, created_at, updated_at
    ) VALUES (
        p_student_id, p_classroom_id, p_payment_plan_id, p_amount_paid,
        'simulation', 'completed', now(), now()
    ) RETURNING id INTO v_payment_id;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Payment record created successfully',
        jsonb_build_object('step', v_step, 'payment_id', v_payment_id, 'amount', p_amount_paid)
    );

    v_step := 'creating_enrollment';
    -- Create enrollment record with subscription dates
    INSERT INTO student_enrollments (
        student_id, classroom_id, payment_plan_id, status,
        enrollment_date, start_date, end_date, next_billing_date,
        auto_renew, created_at, updated_at
    ) VALUES (
        p_student_id, p_classroom_id, p_payment_plan_id, 'active',
        now(), v_start_date, v_end_date, v_next_billing_date,
        true, now(), now()
    ) RETURNING id INTO v_enrollment_id;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Student enrollment record created successfully',
        jsonb_build_object('step', v_step, 'enrollment_id', v_enrollment_id)
    );

    v_step := 'updating_classroom_count';
    -- Update classroom student count
    UPDATE classrooms 
    SET current_students = current_students + 1,
        updated_at = now()
    WHERE id = p_classroom_id;

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Classroom student count updated',
        jsonb_build_object('step', v_step, 'classroom_id', p_classroom_id)
    );

    v_step := 'logging_audit_event';
    -- Log audit event for enrollment
    PERFORM log_audit_event(
        p_user_id := (SELECT user_id FROM students WHERE id = p_student_id),
        p_action_type := 'student_enrollment_created',
        p_table_name := 'student_enrollments',
        p_record_id := v_enrollment_id,
        p_new_values := jsonb_build_object(
            'student_id', p_student_id,
            'classroom_id', p_classroom_id,
            'payment_plan_id', p_payment_plan_id,
            'amount_paid', p_amount_paid,
            'end_date', v_end_date
        ),
        p_description := 'Student enrolled in classroom: ' || v_classroom_record.name,
        p_severity := 'info',
        p_tags := ARRAY['enrollment', 'payment', 'student'],
        p_metadata := jsonb_build_object(
            'payment_id', v_payment_id,
            'billing_cycle', v_payment_plan_record.billing_cycle,
            'classroom_name', v_classroom_record.name
        )
    );

    INSERT INTO trigger_logs (message, metadata)
    VALUES (
        'Enrollment function completed successfully',
        jsonb_build_object(
            'step', 'function_success',
            'enrollment_id', v_enrollment_id,
            'payment_id', v_payment_id,
            'success', true
        )
    );

    RETURN jsonb_build_object(
        'success', true,
        'enrollment_id', v_enrollment_id,
        'payment_id', v_payment_id,
        'start_date', v_start_date,
        'end_date', v_end_date,
        'next_billing_date', v_next_billing_date,
        'billing_cycle', v_payment_plan_record.billing_cycle,
        'message', 'Student enrolled successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES (
            'Enrollment function failed with exception',
            SQLERRM,
            jsonb_build_object(
                'error_state', SQLSTATE,
                'current_step', v_step,
                'parameters', jsonb_build_object(
                    'p_student_id', p_student_id,
                    'p_classroom_id', p_classroom_id,
                    'p_payment_plan_id', p_payment_plan_id,
                    'p_amount_paid', p_amount_paid
                )
            )
        );
        RETURN jsonb_build_object('success', false, 'error', SQLERRM, 'step', v_step);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get student classrooms
CREATE OR REPLACE FUNCTION get_student_classrooms(p_student_id uuid)
RETURNS TABLE (
    classroom_id text,
    classroom_name text,
    subject text,
    grade_level integer,
    teacher_name text,
    enrollment_status text,
    enrollment_date timestamp with time zone,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    next_billing_date timestamp with time zone,
    auto_renew boolean,
    progress numeric,
    price numeric,
    billing_cycle text,
    is_expired boolean
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as classroom_id,
        c.name as classroom_name,
        c.subject,
        c.grade_level,
        COALESCE(t.first_name || ' ' || t.last_name, 'No Teacher Assigned') as teacher_name,
        se.status::text as enrollment_status,
        se.enrollment_date,
        se.start_date,
        se.end_date,
        se.next_billing_date,
        se.auto_renew,
        se.progress,
        cp.price,
        pp.billing_cycle,
        CASE WHEN se.end_date < now() THEN true ELSE false END as is_expired
    FROM student_enrollments se
    JOIN classrooms c ON se.classroom_id = c.id
    LEFT JOIN teachers t ON c.teacher_id = t.id
    LEFT JOIN users tu ON t.user_id = tu.id
    JOIN classroom_pricing cp ON c.id = cp.classroom_id AND se.payment_plan_id = cp.payment_plan_id
    JOIN payment_plans pp ON se.payment_plan_id = pp.id
    WHERE se.student_id = p_student_id
    ORDER BY se.enrollment_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Create teacher by admin
CREATE OR REPLACE FUNCTION create_teacher_by_admin(
    p_admin_id uuid,
    p_email text,
    p_first_name text,
    p_last_name text,
    p_phone text,
    p_qualifications text,
    p_bio text,
    p_experience_years integer,
    p_specializations text,
    p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb AS $$
DECLARE
    v_user_id uuid;
    v_teacher_id uuid;
    v_teacher_id_val text;
BEGIN
    -- Validate admin user
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Admin access required');
    END IF;

    -- Generate teacher ID
    v_teacher_id_val := 'TEA' || to_char(now(), 'YYYYMMDD') || substr(gen_random_uuid()::text, 1, 6);

    -- Create user record
    INSERT INTO users (
        email, user_type, first_name, last_name, phone,
        is_active, email_verified, created_at, updated_at
    ) VALUES (
        p_email, 'teacher', p_first_name, p_last_name, p_phone,
        true, true, now(), now()
    ) RETURNING id INTO v_user_id;

    -- Create teacher record
    INSERT INTO teachers (
        user_id, teacher_id, qualifications, experience_years,
        bio, status, created_at, updated_at
    ) VALUES (
        v_user_id, v_teacher_id_val, p_qualifications, p_experience_years,
        p_bio, 'active', now(), now()
    ) RETURNING id INTO v_teacher_id;

    -- Log admin activity
    INSERT INTO admin_activities (
        admin_id, activity_type, target_user_id, description, metadata, created_at
    ) VALUES (
        p_admin_id, 'create_teacher', v_user_id, 
        'Created teacher account: ' || p_first_name || ' ' || p_last_name,
        p_metadata, now()
    );

    RETURN jsonb_build_object(
        'success', true,
        'user_id', v_user_id,
        'teacher_id', v_teacher_id,
        'teacher_id_val', v_teacher_id_val,
        'message', 'Teacher account created successfully'
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Update expired enrollments
CREATE OR REPLACE FUNCTION update_expired_enrollments()
RETURNS jsonb AS $$
DECLARE
    v_updated_count integer := 0;
BEGIN
    -- Update enrollments that have passed their end_date to 'cancelled' status
    UPDATE student_enrollments 
    SET status = 'cancelled',
        updated_at = now()
    WHERE end_date < now() 
      AND status = 'active';
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    -- Log the operation
    INSERT INTO trigger_logs (message, metadata)
    VALUES ('Expired enrollments updated', jsonb_build_object('updated_count', v_updated_count));
    
    RETURN jsonb_build_object(
        'success', true,
        'updated_count', v_updated_count,
        'message', 'Expired enrollments updated successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO trigger_logs (message, error_message)
        VALUES ('Error updating expired enrollments', SQLERRM);
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Renew student enrollment
CREATE OR REPLACE FUNCTION renew_student_enrollment(
    p_enrollment_id uuid,
    p_payment_id uuid
)
RETURNS jsonb AS $$
DECLARE
    v_enrollment_record student_enrollments%ROWTYPE;
    v_payment_plan_record payment_plans%ROWTYPE;
    v_new_end_date timestamp with time zone;
    v_new_next_billing_date timestamp with time zone;
BEGIN
    -- Get enrollment record
    SELECT * INTO v_enrollment_record FROM student_enrollments WHERE id = p_enrollment_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Enrollment not found');
    END IF;
    
    -- Get payment plan
    SELECT * INTO v_payment_plan_record FROM payment_plans WHERE id = v_enrollment_record.payment_plan_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Payment plan not found');
    END IF;
    
    -- Calculate new subscription dates based on current end_date or now (whichever is later)
    CASE v_payment_plan_record.billing_cycle
        WHEN 'monthly' THEN
            v_new_end_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 month';
            v_new_next_billing_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 month';
        WHEN 'quarterly' THEN
            v_new_end_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '3 months';
            v_new_next_billing_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '3 months';
        WHEN 'yearly' THEN
            v_new_end_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 year';
            v_new_next_billing_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 year';
        ELSE
            v_new_end_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 month';
            v_new_next_billing_date := GREATEST(v_enrollment_record.end_date, now()) + INTERVAL '1 month';
    END CASE;
    
    -- Update enrollment with new dates and active status
    UPDATE student_enrollments 
    SET status = 'active',
        end_date = v_new_end_date,
        next_billing_date = v_new_next_billing_date,
        updated_at = now()
    WHERE id = p_enrollment_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'enrollment_id', p_enrollment_id,
        'new_end_date', v_new_end_date,
        'new_next_billing_date', v_new_next_billing_date,
        'message', 'Enrollment renewed successfully'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Log audit event
CREATE OR REPLACE FUNCTION log_audit_event(
    p_user_id uuid DEFAULT NULL,
    p_action_type text DEFAULT NULL,
    p_table_name text DEFAULT NULL,
    p_record_id uuid DEFAULT NULL,
    p_old_values jsonb DEFAULT NULL,
    p_new_values jsonb DEFAULT NULL,
    p_description text DEFAULT NULL,
    p_ip_address inet DEFAULT NULL,
    p_user_agent text DEFAULT NULL,
    p_session_id text DEFAULT NULL,
    p_request_id text DEFAULT NULL,
    p_severity text DEFAULT 'info',
    p_tags text[] DEFAULT NULL,
    p_metadata jsonb DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
    v_audit_id uuid;
    v_user_type_val user_type;
BEGIN
    -- Get user type if user_id is provided
    IF p_user_id IS NOT NULL THEN
        SELECT user_type INTO v_user_type_val FROM users WHERE id = p_user_id;
    END IF;
    
    -- Insert audit log
    INSERT INTO audit_logs (
        user_id, user_type, action_type, table_name, record_id,
        old_values, new_values, description, ip_address, user_agent,
        session_id, request_id, severity, tags, metadata, created_at
    ) VALUES (
        p_user_id, v_user_type_val, p_action_type, p_table_name, p_record_id,
        p_old_values, p_new_values, p_description, p_ip_address, p_user_agent,
        p_session_id, p_request_id, p_severity, p_tags, p_metadata, now()
    ) RETURNING id INTO v_audit_id;
    
    RETURN v_audit_id;
    
EXCEPTION
    WHEN OTHERS THEN
        -- If audit logging fails, log to trigger_logs instead
        INSERT INTO trigger_logs (message, error_message, metadata)
        VALUES ('Audit logging failed', SQLERRM, jsonb_build_object('action_type', p_action_type, 'table_name', p_table_name));
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get user audit history
CREATE OR REPLACE FUNCTION get_user_audit_history(
    p_user_id uuid,
    p_limit integer DEFAULT 50,
    p_offset integer DEFAULT 0,
    p_action_filter text DEFAULT NULL,
    p_severity_filter text DEFAULT NULL
)
RETURNS TABLE (
    id uuid,
    action_type text,
    table_name text,
    description text,
    severity text,
    ip_address inet,
    created_at timestamp with time zone,
    metadata jsonb
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        al.id,
        al.action_type,
        al.table_name,
        al.description,
        al.severity,
        al.ip_address,
        al.created_at,
        al.metadata
    FROM audit_logs al
    WHERE al.user_id = p_user_id
      AND (p_action_filter IS NULL OR al.action_type = p_action_filter)
      AND (p_severity_filter IS NULL OR al.severity = p_severity_filter)
    ORDER BY al.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Assign teacher to classroom
CREATE OR REPLACE FUNCTION assign_teacher_to_classroom(
    p_admin_id uuid,
    p_classroom_id text,
    p_teacher_id uuid
)
RETURNS jsonb AS $$
DECLARE
    v_classroom_record classrooms%ROWTYPE;
    v_teacher_record teachers%ROWTYPE;
    v_teacher_user_record users%ROWTYPE;
    v_old_teacher_id uuid;
BEGIN
    -- Validate admin user
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_admin_id AND user_type = 'admin') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Admin access required');
    END IF;
    
    -- Validate classroom exists
    SELECT * INTO v_classroom_record FROM classrooms WHERE id = p_classroom_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Classroom not found');
    END IF;
    
    -- Store old teacher ID for audit logging
    v_old_teacher_id := v_classroom_record.teacher_id;
    
    -- If p_teacher_id is provided, validate teacher exists
    IF p_teacher_id IS NOT NULL THEN
        SELECT * INTO v_teacher_record FROM teachers WHERE id = p_teacher_id;
        IF NOT FOUND THEN
            RETURN jsonb_build_object('success', false, 'error', 'Teacher not found');
        END IF;
        
        -- Get teacher user record for name
        SELECT * INTO v_teacher_user_record FROM users WHERE id = v_teacher_record.user_id;
    END IF;
    
    -- Update classroom with new teacher
    UPDATE classrooms 
    SET teacher_id = p_teacher_id,
        updated_at = now()
    WHERE id = p_classroom_id;
    
    -- Log audit event
    PERFORM log_audit_event(
        p_user_id := p_admin_id,
        p_action_type := 'classroom_teacher_assigned',
        p_table_name := 'classrooms',
        p_record_id := v_classroom_record.id::uuid,
        p_old_values := jsonb_build_object('teacher_id', v_old_teacher_id),
        p_new_values := jsonb_build_object('teacher_id', p_teacher_id),
        p_description := CASE 
            WHEN p_teacher_id IS NULL THEN 'Teacher removed from classroom: ' || v_classroom_record.name
            ELSE 'Teacher assigned to classroom: ' || v_classroom_record.name || ' - ' || v_teacher_user_record.first_name || ' ' || v_teacher_user_record.last_name
        END,
        p_severity := 'info',
        p_tags := ARRAY['classroom', 'teacher', 'assignment', 'admin'],
        p_metadata := jsonb_build_object(
            'classroom_name', v_classroom_record.name,
            'teacher_name', CASE 
                WHEN p_teacher_id IS NOT NULL THEN v_teacher_user_record.first_name || ' ' || v_teacher_user_record.last_name
                ELSE NULL
            END,
            'previous_teacher_id', v_old_teacher_id
        )
    );
    
    -- Log admin activity
    INSERT INTO admin_activities (
        admin_id, activity_type, target_table, target_record_id, description, metadata, created_at
    ) VALUES (
        p_admin_id, 'assign_teacher_classroom', 'classrooms', v_classroom_record.id::uuid,
        CASE 
            WHEN p_teacher_id IS NULL THEN 'Removed teacher from classroom: ' || v_classroom_record.name
            ELSE 'Assigned teacher to classroom: ' || v_classroom_record.name
        END,
        jsonb_build_object(
            'classroom_id', p_classroom_id,
            'teacher_id', p_teacher_id,
            'previous_teacher_id', v_old_teacher_id
        ),
        now()
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'classroom_id', p_classroom_id,
        'teacher_id', p_teacher_id,
        'teacher_name', CASE 
            WHEN p_teacher_id IS NOT NULL THEN v_teacher_user_record.first_name || ' ' || v_teacher_user_record.last_name
            ELSE NULL
        END,
        'message', CASE 
            WHEN p_teacher_id IS NULL THEN 'Teacher removed from classroom successfully'
            ELSE 'Teacher assigned to classroom successfully'
        END
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- TRIGGERS
-- =============================================

-- Trigger: Handle new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user_signup();

-- =============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classroom_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_assignment_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Students policies
CREATE POLICY "Students can view their own record" ON public.students
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Students can update their own record" ON public.students
    FOR UPDATE USING (auth.uid() = user_id);

-- Allow public access to student existence for foreign key validation during enrollment counting
CREATE POLICY "Anyone can read student existence for enrollment counting" ON public.students
    FOR SELECT USING (status = 'active');

-- Teachers policies (public read access for teacher profile information)
CREATE POLICY "Anyone can view teacher profiles" ON public.teachers
    FOR SELECT USING (status = 'active');

-- Additional users policy for teacher profile access
CREATE POLICY "Anyone can view teacher user profiles" ON public.users
    FOR SELECT USING (user_type = 'teacher' AND is_active = true);

-- Classrooms policies (public read access for browsing)
CREATE POLICY "Anyone can view active classrooms" ON public.classrooms
    FOR SELECT USING (is_active = true);

-- Classroom pricing policies (public read access)
CREATE POLICY "Anyone can view classroom pricing" ON public.classroom_pricing
    FOR SELECT USING (true);

-- Payment plans policies (public read access)
CREATE POLICY "Anyone can view payment plans" ON public.payment_plans
    FOR SELECT USING (is_active = true);

-- Student enrollments policies
CREATE POLICY "Students can view their own enrollments" ON public.student_enrollments
    FOR SELECT USING (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

CREATE POLICY "Students can insert their own enrollments" ON public.student_enrollments
    FOR INSERT WITH CHECK (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

-- Allow public counting of active enrollments for classroom browsing
CREATE POLICY "Anyone can count active enrollments per classroom" ON public.student_enrollments
    FOR SELECT USING (status = 'active');

-- Payments policies
CREATE POLICY "Students can view their own payments" ON public.payments
    FOR SELECT USING (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

CREATE POLICY "Students can insert their own payments" ON public.payments
    FOR INSERT WITH CHECK (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

-- Class sessions policies (students can view sessions for their enrolled classrooms)
CREATE POLICY "Students can view sessions for enrolled classrooms" ON public.class_sessions
    FOR SELECT USING (
        classroom_id IN (
            SELECT classroom_id FROM student_enrollments 
            WHERE student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
        )
    );

-- Assignments policies
CREATE POLICY "Students can view assignments for enrolled classrooms" ON public.assignments
    FOR SELECT USING (
        classroom_id IN (
            SELECT classroom_id FROM student_enrollments 
            WHERE student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
        )
    );

-- Learning materials policies
CREATE POLICY "Students can view materials for enrolled classrooms" ON public.learning_materials
    FOR SELECT USING (
        is_public = true OR 
        classroom_id IN (
            SELECT classroom_id FROM student_enrollments 
            WHERE student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
        )
    );

-- Student assignment attempts policies
CREATE POLICY "Students can view their own assignment attempts" ON public.student_assignment_attempts
    FOR SELECT USING (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

CREATE POLICY "Students can insert their own assignment attempts" ON public.student_assignment_attempts
    FOR INSERT WITH CHECK (
        student_id IN (SELECT id FROM students WHERE user_id = auth.uid())
    );

-- System notifications policies
CREATE POLICY "Users can view their own notifications" ON public.system_notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON public.system_notifications
    FOR UPDATE USING (user_id = auth.uid());

-- Audit logs policies
CREATE POLICY "Users can view their own audit logs" ON public.audit_logs
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view all audit logs" ON public.audit_logs
    FOR SELECT USING (
        auth.uid() IN (SELECT id FROM users WHERE user_type = 'admin')
    );

CREATE POLICY "System can insert audit logs" ON public.audit_logs
    FOR INSERT WITH CHECK (true);

-- =============================================
-- GRANT PERMISSIONS FOR PUBLIC ACCESS
-- =============================================

-- Grant necessary table permissions for anon users (classroom browsing)
GRANT SELECT ON public.teachers TO anon;
GRANT SELECT ON public.users TO anon;
GRANT SELECT ON public.classrooms TO anon;
GRANT SELECT ON public.classroom_pricing TO anon;
GRANT SELECT ON public.payment_plans TO anon;
GRANT SELECT ON public.student_enrollments TO anon;
GRANT SELECT ON public.students TO anon;

-- Grant permissions for authenticated users  
GRANT SELECT ON public.teachers TO authenticated;
GRANT SELECT ON public.users TO authenticated;
GRANT SELECT ON public.classrooms TO authenticated;
GRANT SELECT ON public.classroom_pricing TO authenticated;
GRANT SELECT ON public.payment_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.student_enrollments TO authenticated;
GRANT SELECT, INSERT ON public.payments TO authenticated;
GRANT SELECT ON public.students TO authenticated;

-- =============================================
-- SCHEMA SETUP COMPLETE
-- =============================================

SELECT 'Complete schema with functions and triggers created successfully!' as status;
