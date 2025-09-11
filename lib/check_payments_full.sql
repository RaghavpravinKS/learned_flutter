-- Check all columns in payments table now
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'payments' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check specifically for classroom_id
SELECT 'classroom_id details:' as info, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'payments' 
AND column_name = 'classroom_id' 
AND table_schema = 'public';

-- Check if there are any foreign key constraints on classroom_id
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'payments' 
AND kcu.column_name = 'classroom_id';
