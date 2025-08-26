import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabaseClient;
  
  AuthService(this._supabaseClient);
  
  // Get the current user
  User? get currentUser => _supabaseClient.auth.currentUser;
  
  // Get the current session
  Session? get currentSession => _supabaseClient.auth.currentSession;
  
  // Check if user is logged in
  bool get isLoggedIn => currentSession != null;
  
  // Stream of auth state changes
  Stream<AuthState> get onAuthStateChange => _supabaseClient.auth.onAuthStateChange;
  
  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userMetadata,
  }) async {
    return await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: userMetadata,
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
  
  // Reset password (returns void as we don't need the response)
  Future<void> resetPassword(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(email);
  }
  
  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
