import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../providers/course_progress_provider.dart';
import '../providers/session_provider.dart';
import '../providers/student_profile_provider.dart';
import '../providers/classroom_provider.dart';
import '../widgets/recent_activity_section.dart';
import 'student_profile_screen.dart';
import 'schedule_screen.dart';
import 'all_learning_materials_screen.dart';
import 'my_classes_screen.dart' as my_classes;

enum DrawerSection { dashboard, myClasses, schedule, profile }

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  DrawerSection _currentDrawerSection = DrawerSection.dashboard;
  DateTime? _lastBackPressTime;

  // Public method to switch drawer section
  void switchToDrawerSection(DrawerSection section) {
    setState(() {
      _currentDrawerSection = section;
    });
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

    // Exit app using SystemNavigator instead of Navigator.pop
    return true; // Allow pop, which will exit the app
  }

  String _getAppBarTitle() {
    switch (_currentDrawerSection) {
      case DrawerSection.dashboard:
        return 'Home';
      case DrawerSection.myClasses:
        return 'My Classes';
      case DrawerSection.schedule:
        return 'My Schedule';
      case DrawerSection.profile:
        return 'Profile';
    }
  }

  Widget _getCurrentBody(String userName) {
    switch (_currentDrawerSection) {
      case DrawerSection.dashboard:
        return _buildHomeContent(userName);
      case DrawerSection.myClasses:
        return const my_classes.MyClassesScreen();
      case DrawerSection.schedule:
        return const _ScheduleBodyWrapper();
      case DrawerSection.profile:
        return const StudentProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Student';

    // Watch student profile to get profile image URL
    final studentProfileAsync = ref.watch(currentStudentProfileProvider);
    String? profileImageUrl;

    studentProfileAsync.whenData((profile) {
      if (profile != null && profile['users'] != null) {
        profileImageUrl = profile['users']['profile_image_url'];
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        // If on a drawer section other than dashboard, go back to dashboard
        if (_currentDrawerSection != DrawerSection.dashboard) {
          setState(() {
            _currentDrawerSection = DrawerSection.dashboard;
          });
          return;
        }

        // Already on Dashboard - show exit confirmation
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
              onPressed: () => context.go(AppRoutes.studentNotifications),
            ),
          ],
        ),
        drawer: _buildDrawer(userName, profileImageUrl),
        body: _getCurrentBody(userName),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentDrawerSection) {
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

  Widget _buildDrawer(String userName, String? profileImageUrl) {
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
                  backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null || profileImageUrl.isEmpty
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87),
                        )
                      : null,
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
          _buildDrawerItem(icon: Icons.school_outlined, title: 'My Classes', section: DrawerSection.myClasses),
          _buildDrawerItem(icon: Icons.schedule_outlined, title: 'Schedule', section: DrawerSection.schedule),
          _buildDrawerItem(icon: Icons.person_outline, title: 'Profile', section: DrawerSection.profile),
          const Divider(),
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
            _buildQuickActionsButtons(context),
            const SizedBox(height: 24),
            _buildMyClassesSection(context),
            const SizedBox(height: 24),
            _buildUpcomingClasses(context),
            const SizedBox(height: 24),
            // Recent activity section
            const RecentActivitySection(),
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

  Widget _buildQuickActionsButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                icon: Icons.assignment_outlined,
                title: 'Assignments',
                subtitle: 'View & Submit',
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.studentAssignments),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context: context,
                icon: Icons.menu_book_outlined,
                title: 'Materials',
                subtitle: 'View & Download',
                color: AppColors.primary,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => const AllLearningMaterialsScreen()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingClasses(BuildContext context) {
    final upcomingSessionsAsync = ref.watch(upcomingSessionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Sessions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            TextButton(
              onPressed: () {
                // Switch to schedule section - we're already inside the state class
                switchToDrawerSection(DrawerSection.schedule);
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                ],
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
                Text('No upcoming sessions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
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
          // Always navigate to join session screen (whether live or not)
          context.push('/student/schedule/session/join/${session.id}', extra: session);
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

  Widget _buildMyClassesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Classes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            TextButton(
              onPressed: () {
                switchToDrawerSection(DrawerSection.myClasses);
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer(
          builder: (context, ref, child) {
            final enrolledClassroomsAsync = ref.watch(enrolledClassroomsProvider);
            return enrolledClassroomsAsync.when(
              data: (classrooms) {
                if (classrooms.isEmpty) {
                  return _buildNoClassesCard(context);
                }
                // Show only first 2 classes
                final displayClasses = classrooms.take(2).toList();
                return Column(
                  children: [
                    for (var classroom in displayClasses) ...[
                      _buildClassroomPreviewCard(context, classroom),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _buildNoClassesCard(context),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoClassesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: Colors.grey.shade600, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No enrolled classes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      'Browse classrooms to get started',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/classrooms');
              },
              icon: const Icon(Icons.explore, size: 18),
              label: const Text('Enroll'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomPreviewCard(BuildContext context, Map<String, dynamic> classroom) {
    final progress = (classroom['progress'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/classroom-home/${classroom['id']}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom['name'] ?? 'Unknown Classroom',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${classroom['subject']} • Grade ${classroom['grade_level']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (progress > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 0.9
                              ? Colors.green
                              : progress >= 0.5
                              ? AppColors.primary
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
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
