-- Check what assignment types are allowed
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.assignments'::regclass
AND contype = 'c';

-- Check the enum type if it exists
SELECT 
    t.typname,
    e.enumlabel
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname LIKE '%assignment%'
ORDER BY e.enumsortorder;
