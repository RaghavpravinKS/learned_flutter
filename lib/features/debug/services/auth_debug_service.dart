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
                learning_goals,
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

  /// Print comprehensive auth debug info to console
  Future<void> printAuthDebugInfo() async {
    print('\n🔍 ==================== AUTH DEBUG INFO ====================');

    final debugInfo = await getAuthDebugInfo();

    // Session Info
    print('📱 SESSION:');
    print('   Exists: ${debugInfo['session_exists']}');
    if (debugInfo['session_info'] != null) {
      final sessionInfo = debugInfo['session_info'] as Map<String, dynamic>;
      print('   Access Token: ${sessionInfo['access_token_exists'] ? 'Present' : 'Missing'}');
      print('   Refresh Token: ${sessionInfo['refresh_token_exists'] ? 'Present' : 'Missing'}');
      print('   Expires At: ${sessionInfo['expires_at']}');
      print('   Is Expired: ${sessionInfo['is_expired']}');
    }

    // User Info
    print('\n👤 USER:');
    print('   Exists: ${debugInfo['user_exists']}');
    if (debugInfo['user_info'] != null) {
      final userInfo = debugInfo['user_info'] as Map<String, dynamic>;
      print('   ID: ${userInfo['id']}');
      print('   Email: ${userInfo['email']}');
      print('   Email Confirmed: ${userInfo['email_confirmed_at'] != null}');
      print('   Created: ${userInfo['created_at']}');
      print('   Last Sign In: ${userInfo['last_sign_in_at']}');
    }

    // Metadata
    if (debugInfo['user_metadata'] != null) {
      print('\n📋 USER METADATA:');
      final metadata = debugInfo['user_metadata'] as Map<String, dynamic>;
      metadata.forEach((key, value) {
        print('   $key: $value');
      });
    }

    // Database Records
    print('\n💾 DATABASE RECORDS:');
    print('   User in DB: ${debugInfo['user_in_database']}');
    if (debugInfo['user_database_record'] != null) {
      final dbUser = debugInfo['user_database_record'] as Map<String, dynamic>;
      print('   DB User Type: ${dbUser['user_type']}');
      print('   DB User Name: ${dbUser['first_name']} ${dbUser['last_name']}');
    }

    print('   Student Record: ${debugInfo['student_record_exists']}');
    if (debugInfo['student_record'] != null) {
      final student = debugInfo['student_record'] as Map<String, dynamic>;
      print('   Student ID (UUID): ${student['id']}');
      print('   Student ID (Code): ${student['student_id']}');
      print('   Grade Level: ${student['grade_level']}');
      print('   School: ${student['school_name']}');
      print('   Status: ${student['status']}');
    }

    // Local Storage
    print('\n💿 LOCAL PERSISTENCE:');
    final storageInfo = debugInfo['local_storage_info'] as Map<String, dynamic>;
    print('   Session Persisted: ${storageInfo['session_persisted']}');
    print('   Note: ${storageInfo['note']}');

    // Errors
    if (debugInfo['error'] != null) {
      print('\n❌ ERRORS:');
      print('   ${debugInfo['error']}');
    }

    if (debugInfo['user_database_error'] != null) {
      print('   User DB Error: ${debugInfo['user_database_error']}');
    }

    if (debugInfo['student_record_error'] != null) {
      print('   Student Record Error: ${debugInfo['student_record_error']}');
    }

    print('🔍 ========================================================\n');
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
      print('🔄 Refreshing authentication session...');
      final response = await _supabase.auth.refreshSession();
      print('✅ Session refreshed successfully');
      print('   New expires at: ${response.session?.expiresAt}');
    } catch (e) {
      print('❌ Failed to refresh session: $e');
    }
  }
}
