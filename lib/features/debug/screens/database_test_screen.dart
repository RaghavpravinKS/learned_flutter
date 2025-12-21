import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseTestScreen extends ConsumerStatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  ConsumerState<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends ConsumerState<DatabaseTestScreen> {
  bool _isLoading = false;
  String _result = '';

  final supabase = Supabase.instance.client;

  Future<void> _runTest(String title, Future<String> Function() testFn) async {
    setState(() {
      _isLoading = true;
      _result = '🚀 Running Test: $title...';
    });
    try {
      final testResult = await testFn();
      setState(() {
        _result = '✅ Test Successful: $title\n\n$testResult';
      });
    } catch (e, s) {
      setState(() {
        _result += '❌ Test Failed: $e\n';
        _result += 'Stack trace:\n$s';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test 1: Verify User and Student Creation
  Future<String> _verifyUserCreation() async {
    final testEmail = 'testuser_${DateTime.now().millisecondsSinceEpoch}@test.com';
    final testPassword = 'password123';
    var resultLog = StringBuffer();
    User? createdUser;

    // 1. Sign up a new user
    final response = await supabase.auth.signUp(email: testEmail, password: testPassword);
    createdUser = response.user;
    if (createdUser == null) throw Exception('SignUp failed: User is null.');
    resultLog.writeln('1. Auth user created with ID: ${createdUser.id}');

    // 2. Verify user in `users` table
    final userRecord = await supabase.from('users').select().eq('id', createdUser.id).single();
    resultLog.writeln('2. Verified user in `users` table with email: ${userRecord['email']}');

    // 3. Create a corresponding student record
    final studentRecord = await supabase
        .from('students')
        .insert({'user_id': createdUser.id, 'student_id': 'stud_${DateTime.now().millisecondsSinceEpoch}'})
        .select()
        .single();
    resultLog.writeln('3. Created student record with ID: ${studentRecord['id']}');

    return resultLog.toString();
  }

  // Test 2: Verify Payment and Enrollment Flow
  Future<String> _verifyPaymentAndEnrollment() async {
    var resultLog = StringBuffer();
    String? studentId, teacherId, classroomId;
    String? studentUserId, teacherUserId;

    // 1. Create test student and teacher
    final studentRes = await supabase.rpc('create_test_student').select().single();
    studentId = studentRes['id'] as String?;
    studentUserId = studentRes['user_id'] as String?;
    if (studentId == null || studentUserId == null) throw Exception('Failed to create test student.');
    resultLog.writeln('1. Created test student: $studentId (user: $studentUserId)');

    final teacherRes = await supabase.rpc('create_test_teacher').select().single();
    teacherId = teacherRes['id'] as String?;
    teacherUserId = teacherRes['user_id'] as String?;
    if (teacherId == null || teacherUserId == null) throw Exception('Failed to create test teacher.');
    resultLog.writeln('2. Created test teacher: $teacherId (user: $teacherUserId)');

    // 2. Create classroom
    final classroomRes = await supabase
        .from('classrooms')
        .insert({
          'teacher_id': teacherId, // teacherId is non-null here
          'name': 'Test Classroom',
          'subject': 'Math',
          'grade_level': 5,
        })
        .select()
        .single();
    classroomId = classroomRes['id'] as String?;
    if (classroomId == null) throw Exception('Failed to create classroom.');
    resultLog.writeln('3. Created test classroom: $classroomId');

    // 3. Simulate payment
    final paymentRes = await supabase
        .from('payments')
        .insert({
          'student_id': studentId, // studentId is non-null here
          'amount': 100.00,
          'payment_status': 'completed',
          'description': 'Test payment for enrollment',
        })
        .select()
        .single();
    resultLog.writeln('4. Simulated payment: ${paymentRes['id']}');

    // 4. Assign student to classroom
    final assignmentRes = await supabase
        .from('student_classroom_assignments')
        .insert({
          'student_id': studentId, // studentId is non-null here
          'classroom_id': classroomId, // classroomId is non-null here
          'teacher_id': teacherId, // teacherId is non-null here
        })
        .select()
        .single();
    resultLog.writeln('5. Assigned student to classroom: ${assignmentRes['id']}');

    // 5. Verify enrollment
    final verification = await supabase
        .from('student_classroom_assignments')
        .select('id')
        .eq('student_id', studentId)
        .eq('classroom_id', classroomId)
        .maybeSingle();

    if (verification == null) throw Exception('Verification failed: Student not found in classroom.');
    resultLog.writeln('6. ✅ VERIFIED: Student is successfully enrolled in the classroom.');

    return resultLog.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backend Flow Tests')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest('User & Student Creation', _verifyUserCreation),
              child: const Text('1. Verify User Creation'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _runTest('Payment & Enrollment', _verifyPaymentAndEnrollment),
              child: const Text('2. Verify Payment & Enrollment'),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (!_isLoading && _result.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_result, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
