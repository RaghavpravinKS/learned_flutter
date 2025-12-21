import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../services/teacher_service.dart';
import 'my_classrooms_screen.dart';
import 'assignment_management_screen.dart';
import 'materials_management_screen.dart';
import 'teacher_profile_screen.dart';
import 'classroom_detail_screen.dart';

enum TeacherDrawerSection { dashboard, profile, analytics, settings, help }

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  final TeacherService _teacherService = TeacherService();
  TeacherDrawerSection _currentDrawerSection = TeacherDrawerSection.dashboard;
  DateTime? _lastBackPressTime;

  // State variables for dashboard data
  Map<String, int> _statistics = {};
  List<Map<String, dynamic>> _recentClassrooms = [];
  List<Map<String, dynamic>> _upcomingSessions = [];
  bool _isLoading = true;
  String? _error;
  String _teacherName = 'Teacher';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadTeacherData();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    // If last back press was more than 2 seconds ago, show message
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return false; // Don't exit
    }

    // Exit app using SystemNavigator
    return true; // Allow pop, which will exit the app
  }

  Future<void> _loadTeacherData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current teacher ID
      final teacherId = await _teacherService.getCurrentTeacherId();

      if (teacherId == null) {
        setState(() {
          _error = 'Teacher account not found. Please contact admin.';
          _isLoading = false;
        });
        return;
      }

      // Load teacher name from database
      final teacherResponse = await Supabase.instance.client
          .from('teachers')
          .select('*, users!inner(first_name, last_name, profile_image_url)')
          .eq('id', teacherId)
          .single();

      // Load teacher statistics and recent data
      final statistics = await _teacherService.getTeacherStatistics(teacherId);
      final recentClassrooms = await _teacherService.getTeacherClassrooms(teacherId);

      // Load upcoming sessions
      final upcomingSessions = await _loadUpcomingSessions(teacherId);

      final firstName = teacherResponse['users']['first_name'] ?? '';
      final lastName = teacherResponse['users']['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      final profileImage = teacherResponse['users']['profile_image_url'];

      setState(() {
        _teacherName = fullName.isNotEmpty ? fullName : 'Teacher';
        _profileImageUrl = profileImage;
        _statistics = statistics;
        _recentClassrooms = recentClassrooms.take(3).toList(); // Show only 3 recent classrooms
        _upcomingSessions = upcomingSessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load teacher data: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadUpcomingSessions(String teacherId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Query sessions from today onwards
      final response = await Supabase.instance.client
          .from('class_sessions')
          .select('''
            id,
            title,
            description,
            session_date,
            start_time,
            end_time,
            session_type,
            meeting_url,
            status,
            classrooms!inner(
              id,
              name,
              subject,
              teacher_id
            )
          ''')
          .eq('classrooms.teacher_id', teacherId)
          .gte('session_date', today.toIso8601String().split('T')[0])
          .order('session_date', ascending: true)
          .order('start_time', ascending: true)
          .limit(10); // Get more and filter in code


      // Filter sessions to only include future ones
      final allSessions = List<Map<String, dynamic>>.from(response);
      final futureSessions = <Map<String, dynamic>>[];

      for (var session in allSessions) {
        final sessionDate = DateTime.parse(session['session_date']);
        final startTime = session['start_time'] as String; // Format: "HH:MM:SS"
        final timeParts = startTime.split(':');
        final sessionDateTime = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );


        if (sessionDateTime.isAfter(now)) {
          futureSessions.add(session);
          if (futureSessions.length >= 5) break; // Only need 5
        }
      }

      return futureSessions;
    } catch (e, stackTrace) {
      return [];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    final pageLabels = ['Home', 'Classes'];

    switch (_currentDrawerSection) {
      case TeacherDrawerSection.dashboard:
        return pageLabels[_currentIndex];
      case TeacherDrawerSection.profile:
        return 'My Profile';
      case TeacherDrawerSection.analytics:
        return 'Analytics';
      case TeacherDrawerSection.settings:
        return 'Settings';
      case TeacherDrawerSection.help:
        return 'Help & Support';
    }
  }

  Widget _getCurrentBody(String teacherName) {
    switch (_currentDrawerSection) {
      case TeacherDrawerSection.dashboard:
        final pages = [_buildHomeContent(teacherName), _buildClassroomsContent()];
        return PageView.builder(
          controller: _pageController,
          itemCount: pages.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) => pages[index],
        );

      case TeacherDrawerSection.profile:
        return const TeacherProfileContent();

      case TeacherDrawerSection.analytics:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Analytics Coming Soon', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
        );

      case TeacherDrawerSection.settings:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Settings Coming Soon', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
        );

      case TeacherDrawerSection.help:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Help & Support Coming Soon', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageLabels = ['Home', 'Classes'];
    final pageIcons = [Icons.home_outlined, Icons.class_outlined];

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        // If on a drawer section other than dashboard, go back to dashboard
        if (_currentDrawerSection != TeacherDrawerSection.dashboard) {
          setState(() {
            _currentDrawerSection = TeacherDrawerSection.dashboard;
            _currentIndex = 0;
          });
          return;
        }

        // If on Classes tab (index 1), go back to Home tab (index 0)
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          _pageController.jumpToPage(0);
          return;
        }

        // Already on Dashboard Home - show exit confirmation
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context, _teacherName),
        body: _getCurrentBody(_teacherName),
        bottomNavigationBar: _currentDrawerSection == TeacherDrawerSection.dashboard
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey[600],
                items: List.generate(
                  2,
                  (index) => BottomNavigationBarItem(icon: Icon(pageIcons[index]), label: pageLabels[index]),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildHomeContent(String teacherName) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTeacherData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeacherData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(teacherName),
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to inspire your students today?',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context),

            const SizedBox(height: 24),

            // Recent Classrooms
            _buildRecentClassrooms(),

            const SizedBox(height: 24),

            // Upcoming Sessions
            _buildUpcomingSessions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.school_outlined,
                title: 'My Classrooms',
                value: '${_statistics['totalClassrooms'] ?? 0}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.people_outline,
                title: 'Total Students',
                value: '${_statistics['totalStudents'] ?? 0}',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.assignment_outlined,
                title: 'Assignments',
                value: '${_statistics['totalAssignments'] ?? 0}',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.folder_outlined,
                title: 'Materials',
                value: '${_statistics['totalMaterials'] ?? 0}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3, // Reduced from 1.5 to give more height
          children: [
            _buildActionCard(
              icon: Icons.video_call,
              title: 'Sessions',
              subtitle: 'Schedule & manage',
              onTap: () {
                context.push('/teacher/sessions');
              },
            ),
            _buildActionCard(
              icon: Icons.assignment_outlined,
              title: 'Assignments',
              subtitle: 'Manage assignments & tests',
              onTap: () {
                context.push('/teacher/assignments');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentClassrooms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Classrooms',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Switch to Classes tab (index 1) in bottom navigation
                _pageController.jumpToPage(1);
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentClassrooms.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.school_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No classrooms yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact your admin to get assigned to classrooms',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentClassrooms
              .map(
                (classroom) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.school, color: Colors.blue[700]),
                    ),
                    title: Text(
                      classroom['name'] ?? 'Untitled Classroom',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${classroom['subject']} • Grade ${classroom['grade_level']}'),
                        const SizedBox(height: 4),
                        Text(
                          '${classroom['active_enrollments'] ?? 0} students • ${classroom['assignment_count'] ?? 0} assignments',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassroomDetailScreen(classroomId: classroom['id']),
                        ),
                      );
                    },
                  ),
                ),
              )
              .toList(),
      ],
    );
  }

  Widget _buildUpcomingSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Sessions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_upcomingSessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text('No Upcoming Sessions', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  for (int i = 0; i < _upcomingSessions.length && i < 3; i++) ...[
                    if (i > 0) const Divider(height: 24),
                    _buildSessionItemFromData(_upcomingSessions[i]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionItemFromData(Map<String, dynamic> session) {
    final classroom = session['classrooms'] as Map<String, dynamic>;
    final subject = classroom['name'] ?? 'Unknown Subject';

    // Parse session_date and start_time/end_time
    final sessionDate = DateTime.parse(session['session_date'] as String);
    final startTime = session['start_time'] as String; // Format: "HH:MM:SS"
    final endTime = session['end_time'] as String;

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    final scheduledStart = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final scheduledEnd = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    final meetingUrl = session['meeting_url'] as String?;

    // Check if session is happening now (within 15 minutes before start time)
    final now = DateTime.now();
    final isLive = now.isAfter(scheduledStart.subtract(const Duration(minutes: 15))) && now.isBefore(scheduledEnd);

    // Format time
    final timeStr = '${_formatTime(scheduledStart)} - ${_formatTime(scheduledEnd)}';

    // Get enrolled student count (placeholder for now)
    final students = 'Scheduled';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLive ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isLive ? Icons.videocam : Icons.schedule,
            color: isLive ? Colors.green : AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(timeStr, style: Theme.of(context).textTheme.bodyMedium),
              Text(students, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
        if (isLive && meetingUrl != null)
          ElevatedButton(
            onPressed: () {
              // TODO: Start session / open meeting URL
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Start'),
          ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  Widget _buildClassroomsContent() {
    return const MyClassroomsScreen();
  }

  Widget _buildAssignmentsContent() {
    return const AssignmentManagementScreen();
  }

  Widget _buildMaterialsContent() {
    return const MaterialsManagementScreen();
  }

  Widget _buildDrawer(BuildContext context, String teacherName) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                  child: _profileImageUrl == null
                      ? Text(
                          teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  teacherName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('Teacher', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: _currentDrawerSection == TeacherDrawerSection.dashboard,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentDrawerSection = TeacherDrawerSection.dashboard;
              });
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            isSelected: _currentDrawerSection == TeacherDrawerSection.profile,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentDrawerSection = TeacherDrawerSection.profile;
              });
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.analytics_outlined,
            title: 'Analytics',
            isSelected: _currentDrawerSection == TeacherDrawerSection.analytics,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentDrawerSection = TeacherDrawerSection.analytics;
              });
            },
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            isSelected: _currentDrawerSection == TeacherDrawerSection.settings,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentDrawerSection = TeacherDrawerSection.settings;
              });
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            isSelected: _currentDrawerSection == TeacherDrawerSection.help,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentDrawerSection = TeacherDrawerSection.help;
              });
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              Navigator.pop(context);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning, $name';
    } else if (hour < 17) {
      return 'Good Afternoon, $name';
    } else {
      return 'Good Evening, $name';
    }
  }
}
