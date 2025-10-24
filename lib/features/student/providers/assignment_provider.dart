import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment_model.dart';
import '../repositories/assignment_repository.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  return AssignmentRepository(supabaseClient: supabaseClient);
});

final upcomingAssignmentsProvider = FutureProvider.autoDispose<List<Assignment>>((ref) async {
  print('=== UPCOMING ASSIGNMENTS PROVIDER ===');
  final repository = ref.watch(assignmentRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  print('Current user ID: $userId');

  if (userId == null) {
    print('ERROR: User not authenticated');
    throw Exception('User not authenticated');
  }

  print('Fetching assignments from repository...');
  final assignments = await repository.getUpcomingAssignments(userId);
  print('Provider returning ${assignments.length} assignments');
  print('====================================');

  return assignments;
});

// Provider to get assignments for a specific classroom
final classroomAssignmentsProvider = FutureProvider.autoDispose.family<List<Assignment>, String>((
  ref,
  classroomId,
) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Get all upcoming assignments and filter by classroom
  final allAssignments = await repository.getUpcomingAssignments(userId);
  return allAssignments.where((assignment) => assignment.classId == classroomId).toList();
});

class AssignmentNotifier extends StateNotifier<AsyncValue<void>> {
  final AssignmentRepository _repository;

  AssignmentNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> submitAssignment({required String assignmentId, required String submissionUrl}) async {
    try {
      state = const AsyncValue.loading();
      await _repository.submitAssignment(assignmentId: assignmentId, submissionUrl: submissionUrl);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final assignmentNotifierProvider = StateNotifierProvider<AssignmentNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(assignmentRepositoryProvider);
  return AssignmentNotifier(repository);
});
