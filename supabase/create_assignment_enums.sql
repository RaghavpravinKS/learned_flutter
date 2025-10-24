-- =============================================
-- ADD ASSIGNMENT ENUM TYPES
-- =============================================

-- Create assignment_type enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE assignment_type AS ENUM ('quiz', 'test', 'assignment', 'project');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create question_type enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE question_type AS ENUM ('multiple_choice', 'true_false', 'short_answer', 'essay');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create assignment_status enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE assignment_status AS ENUM ('draft', 'active', 'completed', 'archived');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =============================================
-- VERIFY ENUMS WERE CREATED
-- =============================================

-- List all assignment-related enum types
SELECT 
    t.typname as enum_name,
    string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) as values
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname = 'public'
    AND t.typname IN ('assignment_type', 'question_type', 'assignment_status')
GROUP BY t.typname
ORDER BY t.typname;

SELECT '✅ Assignment enum types created successfully!' as status;
