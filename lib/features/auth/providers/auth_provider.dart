import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider that exposes the current auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.onAuthStateChange.map((authState) => authState.session?.user);
});

/// Provider for the current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// Provider that indicates whether a user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Provider for the current user's ID
final userIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

/// Provider for the current user's email
final userEmailProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.email;
});

/// Provider for the current user's metadata
final userMetadataProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(currentUserProvider)?.userMetadata;
});
