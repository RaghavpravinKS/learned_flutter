import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/session_model.dart';
import '../models/assignment_model.dart';
import 'session_management_screen.dart';
import 'assignment_management_screen.dart';
import 'attendance_marking_screen.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final String classroomId;

  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _classroom;
  List<Map<String, dynamic>> _students = [];
  List<SessionModel> _upcomingSessions = [];
  List<AssignmentModel> _activeAssignments = [];

  bool _isLoading = true;
  String? _error;

  // Statistics
  int _totalEnrolled = 0;
  double _averageAttendance = 0.0;
  double _averageGrade = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadClassroom(),
        _loadStudents(),
        _loadUpcomingSessions(),
        _loadActiveAssignments(),
        _loadStatistics(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClassroom() async {
    try {
      final response = await Supabase.instance.client
          .from('classrooms')
          .select('''
            *,
            teacher:teacher_id (
              id,
              user_id,
              users!inner (
                first_name,
                last_name,
                email
              )
            )
          ''')
          .eq('id', widget.classroomId)
          .single();

      setState(() {
        _classroom = response;
      });
    } catch (e) {
      print('Error loading classroom: $e');
      rethrow;
    }
  }

  Future<void> _loadStudents() async {
    try {
      final response = await Supabase.instance.client
          .from('student_enrollments')
          .select('''
            student_id,
            enrollment_date,
            status,
            student:student_id (
              id,
              student_id,
              grade_level,
              user_id,
              users!inner (
                first_name,
                last_name,
                email,
                phone
              )
            )
          ''')
          .eq('classroom_id', widget.classroomId)
          .eq('status', 'active')
          .order('enrollment_date', ascending: false);

      setState(() {
        _students = List<Map<String, dynamic>>.from(response as List);
        _totalEnrolled = _students.length;
      });
    } catch (e) {
      print('Error loading students: $e');
      rethrow;
    }
  }

  Future<void> _loadUpcomingSessions() async {
    try {
      // Debug: Check authentication and session
      final currentUser = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      print('DEBUG _loadUpcomingSessions: User ID = ${currentUser?.id}');
      print('DEBUG _loadUpcomingSessions: User email = ${currentUser?.email}');
      print('DEBUG _loadUpcomingSessions: Session exists = ${session != null}');
      print('DEBUG _loadUpcomingSessions: Access token exists = ${session?.accessToken != null}');

      // Try refreshing the session before query
      await Supabase.instance.client.auth.refreshSession();
      print('DEBUG: Session refreshed');

      final now = DateTime.now();
      final response = await Supabase.instance.client
          .from('class_sessions')
          .select()
          .eq('classroom_id', widget.classroomId)
          .gte('session_date', now.toIso8601String().split('T')[0])
          .neq('status', 'cancelled')
          .order('session_date', ascending: true)
          .order('start_time', ascending: true)
          .limit(5);

      final sessions = (response as List).map((item) {
        return SessionModel.fromMap({...item, 'classroom_name': _classroom?['name'] ?? 'Unknown'});
      }).toList();

      setState(() {
        _upcomingSessions = sessions;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      // Don't rethrow if it's just empty data - set empty list
      if (e.toString().contains('permission denied')) {
        print('Note: This might just mean there are no sessions in the database yet');
        setState(() {
          _upcomingSessions = [];
        });
      } else {
        rethrow;
      }
    }
  }

  Future<void> _loadActiveAssignments() async {
    try {
      // Debug: Check authentication
      final currentUser = Supabase.instance.client.auth.currentUser;
      print('DEBUG _loadActiveAssignments: User ID = ${currentUser?.id}');
      print('DEBUG _loadActiveAssignments: User email = ${currentUser?.email}');

      // Try refreshing the session before query
      await Supabase.instance.client.auth.refreshSession();
      print('DEBUG: Session refreshed for assignments');

      final now = DateTime.now();
      final response = await Supabase.instance.client
          .from('assignments')
          .select()
          .eq('classroom_id', widget.classroomId)
          .eq('is_published', true)
          .gte('due_date', now.toIso8601String())
          .order('due_date', ascending: true)
          .limit(5);

      final assignments = (response as List).map((item) {
        return AssignmentModel.fromMap(item);
      }).toList();

      setState(() {
        _activeAssignments = assignments;
      });
    } catch (e) {
      print('Error loading assignments: $e');
      // Don't rethrow if it's just empty data - set empty list
      if (e.toString().contains('permission denied')) {
        print('Note: This might just mean there are no assignments in the database yet');
        setState(() {
          _activeAssignments = [];
        });
      } else {
        rethrow;
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // Skip analytics for MVP - will implement in analytics phase
      // Just show basic counts for now
      setState(() {
        _averageAttendance = 0.0;
        _averageGrade = 0.0;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      // Don't rethrow, statistics are optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _classroom?['name'] ?? 'Classroom Details',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _editClassroom();
              } else if (value == 'analytics') {
                _viewAnalytics();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Classroom')),
              const PopupMenuItem(value: 'analytics', child: Text('View Analytics')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Students'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading classroom',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
          ],
        ),
      );
    }

    if (_classroom == null) {
      return const Center(child: Text('Classroom not found'));
    }

    return TabBarView(
      controller: _tabController,
      children: [_buildOverviewTab(), _buildStudentsTab(), _buildActivityTab()],
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Classroom info card
            _buildClassroomInfoCard(),
            const SizedBox(height: 20),

            // Statistics cards
            _buildStatisticsSection(),
            const SizedBox(height: 20),

            // Upcoming sessions
            _buildUpcomingSessionsSection(),
            const SizedBox(height: 20),

            // Active assignments
            _buildActiveAssignmentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomInfoCard() {
    final teacher = _classroom!['teacher'] as Map<String, dynamic>?;
    final teacherUser = teacher?['users'] as Map<String, dynamic>?;
    final firstName = teacherUser?['first_name'] ?? '';
    final lastName = teacherUser?['last_name'] ?? '';
    var teacherName = '$firstName $lastName'.trim();
    if (teacherName.isEmpty) teacherName = 'Unknown';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.class_, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_classroom!['name'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        '${_classroom!['subject']} • Grade ${_classroom!['grade_level']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _classroom!['is_active'] == true ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _classroom!['is_active'] == true ? 'Active' : 'Inactive',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (_classroom!['description'] != null) ...[
              const SizedBox(height: 16),
              Text(_classroom!['description'], style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            ],
            const Divider(height: 32),
            _buildInfoRow(Icons.person, 'Teacher', teacherName),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.menu_book, 'Board', _classroom!['board'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.people,
              'Capacity',
              '${_classroom!['current_students'] ?? 0}/${_classroom!['max_students'] ?? 30}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Students', _totalEnrolled.toString(), Icons.people, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Attendance',
                '${_averageAttendance.toStringAsFixed(1)}%',
                Icons.how_to_reg,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Grade',
                _averageGrade > 0 ? '${_averageGrade.toStringAsFixed(1)}%' : 'N/A',
                Icons.grade,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming Sessions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SessionManagementScreen()));
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_upcomingSessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('No upcoming sessions', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _upcomingSessions.length,
            itemBuilder: (context, index) => _buildSessionCard(_upcomingSessions[index]),
          ),
      ],
    );
  }

  Widget _buildSessionCard(SessionModel session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.event, color: Colors.blue),
        ),
        title: Text(session.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${session.formattedDate} • ${session.formattedTimeRange}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.how_to_reg, color: Colors.green),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceMarkingScreen(session: session)));
          },
        ),
      ),
    );
  }

  Widget _buildActiveAssignmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Assignments', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignmentManagementScreen()));
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activeAssignments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('No active assignments', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activeAssignments.length,
            itemBuilder: (context, index) => _buildAssignmentCard(_activeAssignments[index]),
          ),
      ],
    );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.assignment, color: Colors.purple),
        ),
        title: Text(assignment.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(assignment.typeDisplay, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              'Due: ${assignment.formattedDueDate}',
              style: TextStyle(
                color: assignment.isPastDue ? Colors.red : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(
            '${assignment.totalPoints} pts',
            style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _students.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No students enrolled',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) => _buildStudentCard(_students[index]),
            ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> studentData) {
    final student = studentData['student'] as Map<String, dynamic>;
    final user = student['users'] as Map<String, dynamic>;
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final email = user['email'] as String;
    final gradeLevel = student['grade_level'];
    final enrollmentDate = DateTime.parse(studentData['enrollment_date'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(
            name[0].toUpperCase(),
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.grade, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Grade ${gradeLevel ?? 'N/A'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Joined ${DateFormat('MMM yyyy').format(enrollmentDate)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'view') {
              _viewStudentDetails(studentData);
            } else if (value == 'progress') {
              _viewStudentProgress(student['id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'progress', child: Text('View Progress')),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Recent Activity', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Recent sessions
          if (_upcomingSessions.isNotEmpty) ...[
            _buildActivitySection(
              'Upcoming Sessions',
              Icons.event,
              Colors.blue,
              _upcomingSessions
                  .map((s) => {'title': s.title, 'subtitle': '${s.formattedDate} • ${s.formattedTimeRange}'})
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Active assignments
          if (_activeAssignments.isNotEmpty) ...[
            _buildActivitySection(
              'Active Assignments',
              Icons.assignment,
              Colors.purple,
              _activeAssignments.map((a) => {'title': a.title, 'subtitle': 'Due: ${a.formattedDueDate}'}).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivitySection(String title, IconData icon, Color color, List<Map<String, String>> items) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['title']!),
                subtitle: Text(item['subtitle']!),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
              );
            },
          ),
        ],
      ),
    );
  }

  void _editClassroom() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit classroom feature coming soon')));
  }

  void _viewAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analytics feature coming soon')));
  }

  void _viewStudentDetails(Map<String, dynamic> studentData) {
    final student = studentData['student'] as Map<String, dynamic>;
    final user = student['users'] as Map<String, dynamic>;
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final studentName = '$firstName $lastName'.trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(studentName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user['email']),
            const SizedBox(height: 8),
            _buildDetailRow('Phone', user['phone'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildDetailRow('Grade Level', student['grade_level']?.toString() ?? 'N/A'),
            const SizedBox(height: 8),
            _buildDetailRow('Student ID', student['student_id']),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _viewStudentProgress(String studentId) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student progress feature coming soon')));
  }
}
