-- Simple diagnostic to check what's happening with the payments table

-- 1. Check current columns in payments table
SELECT 'Current Columns:' as info, column_name, data_type
FROM information_schema.columns 
WHERE table_name = 'payments' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if classrooms table exists and has id column
SELECT 'Classrooms Table:' as info, column_name, data_type
FROM information_schema.columns 
WHERE table_name = 'classrooms' AND table_schema = 'public' AND column_name = 'id';

-- 3. Try to add classroom_id column step by step
-- First, let's see if we can add it without the foreign key constraint
SELECT 'Adding classroom_id column without constraint...' as step;
