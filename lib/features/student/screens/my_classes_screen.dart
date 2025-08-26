import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/models/class_model.dart';
import 'package:learned_flutter/features/student/providers/class_provider.dart';
import 'package:learned_flutter/routes/app_routes.dart';

class MyClassesScreen extends ConsumerWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingClassesAsync = ref.watch(upcomingClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // Navigate to calendar view
              context.push('${AppRoutes.studentClasses}/calendar');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(upcomingClassesProvider.future),
        child: upcomingClassesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load classes',
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
                  onPressed: () => ref.refresh(upcomingClassesProvider.future),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (classes) {
            if (classes.isEmpty) {
              return _buildEmptyState();
            }
            return _buildClassList(classes, context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to join class screen
          context.push('${AppRoutes.studentClasses}/join');
        },
        icon: const Icon(Icons.add),
        label: const Text('Join Class'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Upcoming Classes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.0),
            child: Text(
              'You don\'t have any classes scheduled yet. Join a class to get started!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to join class screen
              // This will be handled by the parent widget
            },
            icon: const Icon(Icons.add),
            label: const Text('Join a Class'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(List<ClassModel> classes, BuildContext context) {
    // Separate classes into upcoming and past
    final now = DateTime.now();
    final upcomingClasses = classes.where((c) => c.endTime.isAfter(now)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final pastClasses = classes.where((c) => c.endTime.isBefore(now)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return CustomScrollView(
      slivers: [
        // Upcoming Classes Section
        if (upcomingClasses.isNotEmpty) ..._buildClassSection(
          context,
          'Upcoming Classes',
          upcomingClasses,
          isUpcoming: true,
        ),
        
        // Past Classes Section
        if (pastClasses.isNotEmpty) ..._buildClassSection(
          context,
          'Past Classes',
          pastClasses,
          isUpcoming: false,
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
      ],
    );
  }

  List<Widget> _buildClassSection(
    BuildContext context,
    String title,
    List<ClassModel> classes, {
    required bool isUpcoming,
  }) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final classItem = classes[index];
            return _buildClassCard(context, classItem, isUpcoming);
          },
          childCount: classes.length,
        ),
      ),
    ];
  }

  Widget _buildClassCard(
    BuildContext context,
    ClassModel classItem,
    bool isUpcoming,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () {
          // Navigate to class details
          context.push(
            '${AppRoutes.studentClassDetails}/${classItem.id}',
            extra: classItem,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classItem.subject,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'With ${classItem.teacherName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (classItem.isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Class Details
              Row(
                children: [
                  _buildDetailChip(
                    Icons.topic_outlined,
                    classItem.topic,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    Icons.access_time,
                    '${_formatTime(classItem.startTime)} - ${_formatTime(classItem.endTime)}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Class Date
              Text(
                _formatDate(classItem.startTime),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              
              // Action Button
              if (isUpcoming) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: classItem.isLive
                        ? () {
                            // Join live class
                            context.push(
                              '${AppRoutes.studentSessionJoin}/${classItem.id}',
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: classItem.isLive
                          ? AppColors.primary
                          : Colors.grey[300],
                      foregroundColor: classItem.isLive ? Colors.white : null,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (classItem.isLive) ...[
                          const Icon(Icons.videocam_outlined, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          classItem.isLive
                              ? 'Join Now'
                              : 'Starts at ${_formatTime(classItem.startTime)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),              
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return 'Today';
    if (dateToCheck == tomorrow) return 'Tomorrow';

    return '${_getWeekday(date.weekday)}, ${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
