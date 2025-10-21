import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/session_model.dart';
import '../services/teacher_service.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  final SessionModel? session; // If provided, we're editing

  const CreateSessionScreen({super.key, this.session});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingUrlController = TextEditingController();

  String? _selectedClassroomId;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();

    // If editing, populate fields
    if (widget.session != null) {
      _titleController.text = widget.session!.title;
      _descriptionController.text = widget.session!.description ?? '';
      _meetingUrlController.text = widget.session!.meetingUrl ?? '';
      _selectedClassroomId = widget.session!.classroomId;
      _selectedDate = widget.session!.sessionDate;
      _startTime = _parseTimeString(widget.session!.startTime);
      _endTime = _parseTimeString(widget.session!.endTime);
    }
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoading = true);

    try {
      final teacherService = TeacherService();
      final teacherId = await teacherService.getCurrentTeacherId();

      if (teacherId == null) {
        throw Exception('Teacher not found');
      }

      final classrooms = await teacherService.getTeacherClassrooms(teacherId);

      setState(() {
        _classrooms = classrooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading classrooms: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _meetingUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.session != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Session' : 'Create Session',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Session Title *',
                        hintText: 'e.g., Introduction to Algebra',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a session title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Classroom dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedClassroomId,
                      decoration: InputDecoration(
                        labelText: 'Classroom *',
                        prefixIcon: const Icon(Icons.school),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _classrooms
                          .map(
                            (classroom) => DropdownMenuItem(
                              value: classroom['id'] as String,
                              child: Text(classroom['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedClassroomId = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a classroom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Session Date *',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorText: _selectedDate == null ? 'Please select a date' : null,
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select date',
                          style: TextStyle(color: _selectedDate != null ? Colors.black : Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectStartTime(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Start Time *',
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                errorText: _startTime == null ? 'Select time' : null,
                              ),
                              child: Text(
                                _startTime != null ? _startTime!.format(context) : 'Select time',
                                style: TextStyle(color: _startTime != null ? Colors.black : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectEndTime(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'End Time *',
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                errorText: _endTime == null ? 'Select time' : null,
                              ),
                              child: Text(
                                _endTime != null ? _endTime!.format(context) : 'Select time',
                                style: TextStyle(color: _endTime != null ? Colors.black : Colors.grey[600]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Meeting URL
                    TextFormField(
                      controller: _meetingUrlController,
                      decoration: InputDecoration(
                        labelText: 'Meeting URL (Google Meet / Zoom)',
                        hintText: 'https://meet.google.com/...',
                        prefixIcon: const Icon(Icons.video_call),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        helperText: 'Optional: Add your Google Meet or Zoom link',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.startsWith('http://') && !value.startsWith('https://')) {
                            return 'Please enter a valid URL';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add details about the session...',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isEditing ? 'Update Session' : 'Create Session',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay.now());

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.now());

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end times')));
      return;
    }

    // Validate end time is after start time
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final isEditing = widget.session != null;

      final sessionData = {
        'classroom_id': _selectedClassroomId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'session_date': _selectedDate!.toIso8601String().split('T')[0],
        'start_time':
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
        'end_time': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00',
        'meeting_url': _meetingUrlController.text.trim().isEmpty ? null : _meetingUrlController.text.trim(),
        'status': 'scheduled',
        'session_type': 'live',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isEditing) {
        // Update existing session
        await supabase.from('class_sessions').update(sessionData).eq('id', widget.session!.id);
      } else {
        // Create new session
        await supabase.from('class_sessions').insert(sessionData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Session updated successfully' : 'Session created successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving session: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
