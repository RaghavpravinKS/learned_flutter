-- Create a mock user for testing student enrollment
INSERT INTO users (id, first_name, last_name, email, role) VALUES 
('a1b2c3d4-e5f6-7890-1234-567890abcdef', 'Test', 'Student', 'test.student@example.com', 'student')
ON CONFLICT (id) DO NOTHING;

-- Create a mock student record
INSERT INTO students (id, user_id, grade_level, school_name, parent_contact) VALUES 
('a1b2c3d4-e5f6-7890-1234-567890abcdef', 'a1b2c3d4-e5f6-7890-1234-567890abcdef', 10, 'Test High School', 'parent@example.com')
ON CONFLICT (id) DO NOTHING;

-- Verify the records were created
SELECT 'User created' as status, id, first_name, last_name, email FROM users WHERE id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';
SELECT 'Student created' as status, id, user_id, grade_level FROM students WHERE id = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';
