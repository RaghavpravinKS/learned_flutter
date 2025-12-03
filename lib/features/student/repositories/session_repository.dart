import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';

class SessionRepository {
  final SupabaseClient _supabaseClient;

  SessionRepository({required SupabaseClient supabaseClient}) : _supabaseClient = supabaseClient;

  // Get upcoming classes for a student
  Future<List<SessionModel>> getUpcomingSessions(String userId) async {
    try {
      print('=== Fetching upcoming sessions for user: $userId ===');

      // Get student ID
      final studentResponse = await _supabaseClient.from('students').select('id').eq('user_id', userId).maybeSingle();

      if (studentResponse == null) {
        print('=== No student record found ===');
        return [];
      }

      final studentId = studentResponse['id'] as String;
      print('=== Student ID: $studentId ===');

      // Get enrolled classroom IDs
      final enrollmentsResponse = await _supabaseClient
          .from('student_enrollments')
          .select('classroom_id')
          .eq('student_id', studentId);

      if (enrollmentsResponse.isEmpty) {
        print('=== No enrollments found ===');
        return [];
      }

      final classroomIds = (enrollmentsResponse as List).map((item) => item['classroom_id'] as String).toList();

      print('=== Found ${classroomIds.length} enrolled classrooms ===');

      // Get current date and time
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Fetch upcoming sessions for those classrooms
      final response = await _supabaseClient
          .from('class_sessions')
          .select('*')
          .inFilter('classroom_id', classroomIds)
          .gte('session_date', today.toIso8601String().split('T')[0])
          .order('session_date', ascending: true)
          .order('start_time', ascending: true)
          .limit(10);

      print('=== Found ${response.length} upcoming sessions ===');

      // Fetch classroom and teacher details for each session
      final sessions = <SessionModel>[];
      for (final sessionData in response as List) {
        final classroomId = sessionData['classroom_id'] as String;

        // Get classroom details
        final classroomResponse = await _supabaseClient
            .from('classrooms')
            .select('name, teacher_id')
            .eq('id', classroomId)
            .single();

        final classroomName = classroomResponse['name'] as String;
        final teacherId = classroomResponse['teacher_id'] as String;

        // Get teacher details
        final teacherResponse = await _supabaseClient.from('teachers').select('user_id').eq('id', teacherId).single();

        final teacherUserId = teacherResponse['user_id'] as String;

        final userResponse = await _supabaseClient
            .from('users')
            .select('first_name, last_name')
            .eq('id', teacherUserId)
            .single();

        final firstName = userResponse['first_name'] as String?;
        final lastName = userResponse['last_name'] as String?;
        final teacherName = '${firstName ?? ''} ${lastName ?? ''}'.trim();

        // Combine session date and time to create DateTime
        final sessionDate = DateTime.parse(sessionData['session_date'] as String);
        final startTimeStr = sessionData['start_time'] as String;
        final endTimeStr = sessionData['end_time'] as String;

        // Parse time strings (format: HH:MM:SS)
        final startTimeParts = startTimeStr.split(':');
        final startTime = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
          int.parse(startTimeParts[0]),
          int.parse(startTimeParts[1]),
        );

        final endTimeParts = endTimeStr.split(':');
        final endTime = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1]),
        );

        // Check if session is live
        final isLive = now.isAfter(startTime) && now.isBefore(endTime);

        final sessionMap = {
          'id': sessionData['id'],
          'subject': sessionData['title'] ?? 'Class Session',
          'topic': sessionData['title'] ?? '',
          'teacher_name': teacherName,
          'classroom_id': classroomId,
          'classroom_name': classroomName,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'is_live': isLive,
          'meeting_url': sessionData['meeting_url'] as String?,
        };

        sessions.add(SessionModel.fromMap(sessionMap));
      }

      print('=== Successfully processed ${sessions.length} sessions ===');
      return sessions;
    } catch (e, stackTrace) {
      print('=== Error fetching upcoming sessions: $e ===');
      print('=== Stack trace: $stackTrace ===');
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
