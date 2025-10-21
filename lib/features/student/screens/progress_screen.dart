import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';
import 'package:learned_flutter/features/student/providers/assignment_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledClassroomsAsync = ref.watch(enrolledClassroomsProvider);

    return enrolledClassroomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading progress: $error'),
          ],
        ),
      ),
      data: (classrooms) {
        if (classrooms.isEmpty) {
          return _buildEmptyState();
        }
        return _buildProgressList(context, ref, classrooms);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Classrooms Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text('Enroll in classrooms to track your progress', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildProgressList(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> classrooms) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: classrooms.length,
      itemBuilder: (context, index) {
        final classroom = classrooms[index];
        final classroomId = classroom['id'] as String;
        final classroomName = classroom['name'] as String;
        final subject = classroom['subject'] as String? ?? '';
        final gradeLevel = (classroom['grade_level'] as int?)?.toString() ?? '';

        return _buildClassroomProgressCard(context, ref, classroomId, classroomName, subject, gradeLevel);
      },
    );
  }

  Widget _buildClassroomProgressCard(
    BuildContext context,
    WidgetRef ref,
    String classroomId,
    String classroomName,
    String subject,
    String gradeLevel,
  ) {
    final theme = Theme.of(context);
    final attendanceAsync = ref.watch(classroomAttendanceProvider(classroomId));
    final assignmentsAsync = ref.watch(classroomAssignmentsProvider(classroomId));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/classroom-home/$classroomId'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Classroom Header
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(classroomName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '$subject • Grade $gradeLevel',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Attendance Section
              _buildAttendanceSection(theme, attendanceAsync),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Grades Section
              _buildGradesSection(theme, assignmentsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSection(ThemeData theme, AsyncValue<Map<String, dynamic>> attendanceAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Attendance', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        attendanceAsync.when(
          loading: () => const Center(child: SizedBox(height: 40, child: CircularProgressIndicator())),
          error: (error, stack) =>
              Text('Unable to load attendance', style: TextStyle(color: Colors.red.shade600, fontSize: 12)),
          data: (stats) {
            final totalSessions = stats['totalSessions'] as int;
            final attended = stats['attended'] as int;
            final attendanceRate = stats['attendanceRate'] as double;

            if (totalSessions == 0) {
              return Text('No sessions yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 12));
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
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
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${attendanceRate.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: attendanceRate >= 75
                            ? Colors.green
                            : attendanceRate >= 50
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$attended of $totalSessions sessions attended',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    Row(
                      children: [
                        Icon(
                          attendanceRate >= 75 ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: attendanceRate >= 75 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          attendanceRate >= 75 ? 'Good' : 'Needs Improvement',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: attendanceRate >= 75 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGradesSection(ThemeData theme, AsyncValue<List> assignmentsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grade, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Grades', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        assignmentsAsync.when(
          loading: () => const Center(child: SizedBox(height: 40, child: CircularProgressIndicator())),
          error: (error, stack) =>
              Text('Unable to load grades', style: TextStyle(color: Colors.red.shade600, fontSize: 12)),
          data: (assignments) {
            final gradedAssignments = assignments.where((a) => a.status == 'graded' && a.grade != null).toList();

            if (gradedAssignments.isEmpty) {
              return Text('No graded assignments yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 12));
            }

            // Calculate average grade
            final totalGrade = gradedAssignments.fold<double>(0, (sum, a) => sum + (a.grade ?? 0));
            final averageGrade = totalGrade / gradedAssignments.length;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Average Grade', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                          '${averageGrade.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(averageGrade),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Graded Assignments', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(
                          '${gradedAssignments.length}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Grade distribution
                Row(
                  children: [
                    Expanded(
                      child: _buildGradeIndicator(
                        'A',
                        gradedAssignments.where((a) => (a.grade ?? 0) >= 90).length,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGradeIndicator(
                        'B',
                        gradedAssignments.where((a) => (a.grade ?? 0) >= 80 && (a.grade ?? 0) < 90).length,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGradeIndicator(
                        'C',
                        gradedAssignments.where((a) => (a.grade ?? 0) >= 70 && (a.grade ?? 0) < 80).length,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGradeIndicator(
                        'D/F',
                        gradedAssignments.where((a) => (a.grade ?? 0) < 70).length,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGradeIndicator(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) return Colors.green;
    if (grade >= 80) return Colors.blue;
    if (grade >= 70) return Colors.orange;
    return Colors.red;
  }
}

// Provider for enrolled classrooms
final enrolledClassroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Get student record
  final studentResponse = await supabase.from('students').select('id').eq('user_id', userId).single();

  final studentId = studentResponse['id'] as String;

  // Get enrolled classrooms
  final enrollmentsResponse = await supabase
      .from('student_enrollments')
      .select('classroom_id, classrooms(id, name, subject, grade_level)')
      .eq('student_id', studentId)
      .eq('status', 'active');

  final enrollments = enrollmentsResponse as List;
  return enrollments.map((e) => e['classrooms'] as Map<String, dynamic>).toList();
});
