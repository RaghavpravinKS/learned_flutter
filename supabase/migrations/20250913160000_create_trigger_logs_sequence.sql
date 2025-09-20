-- Create missing trigger_logs sequence
-- This migration fixes the "relation trigger_logs does not exist" error

-- Create the sequence for trigger_logs (if it doesn't exist)
CREATE SEQUENCE IF NOT EXISTS public.trigger_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Ensure the trigger_logs table exists with proper sequence reference
CREATE TABLE IF NOT EXISTS public.trigger_logs (
    id integer NOT NULL DEFAULT nextval('public.trigger_logs_id_seq'::regclass),
    event_time timestamp with time zone DEFAULT now(),
    message text,
    error_message text,
    metadata jsonb,
    CONSTRAINT trigger_logs_pkey PRIMARY KEY (id)
);

-- Set sequence ownership (only if both exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'trigger_logs_id_seq') AND 
       EXISTS (SELECT 1 FROM pg_class WHERE relname = 'trigger_logs') THEN
        ALTER SEQUENCE public.trigger_logs_id_seq OWNED BY public.trigger_logs.id;
    END IF;
END $$;
