import 'package:supabase_flutter/supabase_flutter.dart';

class UserTypeFixHelper {
  static Future<void> fixCurrentUserType() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('❌ No user is currently logged in');
      return;
    }

    print('🔍 Current user ID: ${user.id}');
    print('🔍 Current metadata: ${user.userMetadata}');

    try {
      // Check if user exists in teachers table
      final teacherResponse = await Supabase.instance.client
          .from('teachers')
          .select('id, teacher_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (teacherResponse != null) {
        print('✅ Found user in teachers table: $teacherResponse');

        // Update user metadata to include user_type
        final currentMetadata = Map<String, dynamic>.from(user.userMetadata ?? {});
        currentMetadata['user_type'] = 'teacher';

        await Supabase.instance.client.auth.updateUser(UserAttributes(data: currentMetadata));

        print('✅ Updated user metadata with user_type: teacher');
        return;
      }

      // Check if user exists in students table
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('id, student_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentResponse != null) {
        print('✅ Found user in students table: $studentResponse');

        // Update user metadata to include user_type
        final currentMetadata = Map<String, dynamic>.from(user.userMetadata ?? {});
        currentMetadata['user_type'] = 'student';

        await Supabase.instance.client.auth.updateUser(UserAttributes(data: currentMetadata));

        print('✅ Updated user metadata with user_type: student');
        return;
      }

      print('❌ User not found in teachers or students table');
    } catch (e) {
      print('❌ Error fixing user type: $e');
    }
  }

  static Future<void> printCurrentUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('❌ No user is currently logged in');
      return;
    }

    print('=== CURRENT USER INFO ===');
    print('User ID: ${user.id}');
    print('Email: ${user.email}');
    print('Metadata: ${user.userMetadata}');

    try {
      // Check teachers table
      final teacherResponse = await Supabase.instance.client
          .from('teachers')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (teacherResponse != null) {
        print('Teacher record: $teacherResponse');
      } else {
        print('No teacher record found');
      }

      // Check students table
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentResponse != null) {
        print('Student record: $studentResponse');
      } else {
        print('No student record found');
      }
    } catch (e) {
      print('Error fetching user info: $e');
    }
    print('========================');
  }
}
