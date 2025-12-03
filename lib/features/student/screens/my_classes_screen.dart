import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/services/classroom_service.dart';

// Provider for enrolled classrooms
final enrolledClassroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final classroomService = ClassroomService();
  final classrooms = await classroomService.getEnrolledClassrooms(null);
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
                      ref.invalidate(enrolledClassroomsProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (classrooms) {
              if (classrooms.isEmpty) {
                return _buildEmptyState(context);
              }
              return CustomScrollView(slivers: _buildClassroomList(context, classrooms));
            },
          ),
        ), // Close SafeArea
      ), // Close RefreshIndicator
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/classrooms');
        },
        icon: const Icon(Icons.explore),
        label: const Text('Enroll'),
        backgroundColor: AppColors.primary,
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
                        label: const Text('Enroll'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {
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
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final classroom = classrooms[index];
            return _buildClassroomCard(context, classroom);
          }, childCount: classrooms.length),
        ),
      ),
    ];
  }

  Widget _buildClassroomCard(BuildContext context, Map<String, dynamic> classroom) {
    final enrollmentDate = DateTime.tryParse(classroom['enrollment_date'] ?? '');
    final nextSession = DateTime.tryParse(classroom['next_session'] ?? '');
    final progress = (classroom['progress'] as num?)?.toDouble() ?? 0.0;
    final description = classroom['description'] as String?;
    final assignmentCount = classroom['assignment_count'] as int? ?? 0;
    final materialsCount = classroom['materials_count'] as int? ?? 0;
    final sessionsCount = classroom['sessions_count'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to classroom home for enrolled students
          context.push('/classroom-home/${classroom['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row - Similar to teacher's design
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.school, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroom['name'] ?? 'Unknown Classroom',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${classroom['subject']} • Grade ${classroom['grade_level']} • ${classroom['board'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),

              // Description (if available)
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Teacher info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    classroom['teacher_name'] ?? 'Teacher Info Unavailable',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  if (enrollmentDate != null) ...[
                    const Spacer(),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Enrolled ${_formatDate(enrollmentDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),

              if (progress > 0) ...[
                const SizedBox(height: 16),
                // Progress bar - Similar to enrollment progress in teacher's design
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Course Progress',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 0.9
                            ? Colors.green
                            : progress >= 0.5
                            ? AppColors.primary
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Stats row - Similar to teacher's quick stats
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStat(icon: Icons.assignment, count: assignmentCount, label: 'Assignments'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStat(icon: Icons.folder, count: materialsCount, label: 'Materials'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStat(icon: Icons.event, count: sessionsCount, label: 'Sessions'),
                  ),
                ],
              ),

              // Next session info (if available)
              if (nextSession != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.video_call, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Session',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                            ),
                            const SizedBox(height: 2),
                            Text(_formatDateTime(nextSession), style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat({required IconData icon, required int count, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
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
}
