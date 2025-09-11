import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/services/classroom_service.dart';
import 'package:learned_flutter/features/debug/helpers/auth_debug_helper.dart';

// Provider for enrolled classrooms
final enrolledClassroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  print('🔍 MyClassesScreen: enrolledClassroomsProvider called');
  final classroomService = ClassroomService();

  // Let the classroom service determine the student ID from authentication
  // Pass null to trigger authenticated user detection
  print('🔍 MyClassesScreen: Fetching classrooms using authenticated user');

  final classrooms = await classroomService.getEnrolledClassrooms(null);
  print('🔍 MyClassesScreen: Provider received ${classrooms.length} classrooms');

  // Print detailed info about each classroom
  for (int i = 0; i < classrooms.length; i++) {
    final classroom = classrooms[i];
    print('🔍 MyClassesScreen: Classroom $i: ${classroom['name']} - Teacher: ${classroom['teacher_name']}');
  }

  return classrooms;
});

class MyClassesScreen extends ConsumerWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledClassrooms = ref.watch(enrolledClassroomsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            print('🔄 MyClassesScreen: Pull-to-refresh triggered');
            ref.invalidate(enrolledClassroomsProvider);
          },
          child: enrolledClassrooms.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Failed to load classrooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print('🔄 MyClassesScreen: Retry button pressed');
                      ref.invalidate(enrolledClassroomsProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (classrooms) {
              print('🔍 MyClassesScreen: UI rendering with ${classrooms.length} classrooms');
              if (classrooms.isEmpty) {
                print('🔍 MyClassesScreen: No classrooms found, showing empty state');
                return _buildEmptyState(context);
              }
              print('🔍 MyClassesScreen: Building classroom list UI');
              return CustomScrollView(slivers: _buildClassroomList(context, classrooms));
            },
          ),
        ), // Close SafeArea
      ), // Close RefreshIndicator
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _debugEnrollmentData(context, ref),
            mini: true,
            heroTag: "debug_enrollment",
            backgroundColor: Colors.orange.withOpacity(0.7),
            child: const Icon(Icons.storage, size: 16),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => AuthDebugHelper.showAuthDebugDialog(context),
            mini: true,
            heroTag: "debug_auth",
            backgroundColor: Colors.blue.withOpacity(0.7),
            child: const Icon(Icons.bug_report, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8, // Take most of screen height
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No Enrolled Classrooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48.0),
                    child: Text(
                      'You haven\'t enrolled in any classrooms yet. Browse available classrooms to get started!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          context.push('/classrooms');
                        },
                        icon: const Icon(Icons.explore),
                        label: const Text('Browse Classrooms'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          print('🔄 MyClassesScreen: Refresh from empty state');
                          ref.invalidate(enrolledClassroomsProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildClassroomList(BuildContext context, List<Map<String, dynamic>> classrooms) {
    print('🔍 MyClassesScreen: _buildClassroomList called with ${classrooms.length} classrooms');

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0), // Add top padding for status bar
          child: SafeArea(
            child: Row(
              children: [
                const Icon(Icons.school, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'My Classrooms',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Spacer(),
                Text(
                  '${classrooms.length} ${classrooms.length == 1 ? 'classroom' : 'classrooms'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final classroom = classrooms[index];
          print(
            '🔍 MyClassesScreen: Building card for classroom $index: ${classroom['name']} with teacher: ${classroom['teacher_name']}',
          );
          return _buildClassroomCard(context, classroom);
        }, childCount: classrooms.length),
      ),
    ];
  }

  Widget _buildClassroomCard(BuildContext context, Map<String, dynamic> classroom) {
    final theme = Theme.of(context);
    final enrollmentDate = DateTime.tryParse(classroom['enrollment_date'] ?? '');
    final nextSession = DateTime.tryParse(classroom['next_session'] ?? '');
    final progress = (classroom['progress'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigate to classroom details
          context.push('/classrooms/${classroom['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with classroom name and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.subject, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroom['name'] ?? 'Unknown Classroom',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${classroom['subject']} • Grade ${classroom['grade_level']}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teacher and enrollment info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    classroom['teacher_name'] ?? 'Teacher Info Unavailable',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  if (enrollmentDate != null) ...[
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Enrolled ${_formatDate(enrollmentDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),

              if (progress > 0) ...[
                const SizedBox(height: 12),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  if (nextSession != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to session
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Next session: ${_formatDateTime(nextSession)}')));
                        },
                        icon: const Icon(Icons.video_call, size: 16),
                        label: const Text('Next Session'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/classrooms/${classroom['id']}');
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      return '${(difference / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (dateTime.day == now.day && dateTime.month == now.month && dateTime.year == now.year) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (dateTime.day == tomorrow.day && dateTime.month == tomorrow.month && dateTime.year == tomorrow.year) {
      return 'Tomorrow at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _debugEnrollmentData(BuildContext context, WidgetRef ref) async {
    try {
      print('🔍 Debug: Checking enrollment data...');
      final classroomService = ClassroomService();

      // Test direct enrollment query
      final enrollments = await classroomService.getEnrolledClassrooms(null);
      print('🔍 Debug: Found ${enrollments.length} enrollments');

      // Show debug dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enrollment Debug'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enrolled Classrooms: ${enrollments.length}'),
                const SizedBox(height: 8),
                if (enrollments.isEmpty)
                  const Text('No enrollments found in database')
                else
                  ...enrollments.map((e) => Text('• ${e['name']}')),
                const SizedBox(height: 16),
                const Text(
                  'Check console logs for detailed debugging info.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
          ),
        );
      }
    } catch (e) {
      print('🔍 Debug enrollment error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debug error: $e')));
      }
    }
  }
}
