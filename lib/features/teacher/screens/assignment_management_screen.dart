import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../services/teacher_service.dart';

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

      // Load assignments using the existing function
      final assignmentsResponse = await Supabase.instance.client.rpc('get_teacher_assignments', {
        'p_teacher_id': teacherId,
      });

      // Load classrooms for filtering
      final classrooms = await _teacherService.getTeacherClassrooms(teacherId);

      setState(() {
        _assignments = List<Map<String, dynamic>>.from(assignmentsResponse);
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
    final totalSubmissions = assignment['total_submissions'] as int;
    final gradedSubmissions = assignment['graded_submissions'] as int;

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
      case 'homework':
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
    // TODO: Navigate to assignment details screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Assignment details coming soon for: ${assignment['title']}')));
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

    showDialog(
      context: context,
      builder: (context) => _CreateAssignmentDialog(classrooms: _classrooms, onAssignmentCreated: _loadData),
    );
  }
}

class _CreateAssignmentDialog extends StatefulWidget {
  final List<Map<String, dynamic>> classrooms;
  final VoidCallback onAssignmentCreated;

  const _CreateAssignmentDialog({required this.classrooms, required this.onAssignmentCreated});

  @override
  State<_CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<_CreateAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _totalPointsController = TextEditingController(text: '100');

  String? _selectedClassroomId;
  String _selectedAssignmentType = 'homework';
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  final List<String> _assignmentTypes = ['homework', 'quiz', 'test', 'project'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _totalPointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_add, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Create Assignment',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Classroom selection
                    DropdownButtonFormField<String>(
                      value: _selectedClassroomId,
                      decoration: const InputDecoration(labelText: 'Classroom', border: OutlineInputBorder()),
                      items: widget.classrooms
                          .map(
                            (classroom) =>
                                DropdownMenuItem<String>(value: classroom['id'], child: Text(classroom['name'])),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedClassroomId = value),
                      validator: (value) => value == null ? 'Please select a classroom' : null,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Assignment Title', border: OutlineInputBorder()),
                      validator: (value) => value?.trim().isEmpty ?? true ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),

                    // Assignment type
                    DropdownButtonFormField<String>(
                      value: _selectedAssignmentType,
                      decoration: const InputDecoration(labelText: 'Assignment Type', border: OutlineInputBorder()),
                      items: _assignmentTypes
                          .map((type) => DropdownMenuItem<String>(value: type, child: Text(type.toUpperCase())))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedAssignmentType = value!),
                    ),
                    const SizedBox(height: 16),

                    // Total points
                    TextFormField(
                      controller: _totalPointsController,
                      decoration: const InputDecoration(labelText: 'Total Points', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final points = int.tryParse(value ?? '');
                        if (points == null || points <= 0) {
                          return 'Please enter a valid number of points';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Due date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule),
                      title: Text(
                        _selectedDueDate == null
                            ? 'Set Due Date'
                            : 'Due: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _selectDueDate,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Instructions
                    TextFormField(
                      controller: _instructionsController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createAssignment,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Create Assignment', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 59));

      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final teacherService = TeacherService();
      final teacherId = await teacherService.getCurrentTeacherId();
      if (teacherId == null) throw Exception('Teacher not found');

      // Call the create_assignment function
      final response = await Supabase.instance.client.rpc('create_assignment', {
        'p_teacher_id': teacherId,
        'p_classroom_id': _selectedClassroomId,
        'p_title': _titleController.text.trim(),
        'p_description': _descriptionController.text.trim(),
        'p_due_date': _selectedDueDate?.toIso8601String(),
        'p_total_points': int.parse(_totalPointsController.text),
        'p_instructions': _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
        'p_assignment_type': _selectedAssignmentType,
      });

      if (response['success'] == true) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assignment "${_titleController.text}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onAssignmentCreated();
        }
      } else {
        throw Exception(response['error'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating assignment: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
