import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/assignment_model.dart';
import '../repositories/assignment_repository.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  return AssignmentRepository(supabaseClient: supabaseClient);
});

final upcomingAssignmentsProvider = FutureProvider.autoDispose<List<Assignment>>((ref) async {
  final repository = ref.watch(assignmentRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return repository.getUpcomingAssignments(userId);
});

class AssignmentNotifier extends StateNotifier<AsyncValue<void>> {
  final AssignmentRepository _repository;
  
  AssignmentNotifier(this._repository) : super(const AsyncValue.data(null));
  
  Future<void> submitAssignment({
    required String assignmentId,
    required String submissionUrl,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _repository.submitAssignment(
        assignmentId: assignmentId,
        submissionUrl: submissionUrl,
      );
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
