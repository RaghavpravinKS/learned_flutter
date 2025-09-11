import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class for complete database reset during development
class DatabaseResetHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Reset all public tables (safe - you have full control)
  static Future<void> resetPublicTables() async {
    print('🗑️ Starting public tables reset...');
    
    try {
      // Delete in correct order to avoid FK constraint errors
      await _supabase.from('student_classroom_assignments').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      print('✅ Cleared student_classroom_assignments');
      
      await _supabase.from('payments').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      print('✅ Cleared payments');
      
      await _supabase.from('classrooms').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      print('✅ Cleared classrooms');
      
      await _supabase.from('students').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      print('✅ Cleared students');
      
      await _supabase.from('teachers').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      print('✅ Cleared teachers');
      
      await _supabase.from('parents').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      print('✅ Cleared parents');
      
      await _supabase.from('users').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      print('✅ Cleared users');
      
      print('🎉 Public tables reset completed!');
      
    } catch (e) {
      print('❌ Error resetting public tables: $e');
      rethrow;
    }
  }

  /// Verify reset completion
  static Future<Map<String, int>> verifyReset() async {
    print('🔍 Verifying reset completion...');
    
    final counts = <String, int>{};
    
    try {
      // Count records in each table
      final userCount = await _supabase.from('users').select('id', const FetchOptions(count: CountOption.exact));
      counts['users'] = userCount.count ?? 0;
      
      final studentCount = await _supabase.from('students').select('id', const FetchOptions(count: CountOption.exact));
      counts['students'] = studentCount.count ?? 0;
      
      final teacherCount = await _supabase.from('teachers').select('id', const FetchOptions(count: CountOption.exact));
      counts['teachers'] = teacherCount.count ?? 0;
      
      final parentCount = await _supabase.from('parents').select('id', const FetchOptions(count: CountOption.exact));
      counts['parents'] = parentCount.count ?? 0;
      
      final classroomCount = await _supabase.from('classrooms').select('id', const FetchOptions(count: CountOption.exact));
      counts['classrooms'] = classroomCount.count ?? 0;
      
      final enrollmentCount = await _supabase.from('student_classroom_assignments').select('id', const FetchOptions(count: CountOption.exact));
      counts['enrollments'] = enrollmentCount.count ?? 0;
      
      final paymentCount = await _supabase.from('payments').select('id', const FetchOptions(count: CountOption.exact));
      counts['payments'] = paymentCount.count ?? 0;
      
      // Print results
      print('📊 Reset Verification Results:');
      counts.forEach((table, count) {
        final status = count == 0 ? '✅' : '❌';
        print('   $status $table: $count records');
      });
      
      final allEmpty = counts.values.every((count) => count == 0);
      print(allEmpty ? '🎉 All public tables are empty!' : '⚠️ Some tables still have data');
      
      return counts;
      
    } catch (e) {
      print('❌ Error verifying reset: $e');
      rethrow;
    }
  }

  /// Get current auth user count (read-only check)
  static Future<void> checkAuthUsers() async {
    print('🔍 Checking auth users...');
    
    try {
      final currentUser = _supabase.auth.currentUser;
      print('📱 Current logged in user: ${currentUser?.email ?? 'None'}');
      
      // Note: We can't directly count auth.users from client
      print('ℹ️ To reset auth.users, use Supabase Dashboard or Admin API');
      
    } catch (e) {
      print('❌ Error checking auth users: $e');
    }
  }

  /// Complete reset workflow
  static Future<void> performCompleteReset() async {
    print('🚀 Starting COMPLETE database reset...');
    print('⚠️ WARNING: This will delete ALL data!');
    
    try {
      // Step 1: Reset public tables
      await resetPublicTables();
      
      // Step 2: Verify public tables
      await verifyReset();
      
      // Step 3: Check auth status
      await checkAuthUsers();
      
      print('✅ Reset workflow completed!');
      print('📝 Next steps:');
      print('   1. Reset auth.users via Supabase Dashboard if needed');
      print('   2. Start fresh registration flow testing');
      print('   3. Use verification tools to test each step');
      
    } catch (e) {
      print('❌ Reset workflow failed: $e');
      rethrow;
    }
  }

  /// Instructions for manual auth.users reset
  static void printAuthResetInstructions() {
    print('🔧 How to reset auth.users:');
    print('');
    print('METHOD 1 - Supabase Dashboard:');
    print('1. Go to https://supabase.com/dashboard');
    print('2. Select your project');
    print('3. Go to Authentication > Users');
    print('4. Select all users and delete them');
    print('');
    print('METHOD 2 - Admin API (Backend):');
    print('1. Use service role key (not anon key)');
    print('2. Call supabase.auth.admin.deleteUser() for each user');
    print('');
    print('METHOD 3 - Project Reset (Nuclear):');
    print('1. Go to Settings > General');
    print('2. Delete and recreate project');
    print('3. Run database migrations again');
  }
}
