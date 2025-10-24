import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:learned_flutter/features/student/models/assignment_model.dart';
import 'package:learned_flutter/features/student/providers/assignment_provider.dart';

class AssignmentsSection extends ConsumerWidget {
  const AssignmentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(upcomingAssignmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.go('/student/assignments'), child: const Text('View All')),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: assignmentsAsync.when(
            data: (assignments) {
              if (assignments.isEmpty) {
                return const Center(child: Text('No upcoming assignments'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment = assignments[index];
                  return _buildAssignmentCard(context, assignment);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading assignments: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment) {
    final dueDate = assignment.dueDate != null ? DateFormat('MMM d, y').format(assignment.dueDate!) : 'No due date';
    final daysLeft = assignment.dueDate?.difference(DateTime.now()).inDays ?? 0;

    Color statusColor = Colors.orange;
    String statusText = assignment.dueDate == null ? 'No deadline' : 'Due in $daysLeft days';

    if (assignment.dueDate != null) {
      if (daysLeft == 0) {
        statusText = 'Due today';
        statusColor = Colors.red;
      } else if (daysLeft < 0) {
        statusText = 'Overdue by ${-daysLeft} days';
        statusColor = Colors.red;
      } else if (daysLeft == 1) {
        statusText = 'Due tomorrow';
        statusColor = Colors.orange;
      }
    }

    if (assignment.status == 'submitted') {
      statusText = 'Submitted';
      statusColor = Colors.green;
    } else if (assignment.status == 'graded') {
      statusText = 'Graded: ${assignment.grade}%';
      statusColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to assignment details
        context.go('/student/assignments/${assignment.id}');
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              assignment.description ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Due: $dueDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
