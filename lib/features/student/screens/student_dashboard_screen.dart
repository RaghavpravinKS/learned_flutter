import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../providers/course_progress_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/course_progress_section.dart';
import 'assignments_screen.dart';
import 'my_classes_screen.dart';
import 'student_profile_screen.dart';
import 'schedule_screen.dart';
import 'learning_materials_screen.dart';
import 'progress_screen.dart';

class _PageItem {
  final Widget screen;
  final String title;
  final IconData icon;

  _PageItem({required this.screen, required this.title, required this.icon});
}

enum DrawerSection { dashboard, schedule, materials, profile, settings, help }

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  int _currentIndex = 0;
  DrawerSection _currentDrawerSection = DrawerSection.dashboard;
  late final PageController _pageController;
  late List<_PageItem> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    switch (_currentDrawerSection) {
      case DrawerSection.dashboard:
        return _pages[_currentIndex].title;
      case DrawerSection.schedule:
        return 'My Schedule';
      case DrawerSection.materials:
        return 'Learning Materials';
      case DrawerSection.profile:
        return 'Profile';
      case DrawerSection.settings:
        return 'Settings';
      case DrawerSection.help:
        return 'Help & Support';
    }
  }

  Widget _getCurrentBody(String userName) {
    switch (_currentDrawerSection) {
      case DrawerSection.dashboard:
        return PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return _pages[index].screen;
          },
        );
      case DrawerSection.schedule:
        return const _ScheduleBodyWrapper();
      case DrawerSection.materials:
        return const LearningMaterialsScreen();
      case DrawerSection.profile:
        return const StudentProfileScreen();
      case DrawerSection.settings:
        return const Center(
          child: Padding(padding: EdgeInsets.all(20.0), child: Text('Settings - Coming Soon')),
        );
      case DrawerSection.help:
        return const Center(
          child: Padding(padding: EdgeInsets.all(20.0), child: Text('Help & Support - Coming Soon')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Student';

    _pages = [
      _PageItem(screen: _buildHomeContent(userName), title: 'Home', icon: Icons.home_outlined),
      _PageItem(screen: const AssignmentsScreen(), title: 'Assignments', icon: Icons.assignment_outlined),
      _PageItem(screen: const MyClassesScreen(), title: 'Classes', icon: Icons.school_outlined),
      _PageItem(screen: const ProgressScreen(), title: 'Progress', icon: Icons.assessment_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.go(AppRoutes.studentNotifications),
          ),
        ],
      ),
      drawer: _buildDrawer(userName),
      body: _getCurrentBody(userName),
      bottomNavigationBar: _currentDrawerSection == DrawerSection.dashboard ? _buildBottomNavigationBar(context) : null,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentDrawerSection) {
      case DrawerSection.materials:
        return FloatingActionButton(
          onPressed: () {
            // Navigate to downloaded materials
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Downloaded Materials - Coming Soon')));
          },
          tooltip: 'Downloaded Materials',
          child: const Icon(Icons.download_outlined),
        );
      case DrawerSection.schedule:
        return FloatingActionButton(
          onPressed: () {
            // Jump to today
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jump to Today - Coming Soon')));
          },
          tooltip: 'Today',
          child: const Icon(Icons.today),
        );
      default:
        return null;
    }
  }

  Widget _buildDrawer(String userName) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('Student', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          _buildDrawerItem(icon: Icons.dashboard_outlined, title: 'Dashboard', section: DrawerSection.dashboard),
          _buildDrawerItem(icon: Icons.schedule_outlined, title: 'Schedule', section: DrawerSection.schedule),
          _buildDrawerItem(
            icon: Icons.menu_book_outlined,
            title: 'Learning Materials',
            section: DrawerSection.materials,
          ),
          _buildDrawerItem(icon: Icons.person_outline, title: 'Profile', section: DrawerSection.profile),
          const Divider(),
          _buildDrawerItem(icon: Icons.settings_outlined, title: 'Settings', section: DrawerSection.settings),
          _buildDrawerItem(icon: Icons.help_outline, title: 'Help & Support', section: DrawerSection.help),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required DrawerSection section}) {
    final isSelected = _currentDrawerSection == section;
    return Container(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : null),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          setState(() {
            _currentDrawerSection = section;
            if (section == DrawerSection.dashboard) {
              _currentIndex = 0; // Reset to home tab
            }
          });
        },
      ),
    );
  }

  Widget _buildHomeContent(String userName) {
    // Refresh data on pull-to-refresh
    Future<void> refreshData() async {
      return ref.refresh(courseProgressProvider.future);
    }

    return RefreshIndicator(
      onRefresh: refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(userName),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            // Course progress section using the provider
            const CourseProgressSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.school_rounded, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getGreeting(userName),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildQuickActions(BuildContext context) {
    final upcomingSessionsAsync = ref.watch(upcomingSessionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Classes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.studentSchedule),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        upcomingSessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return _buildNoUpcomingClasses(context);
            }
            // Show only the next 2 upcoming sessions
            final nextSessions = sessions.take(2).toList();
            return Column(
              children: [
                for (var session in nextSessions) ...[
                  _buildUpcomingClassCard(session, context),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()),
          ),
          error: (error, stack) => _buildNoUpcomingClasses(context),
        ),
      ],
    );
  }

  Widget _buildNoUpcomingClasses(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.event_available, color: Colors.grey.shade600, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No upcoming classes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  'Check your schedule or browse classrooms',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassCard(dynamic session, BuildContext context) {
    final startTime = session.startTime;
    final endTime = session.endTime;
    final isLive = session.isLive;
    final isToday = _isToday(startTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (isLive) {
            context.push('${AppRoutes.studentSessionJoin}/${session.id}');
          } else {
            context.push('${AppRoutes.studentSessionDetails}/${session.id}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isLive ? Colors.green.shade50 : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatTime(startTime),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isLive ? Colors.green.shade700 : AppColors.primary,
                      ),
                    ),
                    if (isToday)
                      Text(
                        'Today',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isLive ? Colors.green.shade700 : AppColors.primary,
                        ),
                      )
                    else
                      Text(
                        _getDayText(startTime),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isLive ? Colors.green.shade700 : AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Class details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.subject,
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'with ${session.teacherName}',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Join button or status
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Join',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getDayText(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    }

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -1)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: _pages.map((page) => BottomNavigationBarItem(icon: Icon(page.icon), label: page.title)).toList(),
      ),
    );
  }
}

// Wrapper widget to manage Schedule state within Dashboard
class _ScheduleBodyWrapper extends StatefulWidget {
  const _ScheduleBodyWrapper();

  @override
  State<_ScheduleBodyWrapper> createState() => _ScheduleBodyWrapperState();
}

class _ScheduleBodyWrapperState extends State<_ScheduleBodyWrapper> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    return ScheduleBody(
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      calendarFormat: _calendarFormat,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      onTodayPressed: () {
        setState(() {
          _focusedDay = DateTime.now();
          _selectedDay = _focusedDay;
        });
      },
    );
  }
}
