import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';

class SessionRepository {
  final SupabaseClient _supabaseClient;

  SessionRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Get upcoming classes for a student
  Future<List<SessionModel>> getUpcomingSessions(String userId) async {
    try {
      // First, get the list of classroom IDs the student is enrolled in.
      final enrolledClassroomsResponse = await _supabaseClient.rpc(
        'get_student_classrooms',
        params: {'p_student_id': userId},
      );

      if (enrolledClassroomsResponse == null || enrolledClassroomsResponse.isEmpty) {
        return [];
      }

      final classroomIds = (enrolledClassroomsResponse as List)
          .map((item) => item['classroom_id'] as String)
          .toList();

      // Then, fetch upcoming sessions for those classrooms.
      final response = await _supabaseClient
          .from('class_sessions')
          .select('''
            id,
            title,
            scheduled_start,
            scheduled_end,
            meeting_url,
            classrooms (id, name),
            teachers (user_id, first_name, last_name)
          ''')
          .filter('classroom_id', 'in', classroomIds)
          .gte('scheduled_start', DateTime.now().toIso8601String())
          .order('scheduled_start', ascending: true)
          .limit(10);

      return (response as List)
          .map((item) => SessionModel.fromMap(item))
          .toList();
    } catch (e) {
      print('Error fetching upcoming sessions: $e');
      rethrow;
    }
  }

  // Join a class session
  Future<void> joinSession(String sessionId, String userId) async {
    try {
      await _supabaseClient.from('session_participants').insert({
        'session_id': sessionId,
        'student_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error joining session: $e');
      rethrow;
    }
  }
}
