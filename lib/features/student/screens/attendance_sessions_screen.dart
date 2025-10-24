import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';

class AttendanceSessionsScreen extends ConsumerWidget {
  final String classroomId;
  final String classroomName;
  final String status;

  const AttendanceSessionsScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsByAttendanceStatusProvider((classroomId: classroomId, status: status)));

    final theme = Theme.of(context);

    // Get status display info
    final statusInfo = _getStatusInfo(status);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${statusInfo['label']} Sessions', style: const TextStyle(fontSize: 18)),
            Text(classroomName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: statusInfo['color'] as Color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(sessionsByAttendanceStatusProvider((classroomId: classroomId, status: status)).future),
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Failed to load sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(
                    sessionsByAttendanceStatusProvider((classroomId: classroomId, status: status)).future,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return _buildEmptyState(statusInfo);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return _buildSessionCard(context, sessions[index], statusInfo, theme);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(Map<String, dynamic> statusInfo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusInfo['icon'] as IconData, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No ${statusInfo['label']} Sessions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text('You have no sessions marked as ${status}', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    Map<String, dynamic> session,
    Map<String, dynamic> statusInfo,
    ThemeData theme,
  ) {
    final sessionDate = DateTime.parse(session['session_date'] as String);
    final startTime = session['start_time'] as String;
    final endTime = session['end_time'] as String;
    final title = session['title'] as String? ?? 'No title';
    final description = session['description'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: (statusInfo['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusInfo['icon'] as IconData, color: statusInfo['color'] as Color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(sessionDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('$startTime - $endTime', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (statusInfo['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusInfo['label'] as String,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusInfo['color'] as Color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'present':
        return {'label': 'Present', 'icon': Icons.check_circle, 'color': Colors.green};
      case 'absent':
        return {'label': 'Absent', 'icon': Icons.cancel, 'color': Colors.red};
      case 'late':
        return {'label': 'Late', 'icon': Icons.access_time, 'color': Colors.orange};
      case 'excused':
        return {'label': 'Excused', 'icon': Icons.event_available, 'color': Colors.blue};
      default:
        return {'label': 'Unknown', 'icon': Icons.help_outline, 'color': Colors.grey};
    }
  }
}
