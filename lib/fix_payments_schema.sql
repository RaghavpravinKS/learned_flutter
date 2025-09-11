-- Add missing classroom_id column to payments table
-- This should have been added by 20250906_enhanced_enrollment_system.sql migration

-- Add classroom_id column with foreign key reference
ALTER TABLE public.payments 
ADD COLUMN IF NOT EXISTS classroom_id UUID REFERENCES public.classrooms(id);

-- Also ensure status column exists (instead of payment_status)
ALTER TABLE public.payments 
ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'pending' 
CHECK (status IN ('pending', 'completed', 'failed', 'refunded', 'cancelled'));

-- If payment_status exists, rename it to status
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'payments' AND column_name = 'payment_status') THEN
        ALTER TABLE public.payments RENAME COLUMN payment_status TO status;
    END IF;
EXCEPTION
    WHEN duplicate_column THEN
        -- Column already exists, do nothing
        NULL;
END $$;

-- Verify the changes
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'payments' 
            AND column_name = 'classroom_id'
            AND table_schema = 'public'
        ) 
        THEN 'classroom_id column NOW EXISTS ✓' 
        ELSE 'classroom_id column STILL MISSING ✗' 
    END as result;
