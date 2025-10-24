import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/models/assignment_model.dart';
import 'package:learned_flutter/features/student/providers/assignment_provider.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  String? _selectedClassroomId;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(upcomingAssignmentsProvider);
    final classroomsAsync = ref.watch(enrolledClassroomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter by Classroom Dropdown
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Filter by Classroom', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                classroomsAsync.when(
                  loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const Text('Error loading classrooms'),
                  data: (classrooms) {
                    return DropdownButtonFormField<String?>(
                      value: _selectedClassroomId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Classrooms')),
                        ...classrooms.map((classroom) {
                          return DropdownMenuItem<String?>(
                            value: classroom['id'] as String,
                            child: Text(classroom['name'] as String, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClassroomId = value;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Assignments List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(upcomingAssignmentsProvider.future),
              child: assignmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load assignments',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(upcomingAssignmentsProvider.future),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (assignments) {
                  // Filter assignments by selected classroom
                  final filteredAssignments = _selectedClassroomId == null
                      ? assignments
                      : assignments.where((a) => a.classId == _selectedClassroomId).toList();

                  if (filteredAssignments.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildAssignmentsList(filteredAssignments, context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Assignments Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text('New assignments will appear here', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(List<Assignment> assignments, BuildContext context) {
    // Group assignments by status
    final pending = assignments.where((a) => a.status == 'pending').toList();
    final submitted = assignments.where((a) => a.status == 'submitted').toList();
    final graded = assignments.where((a) => a.status == 'graded').toList();
    final late = assignments.where((a) => a.status == 'late').toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (pending.isNotEmpty) ...[
          _buildSectionHeader('Pending', pending.length, Colors.orange),
          const SizedBox(height: 8),
          ...pending.map((assignment) => _buildAssignmentCard(assignment, context)),
          const SizedBox(height: 16),
        ],
        if (late.isNotEmpty) ...[
          _buildSectionHeader('Overdue', late.length, Colors.red),
          const SizedBox(height: 8),
          ...late.map((assignment) => _buildAssignmentCard(assignment, context)),
          const SizedBox(height: 16),
        ],
        if (submitted.isNotEmpty) ...[
          _buildSectionHeader('Submitted', submitted.length, Colors.blue),
          const SizedBox(height: 8),
          ...submitted.map((assignment) => _buildAssignmentCard(assignment, context)),
          const SizedBox(height: 16),
        ],
        if (graded.isNotEmpty) ...[
          _buildSectionHeader('Graded', graded.length, Colors.green),
          const SizedBox(height: 8),
          ...graded.map((assignment) => _buildAssignmentCard(assignment, context)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(
            count.toString(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(Assignment assignment, BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dueDate = assignment.dueDate;
    final isOverdue =
        dueDate != null && dueDate.isBefore(now) && assignment.status != 'submitted' && assignment.status != 'graded';
    final daysUntilDue = dueDate?.difference(now).inDays ?? 0;

    Color statusColor;
    IconData statusIcon;
    switch (assignment.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case 'late':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      case 'submitted':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'graded':
        statusColor = Colors.green;
        statusIcon = Icons.grade;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.assignment;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to assignment detail
          context.push('/student/assignments/${assignment.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (assignment.className != null) ...[
                          Text(
                            '${assignment.className}${assignment.teacherName != null ? " • ${assignment.teacherName}" : ""}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (assignment.status == 'graded' && assignment.grade != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${assignment.grade?.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ],
              ),
              if (assignment.description != null && assignment.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  assignment.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDueDate(dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  ] else if (daysUntilDue <= 2 && daysUntilDue >= 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        daysUntilDue == 0 ? 'TODAY' : 'DUE SOON',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ),
                  ],
                  if (assignment.submittedAt != null) ...[
                    const Spacer(),
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7 && difference.inDays > 0) {
      return 'in ${difference.inDays} days';
    } else if (difference.inDays < 0) {
      return '${difference.inDays.abs()} days ago';
    } else {
      return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }
}
