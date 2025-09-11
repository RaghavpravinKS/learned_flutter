-- This migration ensures we have the necessary data for testing enrollment
-- Note: The required tables (payments, student_classroom_assignments) already exist in the schema

-- Insert a mock student record for testing if it doesn't exist
INSERT INTO students (id, student_id, grade_level, school_name, status) VALUES
('a1b2c3d4-e5f6-7890-1234-567890abcdef', 'MOCK_STUDENT_001', 10, 'Test School', 'active')
ON CONFLICT (id) DO NOTHING;

-- Insert a mock user for the student if it doesn't exist
INSERT INTO users (id, email, password_hash, user_type, first_name, last_name, is_active) VALUES
('a1b2c3d4-e5f6-7890-1234-567890abcdef', 'test.student@example.com', 'mock_hash', 'student', 'Test', 'Student', true)
ON CONFLICT (id) DO NOTHING;

-- Update the student record to link to the user
UPDATE students 
SET user_id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef' 
WHERE id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef' AND user_id IS NULL;

-- Clean up any existing test data to avoid conflicts
DELETE FROM student_classroom_assignments WHERE student_id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';
DELETE FROM payments WHERE student_id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';
