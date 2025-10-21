import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/models/assignment_model.dart';
import 'package:learned_flutter/features/student/providers/assignment_provider.dart';
import 'package:learned_flutter/routes/app_routes.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  bool _isFabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(upcomingAssignmentsProvider);

    return Scaffold(
      body: SafeArea(
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
                  const Text('Failed to load assignments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              if (assignments.isEmpty) {
                return _buildEmptyState();
              }
              return _buildAssignmentsList(assignments, context);
            },
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActions(context),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          FloatingActionButton.extended(
            heroTag: 'assignmentsFilterFab',
            onPressed: () {
              setState(() => _isFabExpanded = false);
              _showFilterDialog(context, ref);
            },
            icon: const Icon(Icons.filter_list),
            label: const Text('Filter'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'assignmentsSubmitFab',
            onPressed: () {
              setState(() => _isFabExpanded = false);
              context.push('/student/assignments/submit');
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Submit Work'),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          heroTag: 'assignmentsMainFab',
          onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
          child: Icon(_isFabExpanded ? Icons.close : Icons.edit),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.0),
            child: Text(
              'You don\'t have any assignments due right now. Check back later!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(List<Assignment> assignments, BuildContext context) {
    // Separate assignments by status
    final pendingAssignments = assignments.where((a) => a.status == 'pending' || a.status == 'late').toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final submittedAssignments = assignments.where((a) => a.status == 'submitted' || a.status == 'graded').toList()
      ..sort((a, b) => b.submittedAt!.compareTo(a.submittedAt!));

    return CustomScrollView(
      slivers: [
        // Pending Assignments Section
        if (pendingAssignments.isNotEmpty)
          ..._buildAssignmentSection(context, 'Pending', pendingAssignments, isPending: true),

        // Submitted/Graded Assignments Section
        if (submittedAssignments.isNotEmpty)
          ..._buildAssignmentSection(context, 'Submitted', submittedAssignments, isPending: false),

        const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
      ],
    );
  }

  List<Widget> _buildAssignmentSection(
    BuildContext context,
    String title,
    List<Assignment> assignments, {
    required bool isPending,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final assignment = assignments[index];
          return _buildAssignmentCard(assignment, context, isPending);
        }, childCount: assignments.length),
      ),
    ];
  }

  Widget _buildAssignmentCard(Assignment assignment, BuildContext context, bool isPending) {
    final isLate = assignment.status == 'late';
    final isGraded = assignment.status == 'graded';
    final isSubmitted = assignment.status == 'submitted';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          // Navigate to assignment details
          context.push('${AppRoutes.studentAssignmentDetails}/${assignment.id}', extra: assignment);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assignment Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(assignment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isGraded ? Icons.grade_outlined : Icons.assignment_outlined,
                      color: _getStatusColor(assignment.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Due: ${_formatDate(assignment.dueDate)} • ${_formatTime(assignment.dueDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isLate ? Colors.red : Colors.grey[600],
                            fontWeight: isLate ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isGraded) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Text(
                        '${assignment.grade}%',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ] else if (isLate) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: const Text(
                        'LATE',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ] else if (isSubmitted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: const Text(
                        'SUBMITTED',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Assignment Description
              Text(
                assignment.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 12),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPending
                      ? () {
                          // Navigate to submit assignment
                          context.push(
                            '${AppRoutes.studentAssignmentDetails}/${assignment.id}/submit',
                            extra: assignment,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending ? AppColors.primary : Colors.grey[300],
                    foregroundColor: isPending ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isPending
                        ? isLate
                              ? 'Submit Late'
                              : 'Submit Assignment'
                        : isGraded
                        ? 'View Feedback'
                        : 'View Details',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'graded':
        return Colors.green;
      case 'late':
        return Colors.red;
      case 'submitted':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return 'Today';
    if (dateToCheck == tomorrow) return 'Tomorrow';

    return '${_getWeekday(date.weekday)}, ${date.day} ${_getMonthName(date.month)}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Assignments'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add filter options here
            const Text('Filter options coming soon!'),
            const SizedBox(height: 16),
            Text(
              'In a future update, you will be able to filter assignments by status, due date, and class.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
