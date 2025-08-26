-- Enable Row Level Security on all tables
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Enable necessary extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- Create user roles enum
create type user_role as enum ('student', 'parent', 'teacher', 'admin');

-- Create user profiles table (extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  full_name text not null,
  avatar_url text,
  role user_role not null,
  date_of_birth date,
  phone text,
  address text,
  city text,
  state text,
  country text,
  postal_code text,
  bio text,
  constraint username_length check (char_length(full_name) >= 2)
);

-- Create subjects table
create table public.subjects (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text not null,
  description text,
  icon text,
  is_active boolean default true
);

-- Create courses table
create table public.courses (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  description text,
  subject_id uuid references public.subjects(id) on delete set null,
  level text,
  thumbnail_url text,
  is_published boolean default false,
  price numeric(10, 2) default 0,
  duration_minutes integer
);

-- Create classes table (scheduled sessions)
create table public.classes (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  course_id uuid references public.courses(id) on delete cascade,
  teacher_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  meeting_url text,
  max_students integer,
  is_recurring boolean default false,
  recurrence_rule text,
  status text not null default 'scheduled' check (status in ('scheduled', 'in_progress', 'completed', 'cancelled'))
);

-- Create enrollments table
create table public.enrollments (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  student_id uuid references public.profiles(id) on delete cascade,
  course_id uuid references public.courses(id) on delete cascade,
  enrolled_at timestamp with time zone default timezone('utc'::text, now()) not null,
  completion_percentage integer default 0,
  is_active boolean default true,
  last_accessed_at timestamp with time zone,
  unique(student_id, course_id)
);

-- Create class_attendance table
create table public.class_attendance (
  id uuid primary key default uuid_generate_v4(),
  class_id uuid references public.classes(id) on delete cascade,
  student_id uuid references public.profiles(id) on delete cascade,
  joined_at timestamp with time zone,
  left_at timestamp with time zone,
  status text check (status in ('present', 'absent', 'late', 'excused')),
  unique(class_id, student_id)
);

-- Create assignments table
create table public.assignments (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  course_id uuid references public.courses(id) on delete cascade,
  title text not null,
  description text,
  due_date timestamp with time zone,
  max_score integer,
  is_published boolean default false
);

-- Create submissions table
create table public.submissions (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  assignment_id uuid references public.assignments(id) on delete cascade,
  student_id uuid references public.profiles(id) on delete cascade,
  submitted_at timestamp with time zone,
  content text,
  score integer,
  feedback text,
  status text check (status in ('draft', 'submitted', 'graded', 'late')),
  unique(assignment_id, student_id)
);

-- Create messages table for class discussions
create table public.messages (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  sender_id uuid references public.profiles(id) on delete cascade,
  class_id uuid references public.classes(id) on delete cascade,
  content text not null,
  parent_message_id uuid references public.messages(id) on delete cascade,
  is_edited boolean default false
);

-- Create notifications table
create table public.notifications (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  is_read boolean default false,
  action_url text,
  type text
);

-- Create payments table
create table public.payments (
  id uuid primary key default uuid_generate_v4(),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references public.profiles(id) on delete set null,
  amount numeric(10, 2) not null,
  currency text default 'USD',
  status text not null check (status in ('pending', 'completed', 'failed', 'refunded')),
  payment_method text,
  payment_intent_id text,
  invoice_url text,
  description text
);

-- Create a function to handle new user signups
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url, role)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    (new.raw_user_meta_data->>'role')::user_role
  );
  return new;
end;
$$ language plpgsql security definer;

-- Trigger the function every time a user is created
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Set up Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using (true);

create policy "Users can update their own profile."
  on profiles for update
  using (auth.uid() = id);

-- Create policies for courses
create policy "Courses are viewable by everyone."
  on courses for select
  using (true);

create policy "Enable insert for authenticated users only"
  on courses for insert
  with check (auth.role() = 'authenticated');

-- Create policies for classes
create policy "Classes are viewable by everyone."
  on classes for select
  using (true);

-- Add more specific policies as needed...

-- Create indexes for better performance
create index idx_profiles_role on public.profiles(role);
create index idx_classes_course_id on public.classes(course_id);
create index idx_enrollments_student_id on public.enrollments(student_id);
create index idx_enrollments_course_id on public.enrollments(course_id);
create index idx_attendance_class_id on public.class_attendance(class_id);
create index idx_submissions_assignment_id on public.submissions(assignment_id);
create index idx_messages_class_id on public.messages(class_id);
