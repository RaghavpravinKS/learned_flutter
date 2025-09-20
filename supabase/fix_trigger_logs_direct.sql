-- Create the missing trigger_logs sequence and table
-- This should be run in your Supabase SQL editor

-- Drop existing sequence if it exists (might be corrupted)
DROP SEQUENCE IF EXISTS public.trigger_logs_id_seq CASCADE;

-- Create the sequence
CREATE SEQUENCE public.trigger_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Drop existing table if it exists
DROP TABLE IF EXISTS public.trigger_logs CASCADE;

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
