import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/classroom_service.dart';

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  return ClassroomService();
});

// Simple provider that fetches all classrooms once
final allClassroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  print('🔍 Fetching all classrooms...');
  final service = ref.watch(classroomServiceProvider);
  return service.getAvailableClassrooms();
});

// Legacy provider kept for compatibility with other parts of the app
final availableClassroomsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Map<String, dynamic>?>((ref, filters) async {
      print('🔍 Legacy provider called with filters: $filters');
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
