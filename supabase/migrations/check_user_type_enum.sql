-- Check if user_type enum exists and what values it has
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'user_type'
ORDER BY e.enumsortorder;

-- If the enum doesn't exist, let's create it
DO $$
BEGIN
    -- Check if the enum type exists
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type') THEN
        CREATE TYPE public.user_type AS ENUM ('student', 'teacher', 'parent', 'admin');
        RAISE NOTICE 'Created user_type enum';
    ELSE
        RAISE NOTICE 'user_type enum already exists';
    END IF;
END $$;

-- Re-check the enum values
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'user_type'
ORDER BY e.enumsortorder;
