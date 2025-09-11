import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learned_flutter/features/student/models/session_model.dart';
import 'package:learned_flutter/features/student/repositories/session_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final supabaseClient = Supabase.instance.client;
  return SessionRepository(supabaseClient: supabaseClient);
});

final upcomingSessionsProvider = FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final repository = ref.watch(sessionRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  return repository.getUpcomingSessions(userId);
});

class SessionNotifier extends StateNotifier<AsyncValue<void>> {
  final SessionRepository _repository;
  
  SessionNotifier(this._repository) : super(const AsyncValue.data(null));
  
  Future<void> joinSession(String sessionId) async {
    try {
      state = const AsyncValue.loading();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _repository.joinSession(sessionId, userId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

final sessionNotifierProvider = StateNotifierProvider<SessionNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  return SessionNotifier(repository);
});

final sessionDetailsProvider = FutureProvider.family<SessionModel, String>((ref, sessionId) async {
  final repository = ref.watch(sessionRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  // In a real app, you would have a method in the repository to fetch a single session
  // For now, we'll fetch all sessions and find the one with matching ID
  final sessions = await repository.getUpcomingSessions(userId);
  final sessionData = sessions.firstWhere(
    (s) => s.id == sessionId,
    orElse: () => throw Exception('Session not found'),
  );
  
  return sessionData;
});
