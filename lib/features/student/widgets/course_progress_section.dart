import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CourseProgressSection extends ConsumerWidget {
  const CourseProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
        ),
        const SizedBox(height: 12),
        _buildPlaceholderActivityList(context),
      ],
    );
  }

  // TODO: Replace this placeholder with actual recent activity feed
  // Display new updates here like:
  // - Marks for an assignment (e.g., "Assignment 'Chapter 5 Quiz' graded: 85%")
  // - New post in classroom (e.g., "Teacher posted in 'Physics Class': Exam schedule updated")
  // - New material uploaded (e.g., "New study material: 'Trigonometry Notes.pdf'")
  // - New assignment added (e.g., "New assignment due Oct 25: 'Chemistry Lab Report'")
  // - Upcoming class reminders
  // - Feedback from teachers
  Widget _buildPlaceholderActivityList(BuildContext context) {
    // Placeholder activity items for demonstration
    final placeholderActivities = [
      {
        'type': 'assignment_graded',
        'icon': Icons.grade,
        'color': Colors.green,
        'title': 'Assignment Graded',
        'description': 'Chapter 5 Quiz - Score: 85%',
        'time': '2 hours ago',
      },
      {
        'type': 'new_material',
        'icon': Icons.file_present,
        'color': Colors.blue,
        'title': 'New Material Uploaded',
        'description': 'Trigonometry Notes.pdf',
        'time': '5 hours ago',
      },
      {
        'type': 'classroom_post',
        'icon': Icons.announcement,
        'color': Colors.orange,
        'title': 'Classroom Update',
        'description': 'Physics: Exam schedule updated',
        'time': '1 day ago',
      },
      {
        'type': 'new_assignment',
        'icon': Icons.assignment,
        'color': Colors.red,
        'title': 'New Assignment',
        'description': 'Chemistry Lab Report - Due Oct 25',
        'time': '2 days ago',
      },
    ];

    return Column(
      children: [
        for (var activity in placeholderActivities)
          _buildActivityCard(
            icon: activity['icon'] as IconData,
            iconColor: activity['color'] as Color,
            title: activity['title'] as String,
            description: activity['description'] as String,
            time: activity['time'] as String,
          ),
      ],
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8.0)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }
}
