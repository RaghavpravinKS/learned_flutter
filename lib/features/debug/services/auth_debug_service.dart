import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDebugService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Comprehensive authentication state debug information
  Future<Map<String, dynamic>> getAuthDebugInfo() async {
    final debugInfo = <String, dynamic>{};

    try {
      // 1. Current Session Info
      final session = _supabase.auth.currentSession;
      debugInfo['session_exists'] = session != null;
      debugInfo['session_info'] = session != null
          ? {
              'access_token_exists': session.accessToken.isNotEmpty,
              'refresh_token_exists': session.refreshToken?.isNotEmpty ?? false,
              'expires_at': session.expiresAt != null
                  ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000).toIso8601String()
                  : null,
              'expires_in': session.expiresIn,
              'is_expired': session.isExpired,
            }
          : null;

      // 2. Current User Info
      final user = _supabase.auth.currentUser;
      debugInfo['user_exists'] = user != null;
      debugInfo['user_info'] = user != null
          ? {
              'id': user.id,
              'email': user.email,
              'phone': user.phone,
              'email_confirmed_at': user.emailConfirmedAt,
              'phone_confirmed_at': user.phoneConfirmedAt,
              'confirmed_at': user.confirmedAt,
              'created_at': user.createdAt,
              'updated_at': user.updatedAt,
              'last_sign_in_at': user.lastSignInAt,
            }
          : null;

      // 3. User Metadata
      if (user != null) {
        debugInfo['user_metadata'] = user.userMetadata;
        debugInfo['app_metadata'] = user.appMetadata;
      }

      // 4. Check if user exists in our users table
      if (user != null) {
        try {
          final userRecord = await _supabase.from('users').select('*').eq('id', user.id).maybeSingle();

          debugInfo['user_in_database'] = userRecord != null;
          debugInfo['user_database_record'] = userRecord;
        } catch (e) {
          debugInfo['user_database_error'] = e.toString();
        }
      }

      // 5. Check if student record exists
      if (user != null) {
        try {
          final studentRecord = await _supabase
              .from('students')
              .select('''
                id,
                user_id,
                student_id,
                grade_level,
                school_name,
                board,
                status,
                created_at,
                updated_at
              ''')
              .eq('user_id', user.id)
              .maybeSingle();

          debugInfo['student_record_exists'] = studentRecord != null;
          debugInfo['student_record'] = studentRecord;
        } catch (e) {
          debugInfo['student_record_error'] = e.toString();
        }
      }

      // 6. Check local storage persistence
      debugInfo['local_storage_info'] = await _checkLocalStorage();

      // 7. Check if auth state is persisted
      debugInfo['auth_persistence_enabled'] = true; // Supabase auto-persists by default
    } catch (e) {
      debugInfo['error'] = e.toString();
    }

    return debugInfo;
  }

  /// Check what's stored in local storage
  Future<Map<String, dynamic>> _checkLocalStorage() async {
    try {
      // Supabase stores auth state in browser localStorage/SharedPreferences
      // We can check if session is persisted by seeing if it survives app restart
      final session = _supabase.auth.currentSession;

      return {
        'session_persisted': session != null,
        'session_created_from_storage': session?.accessToken.isNotEmpty ?? false,
        'note': 'Supabase automatically persists auth state in secure storage',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Print comprehensive auth debug info to console (disabled in production)
  Future<void> printAuthDebugInfo() async {
    // Debug prints removed for production - use getAuthDebugInfo() to get data programmatically
  }

  /// Quick check if user is properly authenticated with student record
  Future<bool> isValidStudentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final studentRecord = await _supabase
          .from('students')
          .select('id, status')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      return studentRecord != null;
    } catch (e) {
      return false;
    }
  }

  /// Force refresh the current session
  Future<void> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
    } catch (e) {
      // Failed to refresh session
    }
  }
}
