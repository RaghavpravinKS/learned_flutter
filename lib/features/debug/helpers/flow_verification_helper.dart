import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Comprehensive flow verification tool for LearnED app
class FlowVerificationHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Verify complete user registration and setup
  static Future<Map<String, dynamic>> verifyUserFlow(String? userEmail) async {

    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'user_email': userEmail,
      'verification_results': {},
    };

    try {
      // 1. Check current authentication
      final authUser = _supabase.auth.currentUser;
      final session = _supabase.auth.currentSession;

      results['verification_results']['authentication'] = {
        'user_logged_in': authUser != null,
        'session_exists': session != null,
        'session_valid': session != null && !session.isExpired,
        'user_id': authUser?.id,
        'user_email': authUser?.email,
        'user_metadata': authUser?.userMetadata,
      };

      if (authUser == null) {
        return results;
      }

      // 2. Check public.users table
      final publicUserResponse = await _supabase.from('users').select().eq('id', authUser.id).maybeSingle();

      results['verification_results']['public_user'] = {
        'exists': publicUserResponse != null,
        'data': publicUserResponse,
        'user_type': publicUserResponse?['user_type'],
        'name': '${publicUserResponse?['first_name'] ?? ''} ${publicUserResponse?['last_name'] ?? ''}'.trim(),
      };

      if (publicUserResponse == null) {
        return results;
      }

      final userType = publicUserResponse['user_type'];

      // 3. Check role-specific table
      await _verifyRoleSpecificRecord(authUser.id, userType, results);

      // 4. Check enrollments (for students)
      if (userType == 'student') {
        await _verifyStudentEnrollments(authUser.id, results);
      }

      // 5. Check profile completeness
      await _verifyProfileCompleteness(authUser.id, userType, results);

      // 6. Test database connectivity
      await _verifyDatabaseConnectivity(results);

      return results;
    } catch (e) {
      results['verification_results']['error'] = {
        'message': e.toString(),
        'occurred_at': DateTime.now().toIso8601String(),
      };
      return results;
    }
  }

  /// Verify role-specific record exists
  static Future<void> _verifyRoleSpecificRecord(String userId, String userType, Map<String, dynamic> results) async {
    switch (userType) {
      case 'student':
        final studentResponse = await _supabase.from('students').select().eq('user_id', userId).maybeSingle();

        results['verification_results']['student_record'] = {
          'exists': studentResponse != null,
          'data': studentResponse,
          'student_id': studentResponse?['student_id'],
          'grade_level': studentResponse?['grade_level'],
          'school_name': studentResponse?['school_name'],
          'status': studentResponse?['status'],
        };
        break;

      case 'teacher':
        final teacherResponse = await _supabase.from('teachers').select().eq('user_id', userId).maybeSingle();

        results['verification_results']['teacher_record'] = {
          'exists': teacherResponse != null,
          'data': teacherResponse,
          'teacher_id': teacherResponse?['teacher_id'],
          'qualifications': teacherResponse?['qualifications'],
          'experience_years': teacherResponse?['experience_years'],
          'status': teacherResponse?['status'],
        };
        break;

      case 'parent':
        final parentResponse = await _supabase.from('parents').select().eq('user_id', userId).maybeSingle();

        results['verification_results']['parent_record'] = {'exists': parentResponse != null, 'data': parentResponse};
        break;
    }
  }

  /// Verify student enrollments
  static Future<void> _verifyStudentEnrollments(String userId, Map<String, dynamic> results) async {
    // First get student ID
    final studentResponse = await _supabase.from('students').select('id').eq('user_id', userId).maybeSingle();

    if (studentResponse == null) {
      results['verification_results']['enrollments'] = {'error': 'Student record not found'};
      return;
    }

    final studentId = studentResponse['id'];

    // Get enrollments with classroom and teacher details
    final enrollments = await _supabase
        .from('student_classroom_assignments')
        .select('''
          id,
          enrolled_date,
          status,
          progress,
          classrooms (
            id,
            name,
            subject,
            grade_level
          ),
          teachers (
            id,
            users (
              first_name,
              last_name
            )
          )
        ''')
        .eq('student_id', studentId);

    results['verification_results']['enrollments'] = {
      'count': enrollments.length,
      'data': enrollments,
      'active_count': enrollments.where((e) => e['status'] == 'active').length,
    };

    // Check payments
    final payments = await _supabase
        .from('payments')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    results['verification_results']['payments'] = {
      'count': payments.length,
      'data': payments,
      'successful_count': payments.where((p) => p['payment_status'] == 'completed').length,
    };
  }

  /// Verify profile completeness
  static Future<void> _verifyProfileCompleteness(String userId, String userType, Map<String, dynamic> results) async {
    final userResponse = await _supabase.from('users').select().eq('id', userId).single();

    final completeness = <String, bool>{
      'has_first_name': userResponse['first_name']?.isNotEmpty == true,
      'has_last_name': userResponse['last_name']?.isNotEmpty == true,
      'has_email': userResponse['email']?.isNotEmpty == true,
      'has_phone': userResponse['phone']?.isNotEmpty == true,
    };

    if (userType == 'student') {
      final studentResponse = await _supabase.from('students').select().eq('user_id', userId).maybeSingle();

      if (studentResponse != null) {
        completeness.addAll({
          'has_grade_level': studentResponse['grade_level'] != null,
          'has_school_name': studentResponse['school_name']?.isNotEmpty == true,
          'has_student_id': studentResponse['student_id']?.isNotEmpty == true,
        });
      }
    }

    final completionPercentage = (completeness.values.where((v) => v).length / completeness.length * 100).round();

    results['verification_results']['profile_completeness'] = {
      'percentage': completionPercentage,
      'details': completeness,
      'is_complete': completionPercentage == 100,
    };
  }

  /// Test database connectivity and permissions
  static Future<void> _verifyDatabaseConnectivity(Map<String, dynamic> results) async {
    final connectivity = <String, bool>{};

    try {
      // Test read access to main tables
      await _supabase.from('users').select('count').limit(1);
      connectivity['users_table'] = true;
    } catch (e) {
      connectivity['users_table'] = false;
    }

    try {
      await _supabase.from('classrooms').select('count').limit(1);
      connectivity['classrooms_table'] = true;
    } catch (e) {
      connectivity['classrooms_table'] = false;
    }

    try {
      await _supabase.from('students').select('count').limit(1);
      connectivity['students_table'] = true;
    } catch (e) {
      connectivity['students_table'] = false;
    }

    try {
      await _supabase.from('teachers').select('count').limit(1);
      connectivity['teachers_table'] = true;
    } catch (e) {
      connectivity['teachers_table'] = false;
    }

    results['verification_results']['database_connectivity'] = connectivity;
  }

  /// Print detailed verification report
  static void printVerificationReport(Map<String, dynamic> results) {

    final verificationResults = results['verification_results'] as Map<String, dynamic>;

    // Authentication status
    final auth = verificationResults['authentication'] as Map<String, dynamic>;

    // Public user record
    final publicUser = verificationResults['public_user'] as Map<String, dynamic>;

    // Role-specific verification
    final userType = publicUser['user_type'];
    if (verificationResults.containsKey('${userType}_record')) {
      final roleRecord = verificationResults['${userType}_record'] as Map<String, dynamic>;
      if (roleRecord['exists'] == true) {
        roleRecord.forEach((key, value) {
          if (key != 'exists' && key != 'data') {
          }
        });
      }
    }

    // Enrollments (for students)
    if (verificationResults.containsKey('enrollments')) {
      final enrollments = verificationResults['enrollments'] as Map<String, dynamic>;
    }

    // Payments (for students)
    if (verificationResults.containsKey('payments')) {
      final payments = verificationResults['payments'] as Map<String, dynamic>;
    }

    // Profile completeness
    if (verificationResults.containsKey('profile_completeness')) {
      final profile = verificationResults['profile_completeness'] as Map<String, dynamic>;
    }

    // Database connectivity
    if (verificationResults.containsKey('database_connectivity')) {
      final db = verificationResults['database_connectivity'] as Map<String, dynamic>;
      db.forEach((table, accessible) {
      });
    }

  }

  /// Show verification dialog in the app
  static Future<void> showVerificationDialog(BuildContext context) async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flow Verification'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: verifyUserFlow(currentUser?.email),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Verifying user flow...')],
              );
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            final results = snapshot.data!;
            printVerificationReport(results);

            final verification = results['verification_results'] as Map<String, dynamic>;
            final auth = verification['authentication'] as Map<String, dynamic>;
            final publicUser = verification['public_user'] as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusItem('Authentication', auth['user_logged_in'] == true),
                  _buildStatusItem('Public User Record', publicUser['exists'] == true),
                  _buildStatusItem('User Type: ${publicUser['user_type']}', true),
                  if (verification.containsKey('student_record'))
                    _buildStatusItem('Student Record', verification['student_record']['exists'] == true),
                  if (verification.containsKey('teacher_record'))
                    _buildStatusItem('Teacher Record', verification['teacher_record']['exists'] == true),
                  if (verification.containsKey('enrollments'))
                    _buildStatusItem('Enrollments: ${verification['enrollments']['count']}', true),
                  if (verification.containsKey('profile_completeness'))
                    _buildStatusItem(
                      'Profile: ${verification['profile_completeness']['percentage']}%',
                      verification['profile_completeness']['is_complete'] == true,
                    ),
                ],
              ),
            );
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  static Widget _buildStatusItem(String label, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(isGood ? Icons.check_circle : Icons.error, color: isGood ? Colors.green : Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
