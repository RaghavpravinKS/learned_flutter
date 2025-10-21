import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';
import 'package:learned_flutter/features/student/providers/assignment_provider.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';

class ClassroomHomeScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomHomeScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroomAsync = ref.watch(classroomDetailsProvider(classroomId));

    return Scaffold(
      body: classroomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading classroom: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(classroomDetailsProvider(classroomId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (classroom) => _buildClassroomHome(context, ref, classroom),
      ),
    );
  }

  Widget _buildClassroomHome(BuildContext context, WidgetRef ref, Map<String, dynamic> classroom) {
    final theme = Theme.of(context);
    final teacherName = classroom['teacher_name'] ?? 'Unknown Teacher';

    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40), // Account for app bar
                  Icon(Icons.school, size: 48, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(height: 8),
                  Text(
                    '${classroom['subject']} • Grade ${classroom['grade_level']}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                  ),
                  Text('with $teacherName', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => context.push('/classroom-details/$classroomId'),
              tooltip: 'View Details',
            ),
          ],
        ),

        // Main Content
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.waving_hand, color: Colors.amber.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Welcome back!',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to continue your learning journey in ${classroom['name']}?',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Next Session / Meeting Link
              _buildNextSessionCard(context, ref),

              const SizedBox(height: 16),

              // Assignments Card
              _buildAssignmentsCard(context, ref),

              const SizedBox(height: 16),

              // Attendance Card
              _buildAttendanceCard(context, ref),

              const SizedBox(height: 16),

              // Recent Activity
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Activity',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildActivityItem(
                        context,
                        icon: Icons.check_circle,
                        title: 'Completed: Introduction to Algebra',
                        time: '2 hours ago',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildActivityItem(
                        context,
                        icon: Icons.assignment_turned_in,
                        title: 'Submitted: Practice Problems Set 1',
                        time: '1 day ago',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildActivityItem(
                        context,
                        icon: Icons.star,
                        title: 'Earned badge: Quick Learner',
                        time: '3 days ago',
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 80), // Bottom padding
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildNextSessionCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nextSessionAsync = ref.watch(nextClassroomSessionProvider(classroomId));

    return nextSessionAsync.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.video_call, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text('Next Session', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.video_call, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text('Next Session', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
                    const SizedBox(height: 8),
                    Text('Unable to load session information', style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      data: (session) {
        if (session == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.video_call, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text('Next Session', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No upcoming sessions scheduled',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final meetingUrl = session['meeting_url'] as String?;
        final sessionDate = DateTime.parse(session['session_date'] as String);
        final startTime = session['start_time'] as String;
        final title = session['title'] as String;

        return Card(
          elevation: 3,
          color: AppColors.primary.withOpacity(0.05),
          child: InkWell(
            onTap: meetingUrl != null && meetingUrl.isNotEmpty ? () => _launchMeetingUrl(context, meetingUrl) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.video_call, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Session',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        _formatSessionDate(sessionDate),
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(startTime, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    ],
                  ),
                  if (meetingUrl != null && meetingUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchMeetingUrl(context, meetingUrl),
                            icon: const Icon(Icons.video_camera_front, size: 20),
                            label: const Text('Join Meeting'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final assignmentsAsync = ref.watch(classroomAssignmentsProvider(classroomId));

    return assignmentsAsync.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text('Assignments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text('Assignments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
                    const SizedBox(height: 8),
                    Text('Failed to load assignments', style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      data: (assignments) {
        final pendingCount = assignments.where((a) => a.status == 'pending' || a.status == 'late').length;
        final submittedCount = assignments.where((a) => a.status == 'submitted').length;
        final gradedCount = assignments.where((a) => a.status == 'graded').length;

        return Card(
          child: InkWell(
            onTap: () {
              // Navigate to classroom assignments screen
              final classroomAsync = ref.read(classroomDetailsProvider(classroomId));
              classroomAsync.whenData((classroom) {
                context.push('/classroom-assignments/$classroomId', extra: {'classroomName': classroom['name']});
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text('Assignments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                  if (assignments.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'No assignments yet',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAssignmentStat(
                            context,
                            count: pendingCount,
                            label: 'Pending',
                            color: Colors.orange,
                            icon: Icons.pending_actions,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAssignmentStat(
                            context,
                            count: submittedCount,
                            label: 'Submitted',
                            color: Colors.blue,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAssignmentStat(
                            context,
                            count: gradedCount,
                            label: 'Graded',
                            color: Colors.green,
                            icon: Icons.grade,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentStat(
    BuildContext context, {
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(classroomAttendanceProvider(classroomId));

    return attendanceAsync.when(
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Attendance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Attendance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Unable to load attendance data', style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
          ),
        ),
      ),
      data: (stats) {
        final totalSessions = stats['totalSessions'] as int;
        final attended = stats['attended'] as int;
        final absent = stats['absent'] as int;
        final late = stats['late'] as int;
        final excused = stats['excused'] as int;
        final attendanceRate = stats['attendanceRate'] as double;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Attendance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                if (totalSessions == 0) ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No sessions yet', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ] else ...[
                  // Attendance Rate Progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: attendanceRate / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                attendanceRate >= 75
                                    ? Colors.green
                                    : attendanceRate >= 50
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${attendanceRate.toStringAsFixed(1)}% Attendance',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: attendanceRate >= 75
                                        ? Colors.green
                                        : attendanceRate >= 50
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                ),
                                Text(
                                  '$attended of $totalSessions sessions',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Attendance Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceStat(
                          context,
                          icon: Icons.check_circle,
                          label: 'Present',
                          value: attended.toString(),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceStat(
                          context,
                          icon: Icons.cancel,
                          label: 'Absent',
                          value: absent.toString(),
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceStat(
                          context,
                          icon: Icons.access_time,
                          label: 'Late',
                          value: late.toString(),
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceStat(
                          context,
                          icon: Icons.event_available,
                          label: 'Excused',
                          value: excused.toString(),
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    final difference = sessionDay.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'in $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _launchMeetingUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open meeting link')));
      }
    }
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}
