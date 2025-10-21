import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/classroom_service.dart';

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  return ClassroomService();
});

// Simple provider that fetches all classrooms once
final allClassroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(classroomServiceProvider);
  return service.getAvailableClassrooms();
});

// Provider to get the next upcoming session for a classroom
final nextClassroomSessionProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((
  ref,
  classroomId,
) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();

  final response = await supabase
      .from('class_sessions')
      .select()
      .eq('classroom_id', classroomId)
      .gte('session_date', now.toIso8601String().split('T')[0])
      .order('session_date', ascending: true)
      .order('start_time', ascending: true)
      .limit(1);

  if (response.isEmpty) return null;
  return response.first;
});

// Provider to get attendance statistics for a classroom
final classroomAttendanceProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((
  ref,
  classroomId,
) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Get student record
  final studentResponse = await supabase.from('students').select('id').eq('user_id', userId).single();

  final studentId = studentResponse['id'] as String;

  // Get all sessions for this classroom
  final sessionsResponse = await supabase.from('class_sessions').select('id').eq('classroom_id', classroomId);

  final sessionIds = (sessionsResponse as List).map((s) => s['id'] as String).toList();

  if (sessionIds.isEmpty) {
    return {'totalSessions': 0, 'attended': 0, 'absent': 0, 'late': 0, 'excused': 0, 'attendanceRate': 0.0};
  }

  // Get attendance records for these sessions
  final attendanceResponse = await supabase
      .from('session_attendance')
      .select('attendance_status')
      .eq('student_id', studentId)
      .inFilter('session_id', sessionIds);

  final attendanceRecords = attendanceResponse as List;

  final present = attendanceRecords.where((a) => a['attendance_status'] == 'present').length;
  final absent = attendanceRecords.where((a) => a['attendance_status'] == 'absent').length;
  final late = attendanceRecords.where((a) => a['attendance_status'] == 'late').length;
  final excused = attendanceRecords.where((a) => a['attendance_status'] == 'excused').length;

  final totalSessions = sessionIds.length;
  final attended = present + late; // Count late as attended
  final attendanceRate = totalSessions > 0 ? (attended / totalSessions) * 100 : 0.0;

  return {
    'totalSessions': totalSessions,
    'attended': attended,
    'absent': absent,
    'late': late,
    'excused': excused,
    'attendanceRate': attendanceRate,
  };
});

// Check if student is enrolled in a specific classroom
final studentEnrollmentStatusProvider = FutureProvider.autoDispose.family<bool, String>((ref, classroomId) async {
  final service = ref.watch(classroomServiceProvider);
  final enrolledClassrooms = await service.getEnrolledClassrooms(null);
  return enrolledClassrooms.any((classroom) => classroom['id'] == classroomId);
});

// Legacy provider kept for compatibility with other parts of the app
final availableClassroomsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Map<String, dynamic>?>((ref, filters) async {
      final service = ref.watch(classroomServiceProvider);
      return service.getAvailableClassrooms(
        subject: filters?['subject'],
        board: filters?['board'],
        gradeLevel: filters?['grade_level'],
      );
    });

final classroomDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((
  ref,
  classroomId,
) async {
  final service = ref.watch(classroomServiceProvider);
  return service.getClassroomById(classroomId);
});

final studentEnrollmentsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((
  ref,
  studentId,
) async {
  // This would normally fetch the student's enrollments
  return {'enrollments': [], 'active_subscriptions': [], 'upcoming_sessions': []};
});
