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
        print('🔍 StudentService: No authenticated user found');
        return null;
      }

      print('🔍 StudentService: Current user ID: ${currentUser.id}');
      print('🔍 StudentService: Current user email: ${currentUser.email}');

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
              user_type
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('status', 'active')
          .maybeSingle();

      if (studentRecord != null) {
        print('🔍 StudentService: Found student record: ${studentRecord['student_id']}');
        print(
          '🔍 StudentService: Student name: ${studentRecord['users']['first_name']} ${studentRecord['users']['last_name']}',
        );
        return studentRecord;
      } else {
        print('🔍 StudentService: No student record found for user ${currentUser.id}');

        // Check if this user exists in the users table but not in students
        final userRecord = await _supabase
            .from('users')
            .select('id, first_name, last_name, email, user_type')
            .eq('id', currentUser.id)
            .maybeSingle();

        if (userRecord != null) {
          print('🔍 StudentService: User exists but no student record: ${userRecord}');
          if (userRecord['user_type'] != 'student') {
            print('🔍 StudentService: User is not a student (type: ${userRecord['user_type']})');
          }
        } else {
          print('🔍 StudentService: User not found in users table');
        }

        return null;
      }
    } catch (e) {
      print('🔍 StudentService: Error getting current student profile: $e');
      return null;
    }
  }

  /// Get the current authenticated user's student ID (UUID from students table)
  Future<String?> getCurrentStudentId() async {
    try {
      final studentProfile = await getCurrentStudentProfile();
      if (studentProfile != null) {
        final studentId = studentProfile['id'] as String?;
        print('🔍 StudentService: Current student ID: $studentId');
        return studentId;
      }

      print('🔍 StudentService: No student ID found - user may not be a student');
      return null;
    } catch (e) {
      print('🔍 StudentService: Error getting current student ID: $e');
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
    print('\n🔍 ==================== STUDENT SERVICE DEBUG ====================');
    await _authDebug.printAuthDebugInfo();

    // Additional checks
    print('🎓 STUDENT SERVICE CHECKS:');
    final isValid = await isValidStudentUser();
    print('   Is Valid Student User: $isValid');

    final studentId = await getCurrentStudentId();
    print('   Student ID Retrieved: $studentId');

    print('🔍 ============================================================\n');
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
      print('🔍 StudentService: Error checking valid student user: $e');
      return false;
    }
  }
}
