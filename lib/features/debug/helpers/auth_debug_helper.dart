import 'package:flutter/material.dart';
import '../../student/services/student_service.dart';
import './flow_verification_helper.dart';

class AuthDebugHelper {
  static final StudentService _studentService = StudentService();

  /// Show a debug dialog with authentication information
  static Future<void> showAuthDebugDialog(BuildContext context) async {
    // Get debug information
    final debugInfo = await _studentService.getFullStatus();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugSection('Authentication Status', [
                'User Exists: ${debugInfo['auth_info']['user_exists']}',
                'Session Exists: ${debugInfo['auth_info']['session_exists']}',
                'User in Database: ${debugInfo['auth_info']['user_in_database']}',
                'Student Record Exists: ${debugInfo['auth_info']['student_record_exists']}',
              ]),
              const SizedBox(height: 16),
              _buildDebugSection('Student Info', [
                'Student ID: ${debugInfo['student_id'] ?? 'Not Found'}',
                'Is Valid Student: ${debugInfo['is_valid_student']}',
              ]),
              const SizedBox(height: 16),
              _buildDebugSection('User Details', [
                if (debugInfo['auth_info']['user_info'] != null) ...[
                  'User ID: ${debugInfo['auth_info']['user_info']['id']}',
                  'Email: ${debugInfo['auth_info']['user_info']['email']}',
                ],
              ]),
              const SizedBox(height: 16),
              _buildDebugSection('Database Records', [
                if (debugInfo['auth_info']['user_database_record'] != null) ...[
                  'User Type: ${debugInfo['auth_info']['user_database_record']['user_type']}',
                  'Name: ${debugInfo['auth_info']['user_database_record']['first_name']} ${debugInfo['auth_info']['user_database_record']['last_name']}',
                ],
                if (debugInfo['auth_info']['student_record'] != null) ...[
                  'Student ID Code: ${debugInfo['auth_info']['student_record']['student_id']}',
                  'Grade Level: ${debugInfo['auth_info']['student_record']['grade_level']}',
                  'Status: ${debugInfo['auth_info']['student_record']['status']}',
                ],
              ]),
              const SizedBox(height: 8),
              Text('Timestamp: ${debugInfo['timestamp']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              FlowVerificationHelper.showVerificationDialog(context);
            },
            child: const Text('Full Flow Check'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Also print to console
              _studentService.printFullDebugInfo();
            },
            child: const Text('Print to Console'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  static Widget _buildDebugSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text('• $item', style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  /// Simple method to print auth status to console
  static Future<void> printAuthStatus() async {
    await _studentService.printFullDebugInfo();
  }
}
