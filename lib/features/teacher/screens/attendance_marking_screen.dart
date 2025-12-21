import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  final SessionModel session;

  const AttendanceMarkingScreen({super.key, required this.session});

  @override
  State<AttendanceMarkingScreen> createState() => _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  List<AttendanceModel> _attendanceList = [];
  List<Map<String, dynamic>> _enrolledStudents = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // Track changes
  final Map<String, String> _changedStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([_loadEnrolledStudents(), _loadExistingAttendance()]);

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

  Future<void> _loadEnrolledStudents() async {
    try {
      final response = await Supabase.instance.client
          .from('student_enrollments')
          .select('''
            student_id,
            student:student_id (
              id,
              user_id,
              users!inner (
                first_name,
                last_name,
                email
              )
            )
          ''')
          .eq('classroom_id', widget.session.classroomId)
          .eq('status', 'active');

      setState(() {
        _enrolledStudents = List<Map<String, dynamic>>.from(response as List);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadExistingAttendance() async {
    try {
      final response = await Supabase.instance.client
          .from('session_attendance')
          .select('''
            *,
            student:student_id (
              id,
              user_id,
              users!inner (
                first_name,
                last_name,
                email
              )
            )
          ''')
          .eq('session_id', widget.session.id);

      final attendance = (response as List).map((item) {
        final student = item['student'] as Map<String, dynamic>?;
        final user = student?['users'] as Map<String, dynamic>?;

        final firstName = user?['first_name'] ?? '';
        final lastName = user?['last_name'] ?? '';
        final fullName = (firstName + ' ' + lastName).trim();

        return AttendanceModel.fromMap({
          ...item,
          'student_name': fullName.isNotEmpty ? fullName : 'Unknown',
          'student_email': user?['email'],
        });
      }).toList();

      setState(() {
        _attendanceList = attendance;
      });
    } catch (e) {
      rethrow;
    }
  }

  String? _getAttendanceStatus(String studentId) {
    // Check if there's a local change
    if (_changedStatuses.containsKey(studentId)) {
      return _changedStatuses[studentId];
    }

    // Check existing attendance
    try {
      final existing = _attendanceList.firstWhere((a) => a.studentId == studentId);
      return existing.attendanceStatus;
    } catch (e) {
      return null; // Not marked yet
    }
  }

  String? _getSavedAttendanceStatus(String studentId) {
    // Get the saved status from database (ignore local changes)
    try {
      final existing = _attendanceList.firstWhere((a) => a.studentId == studentId);
      return existing.attendanceStatus;
    } catch (e) {
      return null; // Not marked yet
    }
  }

  void _updateAttendanceStatus(String studentId, String status) {
    setState(() {
      _changedStatuses[studentId] = status;
    });
  }

  Future<void> _saveAllAttendance() async {
    if (_changedStatuses.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSaving = true);

    try {
      for (final entry in _changedStatuses.entries) {
        final studentId = entry.key;
        final status = entry.value;

        // Check if attendance record already exists
        final existing = _attendanceList.firstWhere(
          (a) => a.studentId == studentId,
          orElse: () => AttendanceModel(sessionId: widget.session.id, studentId: studentId, studentName: ''),
        );

        final now = DateTime.now();

        if (existing.id != null) {
          // Update existing record
          await Supabase.instance.client
              .from('session_attendance')
              .update({'attendance_status': status, 'updated_at': now.toIso8601String()})
              .eq('id', existing.id!);
        } else {
          // Insert new record
          await Supabase.instance.client.from('session_attendance').insert({
            'session_id': widget.session.id,
            'student_id': studentId,
            'attendance_status': status,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
        }
      }

      if (mounted) {
        setState(() {
          _changedStatuses.clear();
          _isSaving = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Attendance saved successfully!'), backgroundColor: Colors.green));

        // Reload data
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving attendance: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _markAllAs(String status) {
    setState(() {
      for (final student in _enrolledStudents) {
        final studentId = student['student_id'] as String;
        _changedStatuses[studentId] = status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark Attendance', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(widget.session.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _markAllAs,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'present', child: Text('Mark All Present')),
              const PopupMenuItem(value: 'absent', child: Text('Mark All Absent')),
              const PopupMenuItem(value: 'late', child: Text('Mark All Late')),
              const PopupMenuItem(value: 'excused', child: Text('Mark All Excused')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
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
              'Error loading data',
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

    if (_enrolledStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No students enrolled',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text('No students are enrolled in this classroom', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Session info card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.event, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.classroomName,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${widget.session.formattedDate} • ${widget.session.formattedTimeRange}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Text(
                '${_enrolledStudents.length} Students',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
        ),

        // Attendance summary
        if (_changedStatuses.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  '${_changedStatuses.length} unsaved changes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[700]),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Student list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _enrolledStudents.length,
            itemBuilder: (context, index) => _buildStudentCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(int index) {
    final studentData = _enrolledStudents[index];
    final student = studentData['student'] as Map<String, dynamic>;
    final user = student['users'] as Map<String, dynamic>;
    final studentId = student['id'] as String;
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final name = (firstName + ' ' + lastName).trim();
    final email = user['email'] as String;

    final currentStatus = _getAttendanceStatus(studentId);
    final savedStatus = _getSavedAttendanceStatus(studentId);
    final hasChanges = _changedStatuses.containsKey(studentId);
    final isAlreadyMarked = savedStatus != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasChanges ? 3 : (isAlreadyMarked ? 2 : 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasChanges
            ? BorderSide(color: Colors.orange, width: 2)
            : isAlreadyMarked
            ? BorderSide(color: _getStatusColor(savedStatus).withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(currentStatus ?? 'not_marked').withOpacity(0.2),
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(currentStatus ?? 'not_marked'),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                      Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      // Show saved status with better visual feedback
                      if (isAlreadyMarked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(savedStatus).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusColor(savedStatus).withOpacity(0.4), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getStatusIcon(savedStatus), size: 12, color: _getStatusColor(savedStatus)),
                                const SizedBox(width: 4),
                                Text(
                                  'Marked: ${_capitalizeFirst(savedStatus)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getStatusColor(savedStatus),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                'Not marked yet',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 12, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          isAlreadyMarked ? 'Updating' : 'New',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.orange[700]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Attendance status buttons
            Row(
              children: [
                _buildStatusButton('present', 'Present', Icons.check_circle, studentId, currentStatus ?? ''),
                const SizedBox(width: 8),
                _buildStatusButton('absent', 'Absent', Icons.cancel, studentId, currentStatus ?? ''),
                const SizedBox(width: 8),
                _buildStatusButton('late', 'Late', Icons.access_time, studentId, currentStatus ?? ''),
                const SizedBox(width: 8),
                _buildStatusButton('excused', 'Excused', Icons.event_busy, studentId, currentStatus ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, String label, IconData icon, String studentId, String currentStatus) {
    final isSelected = currentStatus == status;
    final color = _getStatusColor(status);

    return Expanded(
      child: InkWell(
        onTap: () => _updateAttendanceStatus(studentId, status),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? color : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      case 'not_marked':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.event_busy;
      default:
        return Icons.help_outline;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildBottomBar() {
    if (_changedStatuses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _changedStatuses.clear();
                        });
                      },
                icon: const Icon(Icons.clear),
                label: const Text('Discard Changes'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAllAttendance,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Attendance (${_changedStatuses.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
