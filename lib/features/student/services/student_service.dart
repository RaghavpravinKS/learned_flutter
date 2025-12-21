import 'package:supabase_flutter/supabase_flutter.dart';
import '../../debug/services/auth_debug_service.dart';

class StudentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthDebugService _authDebug = AuthDebugService();

  /// Get the current authenticated user's student record
  Future<Map<String, dynamic>?> getCurrentStudentProfile() async {
    try {
      // First, print comprehensive auth debug info
      await _authDebug.printAuthDebugInfo();

      // Get current authenticated user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return null;
      }


      // Find the student record linked to this user
      final studentRecord = await _supabase
          .from('students')
          .select('''
            id,
            user_id,
            student_id,
            grade_level,
            school_name,
            parent_contact,
            emergency_contact_name,
            emergency_contact_phone,
            board,
            status,
            users(
              id,
              first_name,
              last_name,
              email,
              phone,
              user_type,
              profile_image_url,
              date_of_birth,
              address,
              city,
              state,
              country,
              postal_code,
              created_at
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('status', 'active')
          .maybeSingle();

      if (studentRecord != null) {
        return studentRecord;
      } else {

        // Check if this user exists in the users table but not in students
        final userRecord = await _supabase
            .from('users')
            .select('id, first_name, last_name, email, user_type')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (userRecord != null) {
          if (userRecord['user_type'] != 'student') {
          }
        } else {
        }

        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get the current authenticated user's student ID (UUID from students table)
  Future<String?> getCurrentStudentId() async {
    try {
      final studentProfile = await getCurrentStudentProfile();
      if (studentProfile != null) {
        final studentId = studentProfile['id'] as String?;
        return studentId;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if the current user is authenticated and is a student
  bool get isAuthenticatedStudent {
    final currentUser = _supabase.auth.currentUser;
    return currentUser != null;
  }

  /// Get current user details for debugging
  Map<String, dynamic>? get currentUserDebugInfo {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    return {
      'id': currentUser.id,
      'email': currentUser.email,
      'metadata': currentUser.userMetadata,
      'app_metadata': currentUser.appMetadata,
    };
  }

  /// Print comprehensive debug info about authentication and student data
  Future<void> printFullDebugInfo() async {
    await _authDebug.printAuthDebugInfo();

    // Additional checks
    final isValid = await isValidStudentUser();

    final studentId = await getCurrentStudentId();

  }

  /// Quick method to check all authentication and student data
  Future<Map<String, dynamic>> getFullStatus() async {
    final authInfo = await _authDebug.getAuthDebugInfo();
    final studentId = await getCurrentStudentId();
    final isValid = await isValidStudentUser();

    return {
      'auth_info': authInfo,
      'student_id': studentId,
      'is_valid_student': isValid,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if user is a valid authenticated student (async version)
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
}
