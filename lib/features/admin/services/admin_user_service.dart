import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for admin operations like creating users
class AdminUserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new user with email and password using Supabase Auth
  /// This is the ONLY way to create users with passwords in Supabase
  static Future<User?> createUserWithPassword({
    required String email,
    required String password,
    required String userType,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      print('🔐 Creating user with Supabase Auth: $email');

      // Use Supabase Auth to create user (this handles password hashing)
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'user_type': userType, 'first_name': firstName, 'last_name': lastName},
      );

      if (response.user != null) {
        print('✅ Auth user created: ${response.user!.id}');

        // Create corresponding record in public.users
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'user_type': userType,
          'phone': phone,
          'is_active': true,
          'email_verified': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        print('✅ Public user record created');

        // Create role-specific record
        await _createRoleSpecificRecord(response.user!.id, userType);

        print('✅ Role-specific record created for type: $userType');
        return response.user;
      } else {
        print('❌ Failed to create auth user');
      }
    } catch (e) {
      print('❌ Error creating user: $e');
    }
    return null;
  }

  /// Create role-specific records (students, teachers, etc.)
  static Future<void> _createRoleSpecificRecord(String userId, String userType) async {
    final timestamp = DateTime.now().toIso8601String();

    switch (userType) {
      case 'student':
        await _supabase.from('students').insert({
          'id': userId,
          'user_id': userId,
          'student_id': 'STU-${DateTime.now().millisecondsSinceEpoch}',
          'grade_level': 9, // Default
          'status': 'active',
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        break;

      case 'teacher':
        await _supabase.from('teachers').insert({
          'id': userId,
          'user_id': userId,
          'teacher_id': 'TCH-${DateTime.now().millisecondsSinceEpoch}',
          'status': 'active',
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        break;

      case 'admin':
        // If you have an admins table, create record here
        print('📝 Admin user type - no specific table needed');
        break;

      case 'parent':
        await _supabase.from('parents').insert({
          'id': userId,
          'user_id': userId,
          'status': 'active',
          'created_at': timestamp,
          'updated_at': timestamp,
        });
        break;
    }
  }
}

/// Helper for seeding users during development/setup
class UserSeeder {
  /// Seed admin users
  static Future<void> seedAdminUsers() async {
    print('🌱 Seeding admin users...');

    final adminUsers = [
      {
        'email': 'admin@learned.com',
        'password': 'AdminSecure123!',
        'user_type': 'admin',
        'first_name': 'System',
        'last_name': 'Administrator',
      },
      {
        'email': 'principal@learned.com',
        'password': 'PrincipalSecure123!',
        'user_type': 'admin',
        'first_name': 'School',
        'last_name': 'Principal',
      },
    ];

    for (final userData in adminUsers) {
      final user = await AdminUserService.createUserWithPassword(
        email: userData['email']!,
        password: userData['password']!,
        userType: userData['user_type']!,
        firstName: userData['first_name']!,
        lastName: userData['last_name']!,
      );

      if (user != null) {
        print('✅ Created admin: ${userData['email']}');
      } else {
        print('❌ Failed to create admin: ${userData['email']}');
      }

      // Delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  /// Seed test users for development
  static Future<void> seedTestUsers() async {
    print('🧪 Seeding test users...');

    final testUsers = [
      {
        'email': 'student.test@learned.com',
        'password': 'StudentTest123!',
        'user_type': 'student',
        'first_name': 'Test',
        'last_name': 'Student',
      },
      {
        'email': 'teacher.test@learned.com',
        'password': 'TeacherTest123!',
        'user_type': 'teacher',
        'first_name': 'Test',
        'last_name': 'Teacher',
      },
      {
        'email': 'parent.test@learned.com',
        'password': 'ParentTest123!',
        'user_type': 'parent',
        'first_name': 'Test',
        'last_name': 'Parent',
      },
    ];

    for (final userData in testUsers) {
      final user = await AdminUserService.createUserWithPassword(
        email: userData['email']!,
        password: userData['password']!,
        userType: userData['user_type']!,
        firstName: userData['first_name']!,
        lastName: userData['last_name']!,
      );

      if (user != null) {
        print('✅ Created test user: ${userData['email']}');
      }

      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }
}
