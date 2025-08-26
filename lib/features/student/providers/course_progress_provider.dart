import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_progress_model.dart';
import '../repositories/course_progress_repository.dart';

final courseProgressRepositoryProvider = Provider<CourseProgressRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  return CourseProgressRepository(supabaseClient: supabaseClient);
});

final courseProgressProvider = FutureProvider.autoDispose<List<CourseProgress>>((ref) async {
  final repository = ref.watch(courseProgressRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return repository.getStudentCourseProgress(userId);
});

class CourseProgressNotifier extends StateNotifier<AsyncValue<void>> {
  final CourseProgressRepository _repository;
  
  CourseProgressNotifier(this._repository) : super(const AsyncValue.data(null));
  
  Future<void> updateLastAccessed(String courseId) async {
    try {
      state = const AsyncValue.loading();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _repository.updateLastAccessed(
        courseId: courseId,
        studentId: userId,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final courseProgressNotifierProvider = StateNotifierProvider<CourseProgressNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(courseProgressRepositoryProvider);
  return CourseProgressNotifier(repository);
});
