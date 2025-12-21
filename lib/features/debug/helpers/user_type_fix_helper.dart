import 'package:supabase_flutter/supabase_flutter.dart';

class UserTypeFixHelper {
  static Future<void> fixCurrentUserType() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }


    try {
      // Check if user exists in teachers table
      final teacherResponse = await Supabase.instance.client
          .from('teachers')
          .select('id, teacher_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (teacherResponse != null) {

        // Update user metadata to include user_type
        final currentMetadata = Map<String, dynamic>.from(user.userMetadata ?? {});
        currentMetadata['user_type'] = 'teacher';

        await Supabase.instance.client.auth.updateUser(UserAttributes(data: currentMetadata));

        return;
      }

      // Check if user exists in students table
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('id, student_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentResponse != null) {

        // Update user metadata to include user_type
        final currentMetadata = Map<String, dynamic>.from(user.userMetadata ?? {});
        currentMetadata['user_type'] = 'student';

        await Supabase.instance.client.auth.updateUser(UserAttributes(data: currentMetadata));

        return;
      }

    } catch (e) {
    }
  }

  static Future<void> printCurrentUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }


    try {
      // Check teachers table
      final teacherResponse = await Supabase.instance.client
          .from('teachers')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (teacherResponse != null) {
      } else {
      }

      // Check students table
      final studentResponse = await Supabase.instance.client
          .from('students')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentResponse != null) {
      } else {
      }
    } catch (e) {
    }
  }
}
