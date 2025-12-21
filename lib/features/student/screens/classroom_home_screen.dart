import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';
import 'package:learned_flutter/features/student/providers/assignment_provider.dart';
import 'package:learned_flutter/features/student/providers/learning_materials_provider.dart';
import 'package:learned_flutter/features/teacher/models/learning_material_model.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'classroom_materials_screen.dart';
import 'attendance_sessions_screen.dart';

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

              // Learning Materials
              _buildLearningMaterialsCard(context, ref),

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
          elevation: 2,
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
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                    Text(_formatSessionDate(sessionDate), style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(startTime, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ),
                if (meetingUrl != null && meetingUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchMeetingUrl(context, meetingUrl),
                      icon: const Icon(Icons.video_camera_front, size: 20),
                      label: const Text('Join Meeting'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
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
                          ref: ref,
                          icon: Icons.check_circle,
                          label: 'Present',
                          value: attended.toString(),
                          color: Colors.green,
                          status: 'present',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceStat(
                          context,
                          ref: ref,
                          icon: Icons.cancel,
                          label: 'Absent',
                          value: absent.toString(),
                          color: Colors.red,
                          status: 'absent',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceStat(
                          context,
                          ref: ref,
                          icon: Icons.access_time,
                          label: 'Late',
                          value: late.toString(),
                          color: Colors.orange,
                          status: 'late',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceStat(
                          context,
                          ref: ref,
                          icon: Icons.event_available,
                          label: 'Excused',
                          value: excused.toString(),
                          color: Colors.blue,
                          status: 'excused',
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
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String status,
  }) {
    final classroomAsync = ref.watch(classroomDetailsProvider(classroomId));
    final classroomName = classroomAsync.value?['name'] ?? 'Classroom';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AttendanceSessionsScreen(classroomId: classroomId, classroomName: classroomName, status: status),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
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

  Widget _buildLearningMaterialsCard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final materialsAsync = ref.watch(recentClassroomMaterialsProvider(classroomId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_open, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Learning Materials',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    final classroomAsync = ref.read(classroomDetailsProvider(classroomId));
                    final classroomName = classroomAsync.value?['name'] ?? 'Classroom';
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ClassroomMaterialsScreen(classroomId: classroomId, classroomName: classroomName),
                      ),
                    );
                  },
                  child: Text('View All', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            materialsAsync.when(
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 32, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Failed to load materials', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              data: (materials) {
                if (materials.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'No learning materials yet',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: materials
                      .map(
                        (material) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildMaterialItem(context, material: material),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMaterialIcon(LearningMaterialModel material) {
    // Check material type from database
    switch (material.materialType.toLowerCase()) {
      case 'document':
        if (material.isPDF) {
          return Icons.picture_as_pdf;
        }
        return Icons.description;
      case 'video':
        return Icons.videocam;
      case 'presentation':
        return Icons.slideshow;
      case 'recording':
        return Icons.mic;
      case 'note':
        return Icons.note;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildMaterialItem(BuildContext context, {required LearningMaterialModel material}) {
    final daysDiff = DateTime.now().difference(material.uploadDate).inDays;
    final timeAgo = daysDiff == 0
        ? 'Today'
        : daysDiff == 1
        ? 'Yesterday'
        : '$daysDiff days ago';

    return InkWell(
      onTap: () => _viewMaterial(context, material),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getMaterialIcon(material), size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$timeAgo • ${material.fileSizeDisplay}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: AppColors.primary),
              onSelected: (value) async {
                if (value == 'view') {
                  await _viewMaterial(context, material);
                } else if (value == 'download') {
                  await _downloadMaterial(context, material);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(children: [Icon(Icons.visibility, size: 20), SizedBox(width: 12), Text('View')]),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(children: [Icon(Icons.download, size: 20), SizedBox(width: 12), Text('Download')]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewMaterial(BuildContext context, LearningMaterialModel material) async {
    if (material.fileUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File URL not available')));
      }
      return;
    }

    try {

      // Extract the file path from the stored URL
      // The URL might be in format: https://[project].supabase.co/storage/v1/object/public/learning-materials/[path]
      // We need to extract the path after 'learning-materials/'
      String? filePath;
      final storedUrl = material.fileUrl!;

      if (storedUrl.contains('learning-materials/')) {
        filePath = storedUrl.split('learning-materials/').last;
      } else {
        filePath = null;
      }

      Uri uri;

      // If we extracted a file path, create a signed URL for better security and reliability
      if (filePath != null) {
        try {
          final supabase = Supabase.instance.client;
          // Create a signed URL that expires in 1 hour
          final signedUrl = await supabase.storage
              .from('learning-materials')
              .createSignedUrl(filePath, 3600); // 1 hour expiry

          uri = Uri.parse(signedUrl);
        } catch (e) {
          uri = Uri.parse(storedUrl);
        }
      } else {
        uri = Uri.parse(storedUrl);
      }

      // Use inAppBrowserView mode to open in app (works well for PDFs, images, videos)
      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

      if (!launched) {
        // Try external application as fallback
        final launchedExternal = await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (!launchedExternal && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file')));
        }
      } else {
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  Future<void> _downloadMaterial(BuildContext context, LearningMaterialModel material) async {
    if (material.fileUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File URL not available')));
      }
      return;
    }

    try {

      // Extract the file path from the stored URL
      String? filePath;
      final storedUrl = material.fileUrl!;

      if (storedUrl.contains('learning-materials/')) {
        filePath = storedUrl.split('learning-materials/').last;
      } else {
        filePath = null;
      }

      Uri uri;

      // If we extracted a file path, create a signed URL
      if (filePath != null) {
        try {
          final supabase = Supabase.instance.client;
          final signedUrl = await supabase.storage.from('learning-materials').createSignedUrl(filePath, 3600);

          uri = Uri.parse(signedUrl);
        } catch (e) {
          uri = Uri.parse(storedUrl);
        }
      } else {
        uri = Uri.parse(storedUrl);
      }

      // Open in external application/browser which will trigger download
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading ${material.title}...')));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start download')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading file: $e')));
      }
    }
  }
}
