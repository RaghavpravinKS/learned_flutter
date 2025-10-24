import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/assignment_model.dart';
import '../services/teacher_service.dart';
import 'assignment_grading_screen.dart';
import 'create_assignment_screen.dart';

class AssignmentManagementScreen extends ConsumerStatefulWidget {
  const AssignmentManagementScreen({super.key});

  @override
  ConsumerState<AssignmentManagementScreen> createState() => _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState extends ConsumerState<AssignmentManagementScreen> with TickerProviderStateMixin {
  final TeacherService _teacherService = TeacherService();
  late TabController _tabController;

  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedClassroomFilter;

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
      final teacherId = await _teacherService.getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher not found');
      }

      // Load assignments directly from the table
      final assignmentsResponse = await Supabase.instance.client
          .from('assignments')
          .select('''
            *,
            classroom:classroom_id (
              name
            )
          ''')
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      // For each assignment, get submission counts
      final assignments = await Future.wait(
        (assignmentsResponse as List).map((assignment) async {
          final assignmentId = assignment['id'];

          // Get total submission count (count unique students who submitted)
          final submissionsResponse = await Supabase.instance.client
              .from('student_assignment_attempts')
              .select('student_id')
              .eq('assignment_id', assignmentId)
              .not('submitted_at', 'is', null);

          final uniqueStudents = (submissionsResponse as List).map((s) => s['student_id']).toSet().length;

          // Get graded count (count unique students with graded submissions)
          final gradedResponse = await Supabase.instance.client
              .from('student_assignment_attempts')
              .select('student_id')
              .eq('assignment_id', assignmentId)
              .eq('is_graded', true);

          final gradedStudents = (gradedResponse as List).map((s) => s['student_id']).toSet().length;

          final classroom = assignment['classroom'] as Map<String, dynamic>?;

          // Determine status based on publish state and due date
          String status;
          if (assignment['is_published'] != true) {
            status = 'draft';
          } else {
            // Check if due date has passed
            final dueDate = assignment['due_date'] != null ? DateTime.parse(assignment['due_date'] as String) : null;

            if (dueDate != null && dueDate.isBefore(DateTime.now())) {
              status = 'completed';
            } else {
              status = 'active';
            }
          }

          return <String, dynamic>{
            ...assignment,
            'classroom_name': classroom?['name'] ?? 'Unknown',
            'status': status,
            'submission_count': uniqueStudents,
            'graded_count': gradedStudents,
          };
        }).toList(),
      );

      // Load classrooms for filtering
      final classrooms = await _teacherService.getTeacherClassrooms(teacherId);

