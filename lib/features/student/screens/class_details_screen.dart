import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/models/class_model.dart';
import 'package:learned_flutter/features/student/providers/class_provider.dart';
import 'package:learned_flutter/routes/app_routes.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ClassDetailsScreen extends ConsumerWidget {
  final String classId;
  final ClassModel? initialClassData;
  
  const ClassDetailsScreen({
    super.key,
    required this.classId,
    this.initialClassData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If we have initial data, use it, otherwise fetch from the provider
    final classAsync = initialClassData != null
        ? AsyncValue.data(initialClassData!)
        : ref.watch(classDetailsProvider(classId));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Class Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          classAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load class details',
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
                      onPressed: () => ref.refresh(classDetailsProvider(classId).future),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (classData) => _buildClassDetails(classData, context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDetails(ClassModel classData, BuildContext context, WidgetRef ref) {
    final isUpcoming = classData.startTime.isAfter(DateTime.now());
    final isLive = classData.isLive;
    final canJoin = isUpcoming || isLive;

    return SliverList(
      delegate: SliverChildListDelegate([
        // Class Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Title
              Text(
                classData.subject,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'With ${classData.teacherName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              
              // Class Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(isLive, isUpcoming).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(isLive, isUpcoming).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(isLive, isUpcoming),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(isLive, isUpcoming),
                      style: TextStyle(
                        color: _getStatusColor(isLive, isUpcoming),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Class Details Grid
              _buildDetailsGrid(classData, context),
              const SizedBox(height: 24),
              
              // Join Button (if applicable)
              if (canJoin)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLive
                        ? () => _joinClass(context, classData.id)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? AppColors.primary : Colors.grey[300],
                      foregroundColor: isLive ? Colors.white : null,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLive ? 'Join Now' : 'Starts at ${_formatTime(classData.startTime)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Tabs for different sections
        DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'About'),
                  Tab(text: 'Materials'),
                  Tab(text: 'Assignments'),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    // About Tab
                    _buildAboutTab(classData, context),
                    // Materials Tab
                    _buildMaterialsTab(),
                    // Assignments Tab
                    _buildAssignmentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDetailsGrid(ClassModel classData, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!), 
      ),
      child: Column(
        children: [
          // Date and Time
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'Date',
            _formatDate(classData.startTime),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.access_time_outlined,
            'Time',
            '${_formatTime(classData.startTime)} - ${_formatTime(classData.endTime)}',
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.video_call_outlined,
            'Platform',
            'Zoom Meeting',
            showButton: true,
            onTap: () => _launchUrl('https://zoom.us/join'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value,
      {bool showButton = false, VoidCallback? onTap}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (showButton && onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('Launch'),
          ),
      ],
    );
  }

  Widget _buildAboutTab(ClassModel classData, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Class',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            classData.topic.isNotEmpty
                ? classData.topic
                : 'No additional information available for this class.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Learning Objectives',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildObjectiveItem('Understand key concepts of ${classData.subject}'),
          _buildObjectiveItem('Complete practice exercises'),
          _buildObjectiveItem('Get your questions answered'),
        ],
      ),
    );
  }

  Widget _buildObjectiveItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, 
              size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, 
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No materials available yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for class materials',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, 
              size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No assignments yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your teacher will post assignments here',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              // Navigate to all assignments
              // context.push(AppRoutes.studentAssignments);
            },
            child: const Text('View All Assignments'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isLive, bool isUpcoming) {
    if (isLive) return Colors.red;
    if (isUpcoming) return Colors.blue;
    return Colors.grey;
  }

  String _getStatusText(bool isLive, bool isUpcoming) {
    if (isLive) return 'Live Now';
    if (isUpcoming) return 'Upcoming';
    return 'Completed';
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

  Future<void> _joinClass(BuildContext context, String classId) async {
    // In a real app, this would navigate to the video call screen
    // For now, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Class'),
        content: const Text('You are about to join the class session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to the active session screen
              context.push('${AppRoutes.studentSessionActive}/$classId');
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }
}
