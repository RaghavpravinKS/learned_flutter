-- Step 1: Add classroom_id column without foreign key constraint first
ALTER TABLE public.payments ADD COLUMN classroom_id UUID;

-- Verify it was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'payments' 
AND column_name = 'classroom_id' 
AND table_schema = 'public';
