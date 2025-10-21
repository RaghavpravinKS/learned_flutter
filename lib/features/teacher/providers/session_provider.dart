import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_model.dart';

// Provider to get teacher sessions
final teacherSessionsProvider = FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final teacherId = supabase.auth.currentUser?.id;

  if (teacherId == null) {
    throw Exception('Teacher not authenticated');
  }

  // Get teacher's ID from teachers table
  final teacherData = await supabase.from('teachers').select('id').eq('user_id', teacherId).single();

  final teacherDbId = teacherData['id'] as String;

  // Get all classrooms for this teacher
  final classrooms = await supabase.from('classrooms').select('id').eq('teacher_id', teacherDbId);

  final classroomIds = classrooms.map((c) => c['id'] as String).toList();

  if (classroomIds.isEmpty) {
    return [];
  }

  // Get sessions for these classrooms with classroom names
  final response = await supabase
      .from('class_sessions')
      .select('''
        *,
        classrooms!inner(name)
      ''')
      .inFilter('classroom_id', classroomIds)
      .order('session_date', ascending: true)
      .order('start_time', ascending: true);

  return (response as List).map((sessionData) {
    // Flatten the classroom name
    final classroomName = sessionData['classrooms']['name'] as String?;
    final flatData = Map<String, dynamic>.from(sessionData);
    flatData['classroom_name'] = classroomName;
    flatData.remove('classrooms');

    return SessionModel.fromMap(flatData);
  }).toList();
});

// Provider to get upcoming sessions only
final upcomingSessionsProvider = FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final allSessions = await ref.watch(teacherSessionsProvider.future);
  final now = DateTime.now();

  return allSessions.where((session) {
    return session.sessionDate.isAfter(now) || session.isToday;
  }).toList();
});

// Provider to get past sessions
final pastSessionsProvider = FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final allSessions = await ref.watch(teacherSessionsProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return allSessions.where((session) {
    final sessionDay = DateTime(session.sessionDate.year, session.sessionDate.month, session.sessionDate.day);
    return sessionDay.isBefore(today);
  }).toList();
});

// Provider to get sessions for a specific classroom
final classroomSessionsProvider = FutureProvider.autoDispose.family<List<SessionModel>, String>((
  ref,
  classroomId,
) async {
  final allSessions = await ref.watch(teacherSessionsProvider.future);
  return allSessions.where((session) => session.classroomId == classroomId).toList();
});
