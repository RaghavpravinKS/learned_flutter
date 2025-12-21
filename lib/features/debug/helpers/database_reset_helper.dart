import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class for complete database reset during development
class DatabaseResetHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Reset all public tables (safe - you have full control)
  static Future<void> resetPublicTables() async {

    try {
      // Delete in correct order to avoid FK constraint errors
      await _supabase.from('student_classroom_assignments').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      await _supabase.from('payments').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      await _supabase.from('classrooms').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      await _supabase.from('students').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      await _supabase.from('teachers').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      await _supabase.from('parents').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      await _supabase.from('users').delete().neq('id', '00000000-0000-0000-0000-000000000000');

    } catch (e) {
      rethrow;
    }
  }

  /// Verify reset completion
  static Future<Map<String, int>> verifyReset() async {

    final counts = <String, int>{};

    try {
      // Count records in each table using the correct Supabase count API
      final userResponse = await _supabase.from('users').select().count(CountOption.exact);
      counts['users'] = userResponse.count;

      final studentResponse = await _supabase.from('students').select().count(CountOption.exact);
      counts['students'] = studentResponse.count;

      final teacherResponse = await _supabase.from('teachers').select().count(CountOption.exact);
      counts['teachers'] = teacherResponse.count;

      final parentResponse = await _supabase.from('parents').select().count(CountOption.exact);
      counts['parents'] = parentResponse.count;

      final classroomResponse = await _supabase.from('classrooms').select().count(CountOption.exact);
      counts['classrooms'] = classroomResponse.count;

      final enrollmentResponse = await _supabase
          .from('student_classroom_assignments')
          .select()
          .count(CountOption.exact);
      counts['enrollments'] = enrollmentResponse.count;

      final paymentResponse = await _supabase.from('payments').select().count(CountOption.exact);
      counts['payments'] = paymentResponse.count;

      // Print results
      counts.forEach((table, count) {
        final status = count == 0 ? '✅' : '❌';
      });

      final allEmpty = counts.values.every((count) => count == 0);

      return counts;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current auth user count (read-only check)
  static Future<void> checkAuthUsers() async {

    try {
      final currentUser = _supabase.auth.currentUser;

      // Note: We can't directly count auth.users from client
    } catch (e) {
    }
  }

  /// Complete reset workflow
  static Future<void> performCompleteReset() async {

    try {
      // Step 1: Reset public tables
      await resetPublicTables();

      // Step 2: Verify public tables
      await verifyReset();

      // Step 3: Check auth status
      await checkAuthUsers();

    } catch (e) {
      rethrow;
    }
  }

  /// Instructions for manual auth.users reset
  static void printAuthResetInstructions() {
  }
}