      setState(() {
        _assignments = assignments;
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

  List<Map<String, dynamic>> get _filteredAssignments {
    if (_selectedClassroomFilter == null) {
      return _assignments;
    }
    return _assignments.where((assignment) => assignment['classroom_id'] == _selectedClassroomFilter).toList();
  }

  List<Map<String, dynamic>> get _activeAssignments {
    return _filteredAssignments.where((assignment) => assignment['status'] == 'active').toList();
  }

  List<Map<String, dynamic>> get _draftAssignments {
    return _filteredAssignments.where((assignment) => assignment['status'] == 'draft').toList();
  }

  List<Map<String, dynamic>> get _completedAssignments {
    return _filteredAssignments.where((assignment) => assignment['status'] == 'completed').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Classroom filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Filter by Classroom:', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedClassroomFilter,
                            hint: Text(
                              'All Classrooms',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                            ),
                            dropdownColor: AppColors.primary,
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.9)),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Classrooms', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                              ),
                              ..._classrooms.map(
                                (classroom) => DropdownMenuItem<String>(
                                  value: classroom['id'],
                                  child: Text(
                                    classroom['name'],
                                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedClassroomFilter = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: [
                  Tab(text: 'Active (${_activeAssignments.length})'),
                  Tab(text: 'Draft (${_draftAssignments.length})'),
                  Tab(text: 'Completed (${_completedAssignments.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAssignmentDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
      ),
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
              'Error loading assignments',
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

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAssignmentList(_activeAssignments, 'No active assignments'),
        _buildAssignmentList(_draftAssignments, 'No draft assignments'),
        _buildAssignmentList(_completedAssignments, 'No completed assignments'),
      ],
    );
  }

  Widget _buildAssignmentList(List<Map<String, dynamic>> assignments, String emptyMessage) {
    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first assignment to get started.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: assignments.length,
        itemBuilder: (context, index) => _buildAssignmentCard(assignments[index]),
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final dueDate = assignment['due_date'] != null ? DateTime.parse(assignment['due_date']) : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());
    final totalSubmissions = (assignment['submission_count'] ?? 0) as int;
    final gradedSubmissions = (assignment['graded_count'] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewAssignmentDetails(assignment),
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
                      color: _getStatusColor(assignment['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getAssignmentIcon(assignment['assignment_type']),
                      color: _getStatusColor(assignment['status']),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment['title'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(assignment['classroom_name'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(assignment['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(assignment['status']).withOpacity(0.3)),
                    ),
                    child: Text(
                      assignment['status'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(assignment['status']),
                      ),
                    ),
                  ),
                ],
              ),

              if (assignment['description'] != null && assignment['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  assignment['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Assignment details row
              Row(
                children: [
                  if (dueDate != null) ...[
                    Icon(
                      isOverdue ? Icons.warning : Icons.schedule,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDateTime(dueDate)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.score, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${assignment['total_points']} pts', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),

              if (assignment['status'] == 'active') ...[
                const SizedBox(height: 12),
                // Progress indicator for submissions
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Submissions',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                              ),
                              Text(
                                '$totalSubmissions submissions • $gradedSubmissions graded',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: totalSubmissions > 0 ? gradedSubmissions / totalSubmissions : 0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              gradedSubmissions == totalSubmissions ? Colors.green : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAssignmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Icons.quiz_outlined;
      case 'test':
        return Icons.fact_check_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'project':
        return Icons.folder_special_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays < 0) {
      return '${difference.inDays.abs()} days ago';
    } else if (difference.inDays == 0) {
      if (difference.inHours < 0) {
        return '${difference.inHours.abs()} hours ago';
      } else {
        return '${difference.inHours} hours left';
      }
    } else {
      return '${difference.inDays} days left';
    }
  }

  void _viewAssignmentDetails(Map<String, dynamic> assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Title
              Text(assignment['title'], style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Classroom name
              Row(
                children: [
                  Icon(Icons.class_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(assignment['classroom_name'], style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(assignment['status']).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAssignmentIcon(assignment['assignment_type']),
                      size: 16,
                      color: _getStatusColor(assignment['status']),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      assignment['status'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(assignment['status']),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Details
              _buildDetailRow(Icons.score, 'Total Points', '${assignment['total_points']} points'),
              if (assignment['due_date'] != null)
                _buildDetailRow(Icons.schedule, 'Due Date', _formatDateTime(DateTime.parse(assignment['due_date']))),
              if (assignment['description'] != null && assignment['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text('Description', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(assignment['description'], style: TextStyle(color: Colors.grey[700], height: 1.5)),
              ],
              if (assignment['instructions'] != null && assignment['instructions'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text('Instructions', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(assignment['instructions'], style: TextStyle(color: Colors.grey[700], height: 1.5)),
              ],
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editAssignment(assignment);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _gradeAssignment(assignment);
                      },
                      icon: const Icon(Icons.grading),
                      label: const Text('Grade'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _editAssignment(Map<String, dynamic> assignmentData) {
    // Convert map to AssignmentModel
    final assignment = AssignmentModel.fromMap(assignmentData);

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => CreateAssignmentScreen(assignment: assignment))).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _gradeAssignment(Map<String, dynamic> assignmentData) {
    // Convert map to AssignmentModel
    final assignment = AssignmentModel.fromMap(assignmentData);

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => AssignmentGradingScreen(assignment: assignment)));
  }

  void _showCreateAssignmentDialog() {
    if (_classrooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be assigned to at least one classroom to create assignments.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to Create Assignment Screen
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateAssignmentScreen())).then((result) {
      // Reload data if assignment was created
      if (result == true) {
        _loadData();
      }
    });
  }
}
