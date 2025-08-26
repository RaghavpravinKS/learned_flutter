import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learned_flutter/features/student/models/class_model.dart';
import 'package:learned_flutter/features/student/repositories/class_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  return ClassRepository(supabaseClient: supabaseClient);
});

final upcomingClassesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) async {
  final repository = ref.watch(classRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return repository.getUpcomingClasses(userId);
});

class ClassNotifier extends StateNotifier<AsyncValue<void>> {
  final ClassRepository _repository;
  
  ClassNotifier(this._repository) : super(const AsyncValue.data(null));
  
  Future<void> joinClass(String classId) async {
    try {
      state = const AsyncValue.loading();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _repository.joinClass(classId, userId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final classNotifierProvider = StateNotifierProvider<ClassNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(classRepositoryProvider);
  return ClassNotifier(repository);
});

final classDetailsProvider = FutureProvider.family<ClassModel, String>((ref, classId) async {
  final repository = ref.watch(classRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  // In a real app, you would have a method in the repository to fetch a single class
  // For now, we'll fetch all classes and find the one with matching ID
  final classes = await repository.getUpcomingClasses(userId);
  final classData = classes.firstWhere(
    (c) => c.id == classId,
    orElse: () => throw Exception('Class not found'),
  );
  
  return classData;
});
