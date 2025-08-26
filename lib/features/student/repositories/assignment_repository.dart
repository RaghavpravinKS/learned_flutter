import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment_model.dart';

class AssignmentRepository {
  final SupabaseClient _supabaseClient;

  AssignmentRepository({required SupabaseClient supabaseClient}) 
      : _supabaseClient = supabaseClient;

  Future<List<Assignment>> getUpcomingAssignments(String studentId) async {
    final response = await _supabaseClient
        .rpc('get_student_assignments', params: {'student_id': studentId})
        .select()
        .order('due_date', ascending: true);

    return response.map((json) => Assignment.fromJson(json)).toList();
  }

  Future<Assignment> getAssignmentById(String assignmentId) async {
    final response = await _supabaseClient
        .from('assignments')
        .select()
        .eq('id', assignmentId)
        .single();
    
    return Assignment.fromJson(response);
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required String submissionUrl,
  }) async {
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
