import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for handling authentication with Supabase

class AuthService {
  final SupabaseClient _supabase;

  /// Private constructor
  AuthService() : _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userMetadata,
  }) async {
    return await _supabase.auth.signUp(email: email, password: password, data: userMetadata);
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sign out - clears session and all persistent data
  Future<void> signOut() async {
    try {
      // Sign out from Supabase (this automatically clears session and persistent data)
      await _supabase.auth.signOut();

      // Supabase automatically handles:
      // - Clearing the session from memory
      // - Removing persistent auth state from secure storage
      // - Invalidating refresh tokens
      // - Triggering auth state change listeners

    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabase.from('user_profiles').select().eq('user_id', userId).single();
    return response as Map<String, dynamic>?;
  }

  // Update user profile
  Future<void> updateUserProfile({required String userId, required Map<String, dynamic> updates}) async {
    await _supabase.from('user_profiles').update(updates).eq('user_id', userId);
  }
}
