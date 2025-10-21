-- Check the actual definition of RLS policies

-- Check assignments policies definition
SELECT 
    schemaname,
    tablename,
    policyname,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'assignments'
AND policyname LIKE 'Teachers%';

-- Check class_sessions policies definition  
SELECT 
    schemaname,
    tablename,
    policyname,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'class_sessions'
AND policyname LIKE 'Teachers%';
