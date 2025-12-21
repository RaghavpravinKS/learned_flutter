import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// Provider to fetch recent activities
final recentActivitiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  try {
    // Get student ID
    final studentResponse = await supabase.from('students').select('id').eq('user_id', userId).maybeSingle();

    if (studentResponse == null) {
      return [];
    }

    final studentId = studentResponse['id'] as String;

    // Get enrolled classroom IDs
    final enrollmentsResponse = await supabase
        .from('student_enrollments')
        .select('classroom_id')
        .eq('student_id', studentId);

    if (enrollmentsResponse.isEmpty) {
      return [];
    }

    final classroomIds = (enrollmentsResponse as List).map((item) => item['classroom_id'] as String).toList();

    final activities = <Map<String, dynamic>>[];

    // 1. Get recent graded assignments
    final gradedAssignmentsResponse = await supabase
        .from('student_assignment_attempts')
        .select('''
          id,
          assignment_id,
          grade,
          graded_at,
          assignments!inner(title, classroom_id)
        ''')
        .eq('student_id', studentId)
        .not('grade', 'is', null)
        .inFilter('assignments.classroom_id', classroomIds)
        .order('graded_at', ascending: false)
        .limit(3);

    for (final attempt in gradedAssignmentsResponse as List) {
      final assignment = attempt['assignments'] as Map<String, dynamic>;
      activities.add({
        'type': 'assignment_graded',
        'icon': Icons.grade,
        'color': Colors.green,
        'title': 'Assignment Graded',
        'description': '${assignment['title']} - Score: ${attempt['grade']?.toStringAsFixed(1)}%',
        'timestamp': DateTime.parse(attempt['graded_at'] as String),
      });
    }

    // 2. Get recent learning materials
    final materialsResponse = await supabase
        .from('learning_materials')
        .select('id, title, upload_date')
        .inFilter('classroom_id', classroomIds)
        .order('upload_date', ascending: false)
        .limit(3);

    for (final material in materialsResponse as List) {
      activities.add({
        'type': 'new_material',
        'icon': Icons.file_present,
        'color': Colors.blue,
        'title': 'New Material Uploaded',
        'description': material['title'] as String,
        'timestamp': DateTime.parse(material['upload_date'] as String),
      });
    }

    // 3. Get recent assignments (not yet submitted)
    final recentAssignmentsResponse = await supabase
        .from('assignments')
        .select('id, title, created_at')
        .inFilter('classroom_id', classroomIds)
        .order('created_at', ascending: false)
        .limit(3);

    for (final assignment in recentAssignmentsResponse as List) {
      activities.add({
        'type': 'new_assignment',
        'icon': Icons.assignment,
        'color': Colors.red,
        'title': 'New Assignment',
        'description': assignment['title'] as String,
        'timestamp': DateTime.parse(assignment['created_at'] as String),
      });
    }

    // Sort all activities by timestamp
    activities.sort((a, b) {
      final timeA = a['timestamp'] as DateTime;
      final timeB = b['timestamp'] as DateTime;
      return timeB.compareTo(timeA);
    });

    // Return top 5 most recent activities
    return activities.take(5).toList();
  } catch (e) {
    return [];
  }
});

class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(recentActivitiesProvider);

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
        activitiesAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return _buildEmptyState();
            }
            return Column(
              children: activities.map((activity) {
                return _buildActivityCard(
                  icon: activity['icon'] as IconData,
                  iconColor: activity['color'] as Color,
                  title: activity['title'] as String,
                  description: activity['description'] as String,
                  timestamp: activity['timestamp'] as DateTime,
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()),
          ),
          error: (error, stack) => _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.grey.shade600, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No recent activity',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your recent activities will appear here',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required DateTime timestamp,
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
                Text(timeago.format(timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }
}
