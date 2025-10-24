import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment_model.dart';

class AssignmentRepository {
  final SupabaseClient _supabaseClient;

  AssignmentRepository({required SupabaseClient supabaseClient}) : _supabaseClient = supabaseClient;

  Future<List<Assignment>> getUpcomingAssignments(String studentId) async {
    print('=== LOADING STUDENT ASSIGNMENTS ===');
    print('Student ID (user_id): $studentId');

    try {
      // First, get the student record to access student_id (not user_id)
      print('Step 1: Getting student record from students table...');
      final studentRecord = await _supabaseClient.from('students').select('id').eq('user_id', studentId).single();

      final studentDbId = studentRecord['id'] as String;
      print('Student DB ID: $studentDbId');

      // Get all classrooms the student is enrolled in
      print('Step 2: Getting enrolled classrooms...');
      final enrollments = await _supabaseClient
          .from('student_enrollments')
          .select('classroom_id')
          .eq('student_id', studentDbId)
          .eq('status', 'active');

      print('Found ${(enrollments as List).length} enrollments');

      if (enrollments.isEmpty) {
        print('No active enrollments found');
        return [];
      }

      // Extract classroom IDs
      final classroomIds = enrollments.map((e) => e['classroom_id'] as String).toList();
      print('Classroom IDs: $classroomIds');

      // Get all assignments for these classrooms with classroom and teacher info
      print('Step 3: Getting assignments for enrolled classrooms...');
      final response = await _supabaseClient
          .from('assignments')
          .select('''
            *,
            classrooms!inner(
              name,
              teachers!inner(
                users!inner(
                  first_name,
                  last_name
                )
              )
            )
          ''')
          .inFilter('classroom_id', classroomIds)
          .eq('is_published', true)
          .order('due_date', ascending: true, nullsFirst: false);

      print('Raw response: $response');
      print('Response type: ${response.runtimeType}');
      print('Number of assignments: ${(response as List).length}');

      // Get all submissions for this student
      print('Step 4: Checking for student submissions...');
      final submissions = await _supabaseClient
          .from('student_assignment_attempts')
          .select('assignment_id, submitted_at, is_graded, answers')
          .eq('student_id', studentDbId);

      print('Found ${(submissions as List).length} submissions');

      // Create a map of assignment_id -> submission data for quick lookup
      final submissionMap = <String, Map<String, dynamic>>{};
      for (final submission in submissions) {
        submissionMap[submission['assignment_id'] as String] = submission;
      }

      // Map to Assignment model with actual submission status and enriched data
      final assignments = response.map((json) {
        print('Processing assignment JSON: $json');

        // Extract classroom and teacher info
        final classroom = json['classrooms'] as Map<String, dynamic>?;
        final teacher = classroom?['teachers'] as Map<String, dynamic>?;
        final teacherUser = teacher?['users'] as Map<String, dynamic>?;

        final classroomName = classroom?['name'] as String?;
        final teacherFirstName = teacherUser?['first_name'] as String?;
        final teacherLastName = teacherUser?['last_name'] as String?;
        final teacherName = (teacherFirstName != null && teacherLastName != null)
            ? '$teacherFirstName $teacherLastName'
            : null;

        print('  Classroom: $classroomName, Teacher: $teacherName');

        // Check if this assignment has a submission
        final assignmentId = json['id'] as String;
        final submission = submissionMap[assignmentId];

        String status = 'pending';
        String? submittedAt;
        String? submissionUrl;

        if (submission != null) {
          // Assignment has been submitted
          final isGraded = submission['is_graded'] as bool? ?? false;
          status = isGraded ? 'graded' : 'submitted';
          submittedAt = submission['submitted_at'] as String?;

          // Try to extract file URL from answers JSONB field
          final answers = submission['answers'];
          if (answers is Map && answers['file_url'] != null) {
            submissionUrl = answers['file_url'] as String;
          }

          print('  Status: $status (submitted at: $submittedAt)');
        } else {
          print('  Status: pending (no submission found)');
        }

        // Add submission fields and enriched data
        final enrichedJson = {
          ...json,
          'classroom_name': classroomName,
          'teacher_name': teacherName,
          'status': status,
          'submitted_at': submittedAt,
          'submission_url': submissionUrl,
          'grade': null,
        };

        return Assignment.fromJson(enrichedJson);
      }).toList();

      print('Parsed ${assignments.length} assignments');
      for (var assignment in assignments) {
        print('  - ${assignment.title} for ${assignment.className} (${assignment.teacherName})');
      }
      print('=== ASSIGNMENTS LOADED SUCCESSFULLY ===');

      return assignments;
    } catch (e, stackTrace) {
      print('=== ERROR LOADING ASSIGNMENTS ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('=================================');
      rethrow;
    }
  }

  Future<Assignment> getAssignmentById(String assignmentId) async {
    print('=== LOADING ASSIGNMENT BY ID: $assignmentId ===');

    // Get current user and student ID
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final studentRecord = await _supabaseClient.from('students').select('id').eq('user_id', userId).single();

    final studentDbId = studentRecord['id'] as String;

    final response = await _supabaseClient
        .from('assignments')
        .select('''
          *,
          classrooms!inner(
            name,
            teachers!inner(
              users!inner(
                first_name,
                last_name
              )
            )
          )
        ''')
        .eq('id', assignmentId)
        .single();

    print('Assignment loaded: ${response['title']}');

    // Extract classroom and teacher info
    final classroom = response['classrooms'] as Map<String, dynamic>?;
    final teacher = classroom?['teachers'] as Map<String, dynamic>?;
    final teacherUser = teacher?['users'] as Map<String, dynamic>?;

    final classroomName = classroom?['name'] as String?;
    final teacherFirstName = teacherUser?['first_name'] as String?;
    final teacherLastName = teacherUser?['last_name'] as String?;
    final teacherName = (teacherFirstName != null && teacherLastName != null)
        ? '$teacherFirstName $teacherLastName'
        : null;

    print('Classroom: $classroomName, Teacher: $teacherName');

    // Check if this assignment has a submission
    print('Checking for student submission...');
    final submissions = await _supabaseClient
        .from('student_assignment_attempts')
        .select('submitted_at, is_graded, answers')
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentDbId);

    String status = 'pending';
    String? submittedAt;
    String? submissionUrl;

    if (submissions.isNotEmpty) {
      final submission = submissions.first;
      final isGraded = submission['is_graded'] as bool? ?? false;
      status = isGraded ? 'graded' : 'submitted';
      submittedAt = submission['submitted_at'] as String?;

      // Try to extract file URL from answers JSONB field
      final answers = submission['answers'];
      if (answers is Map && answers['file_url'] != null) {
        submissionUrl = answers['file_url'] as String;
      }

      print('Submission found: status=$status, submitted_at=$submittedAt');
    } else {
      print('No submission found for this assignment');
    }

    // Enrich with classroom and teacher data
    final enrichedJson = {
      ...response,
      'classroom_name': classroomName,
      'teacher_name': teacherName,
      'status': status,
      'submitted_at': submittedAt,
      'submission_url': submissionUrl,
      'grade': null,
    };

    return Assignment.fromJson(enrichedJson);
  }

  Future<void> submitAssignment({required String assignmentId, required String submissionUrl}) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabaseClient.from('assignment_submissions').upsert({
      'assignment_id': assignmentId,
      'student_id': userId,
      'submission_url': submissionUrl,
      'submitted_at': DateTime.now().toIso8601String(),
      'status': 'submitted',
    });
  }
}
