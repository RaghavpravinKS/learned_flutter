import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../services/teacher_service.dart';
import 'classroom_detail_screen.dart';

class MyClassroomsScreen extends ConsumerStatefulWidget {
  const MyClassroomsScreen({super.key});

  @override
  ConsumerState<MyClassroomsScreen> createState() => _MyClassroomsScreenState();
}

class _MyClassroomsScreenState extends ConsumerState<MyClassroomsScreen> {
  final TeacherService _teacherService = TeacherService();
  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teacherId = await _teacherService.getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher not found');
      }

      final classrooms = await _teacherService.getTeacherClassrooms(teacherId);
      setState(() {
        _classrooms = classrooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Error loading classrooms',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadClassrooms, child: const Text('Try Again')),
          ],
        ),
      );
    }

    if (_classrooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Classrooms Assigned',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              'Contact your administrator to get assigned to classrooms.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassrooms,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with stats
          _buildStatsHeader(),
          const SizedBox(height: 24),

          // Classrooms grid
          Text(
            'Your Classrooms',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
          const SizedBox(height: 16),

          // Classroom cards
          ..._classrooms.map(_buildClassroomCard),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalStudents = _classrooms.fold<int>(0, (sum, classroom) => sum + (classroom['active_enrollments'] as int));
    final totalAssignments = _classrooms.fold<int>(0, (sum, classroom) => sum + (classroom['assignment_count'] as int));
    final totalMaterials = _classrooms.fold<int>(0, (sum, classroom) => sum + (classroom['materials_count'] as int));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.class_,
                    count: _classrooms.length,
                    label: 'Classrooms',
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    count: totalStudents,
                    label: 'Students',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.assignment,
                    count: totalAssignments,
                    label: 'Assignments',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.folder,
                    count: totalMaterials,
                    label: 'Materials',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required int count, required String label, required Color color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildClassroomCard(Map<String, dynamic> classroom) {
    final enrollmentCount = classroom['active_enrollments'] as int;
    final maxStudents = classroom['max_students'] as int;
    final enrollmentPercentage = maxStudents > 0 ? (enrollmentCount / maxStudents * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClassroomDetailScreen(classroomId: classroom['id'])),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.school, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroom['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${classroom['subject']} • Grade ${classroom['grade_level']} • ${classroom['board']}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),

              if (classroom['description'] != null && classroom['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  classroom['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Progress bar for enrollment
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Enrollment',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                      Text(
                        '$enrollmentCount/$maxStudents students',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: maxStudents > 0 ? enrollmentCount / maxStudents : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      enrollmentPercentage >= 90
                          ? Colors.red
                          : enrollmentPercentage >= 70
                          ? Colors.orange
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _buildQuickStat(icon: Icons.assignment, count: classroom['assignment_count'], label: 'Assignments'),
                  const SizedBox(width: 20),
                  _buildQuickStat(icon: Icons.folder, count: classroom['materials_count'], label: 'Materials'),
                  const SizedBox(width: 20),
                  _buildQuickStat(icon: Icons.video_call, count: classroom['recent_sessions'], label: 'Sessions (30d)'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat({required IconData icon, required int count, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
        ),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
