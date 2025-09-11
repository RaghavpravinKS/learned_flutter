import 'package:flutter/material.dart';
import '../../admin/services/admin_user_service.dart';

class AdminDebugHelper {
  /// Show admin user creation dialog
  static Future<void> showCreateAdminDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    String selectedUserType = 'admin';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Admin User'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedUserType,
                  decoration: const InputDecoration(labelText: 'User Type'),
                  items: [
                    'admin',
                    'teacher',
                    'student',
                    'parent',
                  ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) => setState(() => selectedUserType = value!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                Navigator.of(context).pop();

                final user = await AdminUserService.createUserWithPassword(
                  email: emailController.text,
                  password: passwordController.text,
                  userType: selectedUserType,
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(user != null ? 'User created successfully!' : 'Failed to create user'),
                      backgroundColor: user != null ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// Quick seed function
  static Future<void> seedTestData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Creating test users...')],
        ),
      ),
    );

    try {
      await UserSeeder.seedTestUsers();
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test users created successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
