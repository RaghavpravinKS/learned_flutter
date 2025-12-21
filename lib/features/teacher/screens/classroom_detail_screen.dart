import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

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
  List<Map<String, dynamic>> _materials = [];

  bool _isLoading = true;
  bool _isUploadingMaterial = false;
  String? _error;

  // Statistics
  int _totalEnrolled = 0;
  double _averageAttendance = 0.0;
  double _averageGrade = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        _loadMaterials(),
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
      rethrow;
    }
  }

  Future<void> _loadUpcomingSessions() async {
    try {
      // Try refreshing the session before query
      await Supabase.instance.client.auth.refreshSession();

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
      // Don't rethrow if it's just empty data - set empty list
      if (e.toString().contains('permission denied')) {
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
      // Try refreshing the session before query
      await Supabase.instance.client.auth.refreshSession();

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
      // Don't rethrow if it's just empty data - set empty list
      if (e.toString().contains('permission denied')) {
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
            Tab(text: 'Materials'),
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
      children: [_buildOverviewTab(), _buildStudentsTab(), _buildActivityTab(), _buildMaterialsTab()],
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
    // Safely extract nested data with null checks
    final studentRaw = studentData['student'];
    if (studentRaw == null) {
      return const SizedBox.shrink(); // Skip this card
    }
    
    final student = studentRaw as Map<String, dynamic>;
    final userRaw = student['users'];
    if (userRaw == null) {
      return const SizedBox.shrink(); // Skip this card
    }
    
    final user = userRaw as Map<String, dynamic>;
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final name = '$firstName $lastName'.trim().isEmpty ? 'Unknown Student' : '$firstName $lastName'.trim();
    final email = user['email'] as String? ?? 'No email';
    final gradeLevel = student['grade_level'];
    final enrollmentDateStr = studentData['enrollment_date'] as String?;
    final enrollmentDate = enrollmentDateStr != null 
        ? DateTime.tryParse(enrollmentDateStr) ?? DateTime.now()
        : DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
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

  Widget _buildMaterialsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadMaterials();
      },
      child: _materials.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'No Materials Yet',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload course materials for your students',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isUploadingMaterial ? null : _uploadMaterial,
                    icon: _isUploadingMaterial
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_isUploadingMaterial ? 'Uploading...' : 'Upload Material'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_materials.length} Material${_materials.length == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isUploadingMaterial ? null : _uploadMaterial,
                        icon: _isUploadingMaterial
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.add, size: 20),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _materials.length,
                    itemBuilder: (context, index) => _buildMaterialCard(_materials[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    final fileName = material['title'] as String; // Using 'title' instead of 'file_name'
    final fileSize = _formatFileSize(material['file_size'] as int? ?? 0);
    final uploadedAt = DateTime.parse(material['created_at'] as String);
    final isPublic = material['is_public'] as bool? ?? false;

    // Get file extension and icon
    final extension = fileName.split('.').last.toLowerCase();
    IconData icon;
    Color iconColor;

    switch (extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        icon = Icons.image;
        iconColor = Colors.purple;
        break;
      case 'mp4':
      case 'mov':
      case 'avi':
        icon = Icons.video_file;
        iconColor = Colors.pink;
        break;
      default:
        icon = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewMaterial(material),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('Size: $fileSize', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(
                      'Uploaded: ${DateFormat('MMM dd, yyyy').format(uploadedAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (isPublic)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          'Public',
                          style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDeleteMaterial(material);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMaterials() async {
    try {

      final response = await Supabase.instance.client
          .from('learning_materials')
          .select('*')
          .eq('classroom_id', widget.classroomId)
          .order('created_at', ascending: false);


      setState(() {
        _materials = List<Map<String, dynamic>>.from(response);
      });
    } catch (e, stackTrace) {
    }
  }

  Future<void> _uploadMaterial() async {
    try {

      // Pick file
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;

      if (file.bytes == null && file.path == null) {
        throw Exception('No file data available');
      }

      setState(() => _isUploadingMaterial = true);

      // Get teacher ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      final teacherResponse = await Supabase.instance.client
          .from('teachers')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final teacherId = teacherResponse['id'] as String;

      // Verify the teacher owns this classroom (for debugging policy)
      final classroomCheck = await Supabase.instance.client
          .from('classrooms')
          .select('id, teacher_id, name')
          .eq('id', widget.classroomId)
          .maybeSingle();

      if (classroomCheck != null) {
      } else {
      }

      // Upload to Supabase Storage
      final filePath = 'classrooms/${widget.classroomId}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      try {
        if (file.bytes != null) {
          await Supabase.instance.client.storage
              .from('learning-materials')
              .uploadBinary(filePath, file.bytes!, fileOptions: FileOptions(contentType: file.extension));
        } else if (file.path != null) {
          await Supabase.instance.client.storage.from('learning-materials').upload(filePath, File(file.path!));
        }
      } catch (storageError) {
        if (storageError is StorageException) {
        }
        rethrow;
      }

      // Get public URL
      final fileUrl = Supabase.instance.client.storage.from('learning-materials').getPublicUrl(filePath);

      // Save to database

      // Determine material type from file extension
      String materialType = 'document'; // default
      final ext = file.extension?.toLowerCase();
      if (ext != null) {
        if (['mp4', 'mov', 'avi', 'webm'].contains(ext)) {
          materialType = 'video';
        } else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
          materialType = 'note'; // or could be 'document'
        } else if (['ppt', 'pptx'].contains(ext)) {
          materialType = 'presentation';
        } else if (['pdf', 'doc', 'docx'].contains(ext)) {
          materialType = 'document';
        }
      }

      final materialData = {
        'classroom_id': widget.classroomId,
        'teacher_id': teacherId,
        'title': file.name,
        'material_type': materialType,
        'file_url': fileUrl,
        'file_size': file.size,
        'mime_type': file.extension,
        'is_public': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('learning_materials').insert(materialData);

      // Reload materials
      await _loadMaterials();


      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Material uploaded successfully!'), backgroundColor: Colors.green));
      }
    } catch (e, stackTrace) {

      if (e is StorageException) {
      } else if (e is PostgrestException) {
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading material: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMaterial = false);
      }
    }
  }

  Future<void> _confirmDeleteMaterial(Map<String, dynamic> material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMaterial(material);
    }
  }

  Future<void> _deleteMaterial(Map<String, dynamic> material) async {
    try {
      // Extract file path from file_url
      // file_url format: https://{project}.supabase.co/storage/v1/object/public/learning-materials/{path}
      final fileUrl = material['file_url'] as String?;
      if (fileUrl != null) {
        // Extract the path after 'learning-materials/'
        final uri = Uri.parse(fileUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('learning-materials');
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          await Supabase.instance.client.storage.from('learning-materials').remove([filePath]);
        }
      }

      // Delete from database
      await Supabase.instance.client.from('learning_materials').delete().eq('id', material['id']);

      // Reload materials
      await _loadMaterials();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Material deleted successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting material: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _viewMaterial(Map<String, dynamic> material) async {
    final storedUrl = material['file_url'] as String?;
    if (storedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File URL not available'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      
      String? filePath;
      if (storedUrl.contains('learning-materials/')) {
        filePath = storedUrl.split('learning-materials/').last;
      }

      Uri uri;
      if (filePath != null) {
        try {
          // Create a signed URL for secure access
          final signedUrl = await Supabase.instance.client.storage
              .from('learning-materials')
              .createSignedUrl(filePath, 3600);
          uri = Uri.parse(signedUrl);
        } catch (e) {
          uri = Uri.parse(storedUrl);
        }
      } else {
        uri = Uri.parse(storedUrl);
      }

      // Try in-app browser first, then external
      var launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!launched && mounted) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
