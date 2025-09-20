-- Emergency fix: Create trigger_logs table and sequence immediately
-- This must be run BEFORE any user registration attempts

-- Drop existing objects if they exist (to avoid conflicts)
DROP TABLE IF EXISTS public.trigger_logs CASCADE;
DROP SEQUENCE IF EXISTS public.trigger_logs_id_seq CASCADE;

-- Create the sequence
CREATE SEQUENCE public.trigger_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Create the trigger_logs table
CREATE TABLE public.trigger_logs (
    id integer NOT NULL DEFAULT nextval('public.trigger_logs_id_seq'::regclass),
    event_time timestamp with time zone DEFAULT now(),
    message text,
    error_message text,
    metadata jsonb,
    CONSTRAINT trigger_logs_pkey PRIMARY KEY (id)
);

-- Set sequence ownership
ALTER SEQUENCE public.trigger_logs_id_seq OWNED BY public.trigger_logs.id;

-- Grant necessary permissions
GRANT ALL ON TABLE public.trigger_logs TO authenticated;
GRANT ALL ON TABLE public.trigger_logs TO service_role;
GRANT ALL ON SEQUENCE public.trigger_logs_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.trigger_logs_id_seq TO service_role;
