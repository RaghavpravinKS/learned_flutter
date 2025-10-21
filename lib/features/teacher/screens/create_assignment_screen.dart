import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/assignment_model.dart';
import '../services/teacher_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final AssignmentModel? assignment; // Null for create, populated for edit

  const CreateAssignmentScreen({super.key, this.assignment});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TeacherService _teacherService = TeacherService();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _totalPointsController;
  late final TextEditingController _timeLimitController;

  // Form state
  String? _selectedClassroomId;
  String _selectedAssignmentType = 'assignment';
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _hasTimeLimit = false;

  // UI state
  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = false;
  bool _isLoadingClassrooms = true;
  String? _error;

  final List<Map<String, dynamic>> _assignmentTypes = [
    {'value': 'assignment', 'label': 'Assignment', 'icon': Icons.assignment_outlined},
    {'value': 'quiz', 'label': 'Quiz', 'icon': Icons.quiz_outlined},
    {'value': 'test', 'label': 'Test', 'icon': Icons.school_outlined},
    {'value': 'project', 'label': 'Project', 'icon': Icons.folder_outlined},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if editing
    _titleController = TextEditingController(text: widget.assignment?.title ?? '');
    _descriptionController = TextEditingController(text: widget.assignment?.description ?? '');
    _instructionsController = TextEditingController(text: widget.assignment?.instructions ?? '');
    _totalPointsController = TextEditingController(text: widget.assignment?.totalPoints.toString() ?? '100');
    _timeLimitController = TextEditingController(text: widget.assignment?.timeLimitMinutes?.toString() ?? '');

    // Set initial state from existing assignment
    if (widget.assignment != null) {
      _selectedClassroomId = widget.assignment!.classroomId;
      _selectedAssignmentType = widget.assignment!.assignmentType;
      _selectedDueDate = widget.assignment!.dueDate;
      if (_selectedDueDate != null) {
        _selectedDueTime = TimeOfDay.fromDateTime(_selectedDueDate!);
      }
      _hasTimeLimit = widget.assignment!.timeLimitMinutes != null;
    }

    _loadClassrooms();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _totalPointsController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadClassrooms() async {
    try {
      final teacherId = await _teacherService.getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher not found');
      }

      final classrooms = await _teacherService.getTeacherClassrooms(teacherId);

      setState(() {
        _classrooms = classrooms;
        _isLoadingClassrooms = false;

        // If creating new and only one classroom, auto-select it
        if (widget.assignment == null && classrooms.length == 1) {
          _selectedClassroomId = classrooms[0]['id'];
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingClassrooms = false;
      });
    }
  }

  Future<void> _saveAssignment({required bool publish}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassroomId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a classroom'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teacherId = await _teacherService.getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher not found');
      }

      // Combine date and time for due date
      DateTime? finalDueDate;
      if (_selectedDueDate != null) {
        if (_selectedDueTime != null) {
          finalDueDate = DateTime(
            _selectedDueDate!.year,
            _selectedDueDate!.month,
            _selectedDueDate!.day,
            _selectedDueTime!.hour,
            _selectedDueTime!.minute,
          );
        } else {
          // Default to end of day if no time selected
          finalDueDate = DateTime(_selectedDueDate!.year, _selectedDueDate!.month, _selectedDueDate!.day, 23, 59);
        }
      }

      final assignmentData = {
        'classroom_id': _selectedClassroomId,
        'teacher_id': teacherId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'assignment_type': _selectedAssignmentType,
        'total_points': int.parse(_totalPointsController.text),
        'time_limit_minutes': _hasTimeLimit && _timeLimitController.text.isNotEmpty
            ? int.parse(_timeLimitController.text)
            : null,
        'due_date': finalDueDate?.toIso8601String(),
        'is_published': publish,
        'instructions': _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
        'status': publish ? 'active' : 'draft',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.assignment == null) {
        // Create new assignment
        assignmentData['created_at'] = DateTime.now().toIso8601String();

        await Supabase.instance.client.from('assignments').insert(assignmentData);
      } else {
        // Update existing assignment
        await Supabase.instance.client.from('assignments').update(assignmentData).eq('id', widget.assignment!.id!);
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.assignment == null ? 'Assignment created successfully!' : 'Assignment updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? const TimeOfDay(hour: 23, minute: 59),
    );

    if (time != null) {
      setState(() {
        _selectedDueTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.assignment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Assignment' : 'Create Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingClassrooms
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildErrorState() {
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Classroom Selection
          _buildSectionTitle('Basic Information'),
          const SizedBox(height: 12),
          _buildClassroomDropdown(),
          const SizedBox(height: 16),

          // Assignment Type
          _buildAssignmentTypeSelector(),
          const SizedBox(height: 16),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Assignment Title *',
              hintText: 'e.g., Chapter 5 Quiz',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // Grading & Timing
          _buildSectionTitle('Grading & Timing'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _totalPointsController,
                  decoration: InputDecoration(
                    labelText: 'Total Points *',
                    prefixIcon: const Icon(Icons.star_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    final points = int.tryParse(value ?? '');
                    if (points == null || points <= 0) {
                      return 'Enter valid points';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time Limit'),
                      value: _hasTimeLimit,
                      onChanged: (value) {
                        setState(() {
                          _hasTimeLimit = value;
                          if (!value) {
                            _timeLimitController.clear();
                          }
                        });
                      },
                    ),
                    if (_hasTimeLimit)
                      TextFormField(
                        controller: _timeLimitController,
                        decoration: InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (_hasTimeLimit && (int.tryParse(value ?? '') ?? 0) <= 0) {
                            return 'Enter valid minutes';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Due Date & Time
          _buildDueDateTimeSelector(),
          const SizedBox(height: 24),

          // Description
          _buildSectionTitle('Description & Instructions'),
          const SizedBox(height: 12),

          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of the assignment',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _instructionsController,
            decoration: InputDecoration(
              labelText: 'Instructions (Optional)',
              hintText: 'Detailed instructions for students',
              prefixIcon: const Icon(Icons.list_alt),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
    );
  }

  Widget _buildClassroomDropdown() {
    if (_classrooms.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No classrooms available. Please contact admin.',
                  style: TextStyle(color: Colors.orange[900]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedClassroomId,
      decoration: InputDecoration(
        labelText: 'Classroom *',
        prefixIcon: const Icon(Icons.class_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _classrooms.map((classroom) {
        return DropdownMenuItem<String>(
          value: classroom['id'],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(classroom['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${classroom['subject']} - Grade ${classroom['grade_level']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedClassroomId = value;
        });
      },
      validator: (value) => value == null ? 'Please select a classroom' : null,
    );
  }

  Widget _buildAssignmentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment Type *',
          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _assignmentTypes.map((type) {
            final isSelected = _selectedAssignmentType == type['value'];
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type['icon'] as IconData, size: 18, color: isSelected ? Colors.white : AppColors.primary),
                  const SizedBox(width: 6),
                  Text(type['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedAssignmentType = type['value'] as String;
                });
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateTimeSelector() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Due Date & Time', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDueDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDueDate == null
                          ? 'Select Date'
                          : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedDueDate == null ? null : _selectDueTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedDueTime == null ? 'Select Time' : _selectedDueTime!.format(context)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedDueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Due: ${_formatFullDueDate()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFullDueDate() {
    if (_selectedDueDate == null) return '';

    final date = _selectedDueDate!;
    final time = _selectedDueTime ?? const TimeOfDay(hour: 23, minute: 59);
    final fullDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final now = DateTime.now();
    final difference = fullDate.difference(now);

    if (difference.inDays < 0) {
      return 'Past date';
    } else if (difference.inDays == 0) {
      return 'Today at ${time.format(context)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${time.format(context)}';
    } else {
      return 'In ${difference.inDays} days at ${time.format(context)}';
    }
  }

  Widget _buildBottomBar() {
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
                onPressed: _isLoading ? null : () => _saveAssignment(publish: false),
                icon: const Icon(Icons.save_outlined),
                label: Text(_isLoading ? 'Saving...' : 'Save as Draft'),
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
                onPressed: _isLoading ? null : () => _saveAssignment(publish: true),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.publish),
                label: Text(_isLoading ? 'Publishing...' : 'Publish Assignment'),
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
