import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/session_model.dart';
import '../models/recurring_session_model.dart';
import '../services/teacher_service.dart';

class CreateSessionScreen extends ConsumerStatefulWidget {
  final SessionModel? session; // If provided, we're editing

  const CreateSessionScreen({super.key, this.session});

  @override
  ConsumerState<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends ConsumerState<CreateSessionScreen> with SingleTickerProviderStateMixin {
  final _oneTimeFormKey = GlobalKey<FormState>();
  final _recurringFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingUrlController = TextEditingController();

  late TabController _tabController;

  // One-time session fields
  String? _selectedClassroomId;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Recurring session fields
  String? _recurringClassroomId;
  DateTime? _recurringStartDate;
  DateTime? _recurringEndDate;
  TimeOfDay? _recurringStartTime;
  TimeOfDay? _recurringEndTime;
  bool _hasEndDate = false;
  Set<int> _selectedDays = {}; // 0=Sun, 1=Mon, ..., 6=Sat
  int _monthsAhead = 3; // Default: 3 months
  bool _useDifferentTimes = false; // Toggle for per-day times
  Map<int, TimeOfDay?> _perDayStartTimes = {}; // Start time for each day
  Map<int, TimeOfDay?> _perDayEndTimes = {}; // End time for each day

  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClassrooms();

    // If editing, populate fields (only support one-time sessions for now)
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
    _tabController.dispose();
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
        bottom: !isEditing
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'One-Time Session'),
                  Tab(text: 'Recurring Session'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEditing
          ? _buildOneTimeSessionForm(isEditing)
          : TabBarView(
              controller: _tabController,
              children: [_buildOneTimeSessionForm(isEditing), _buildRecurringSessionForm()],
            ),
    );
  }

  // Build one-time session form
  Widget _buildOneTimeSessionForm(bool isEditing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _oneTimeFormKey,
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
                    (classroom) =>
                        DropdownMenuItem(value: classroom['id'] as String, child: Text(classroom['name'] as String)),
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
                labelText: 'Meeting URL (Google Meet / Zoom) *',
                hintText: 'https://meet.google.com/...',
                prefixIcon: const Icon(Icons.video_call),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Add your Google Meet or Zoom link',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a meeting URL';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'Please enter a valid URL';
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
    );
  }

  // Build recurring session form
  Widget _buildRecurringSessionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _recurringFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Session Title *',
                hintText: 'e.g., Weekly Math Class',
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
              value: _recurringClassroomId,
              decoration: InputDecoration(
                labelText: 'Classroom *',
                prefixIcon: const Icon(Icons.school),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _classrooms
                  .map(
                    (classroom) =>
                        DropdownMenuItem(value: classroom['id'] as String, child: Text(classroom['name'] as String)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _recurringClassroomId = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a classroom';
                }
                return null;
              },
            ),

            // Show minimum hours requirement if classroom is selected
            if (_recurringClassroomId != null) _buildMinimumHoursInfo(),

            const SizedBox(height: 16),

            // Day selector
            Text('Select Days *', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildDaySelector(),
            if (_selectedDays.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Please select at least one day', style: TextStyle(color: Colors.red[700], fontSize: 12)),
              ),
            const SizedBox(height: 16),

            // Time pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _useDifferentTimes ? null : () => _selectRecurringStartTime(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Time *',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorText: !_useDifferentTimes && _recurringStartTime == null ? 'Select time' : null,
                        enabled: !_useDifferentTimes,
                      ),
                      child: Text(
                        _recurringStartTime != null ? _recurringStartTime!.format(context) : 'Select time',
                        style: TextStyle(
                          color: _useDifferentTimes
                              ? Colors.grey[400]
                              : (_recurringStartTime != null ? Colors.black : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _useDifferentTimes ? null : () => _selectRecurringEndTime(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Time *',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorText: !_useDifferentTimes && _recurringEndTime == null ? 'Select time' : null,
                        enabled: !_useDifferentTimes,
                      ),
                      child: Text(
                        _recurringEndTime != null ? _recurringEndTime!.format(context) : 'Select time',
                        style: TextStyle(
                          color: _useDifferentTimes
                              ? Colors.grey[400]
                              : (_recurringEndTime != null ? Colors.black : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle for different times per day
            Row(
              children: [
                Checkbox(
                  value: _useDifferentTimes,
                  onChanged: (value) {
                    setState(() {
                      _useDifferentTimes = value ?? false;
                      if (!_useDifferentTimes) {
                        // Clear per-day times when disabled
                        _perDayStartTimes.clear();
                        _perDayEndTimes.clear();
                      }
                    });
                  },
                ),
                Expanded(child: Text('Use different times for each day', style: GoogleFonts.poppins(fontSize: 14))),
              ],
            ),

            // Per-day time pickers (conditional)
            if (_useDifferentTimes && _selectedDays.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPerDayTimePickers(),
              const SizedBox(height: 16),
            ],

            // Start date picker
            InkWell(
              onTap: () => _selectRecurringStartDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Start Date *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _recurringStartDate == null ? 'Please select a date' : null,
                ),
                child: Text(
                  _recurringStartDate != null
                      ? '${_recurringStartDate!.day}/${_recurringStartDate!.month}/${_recurringStartDate!.year}'
                      : 'Select start date',
                  style: TextStyle(color: _recurringStartDate != null ? Colors.black : Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // End date toggle
            Row(
              children: [
                Checkbox(
                  value: _hasEndDate,
                  onChanged: (value) {
                    setState(() {
                      _hasEndDate = value ?? false;
                      if (!_hasEndDate) _recurringEndDate = null;
                    });
                  },
                ),
                Expanded(
                  child: Text('Set end date (Leave unchecked for ongoing)', style: GoogleFonts.poppins(fontSize: 14)),
                ),
              ],
            ),

            // End date picker (conditional)
            if (_hasEndDate) ...[
              InkWell(
                onTap: () => _selectRecurringEndDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: _recurringEndDate == null ? 'Please select an end date' : null,
                  ),
                  child: Text(
                    _recurringEndDate != null
                        ? '${_recurringEndDate!.day}/${_recurringEndDate!.month}/${_recurringEndDate!.year}'
                        : 'Select end date',
                    style: TextStyle(color: _recurringEndDate != null ? Colors.black : Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Generate sessions dropdown
            DropdownButtonFormField<int>(
              value: _monthsAhead,
              decoration: InputDecoration(
                labelText: 'Generate Sessions For *',
                prefixIcon: const Icon(Icons.event_repeat),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: _hasEndDate
                    ? 'All sessions until end date will be generated'
                    : 'For ongoing sessions, choose how many months to generate',
                enabled: !_hasEndDate, // Disable the field when end date is set
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 Month')),
                DropdownMenuItem(value: 2, child: Text('2 Months')),
                DropdownMenuItem(value: 3, child: Text('3 Months (Recommended)')),
                DropdownMenuItem(value: 6, child: Text('6 Months')),
                DropdownMenuItem(value: 12, child: Text('12 Months (1 Year)')),
              ],
              onChanged: _hasEndDate
                  ? null // Disable dropdown when end date is set
                  : (value) {
                      setState(() => _monthsAhead = value ?? 3);
                    },
            ),
            const SizedBox(height: 16),

            // Meeting URL
            TextFormField(
              controller: _meetingUrlController,
              decoration: InputDecoration(
                labelText: 'Meeting URL (Google Meet / Zoom) *',
                hintText: 'https://meet.google.com/...',
                prefixIcon: const Icon(Icons.video_call),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'Add your Google Meet or Zoom link',
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a meeting URL';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'Please enter a valid URL';
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
                hintText: 'Add details about the recurring session...',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Preview section
            if (_recurringStartDate != null && _selectedDays.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recurring Pattern',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(_buildRecurrenceDescription(), style: GoogleFonts.poppins(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveRecurringSession,
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
                    : const Text(
                        'Create Recurring Session',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Day selector widget
  Widget _buildDaySelector() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(index);
              } else {
                _selectedDays.remove(index);
              }
            });
          },
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }),
    );
  }

  // Helper method to get day name
  String _getDayName(int dayIndex) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayIndex];
  }

  // Per-day time pickers widget
  Widget _buildPerDayTimePickers() {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final sortedDays = _selectedDays.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set times for each day',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          ...sortedDays.map((dayIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(days[dayIndex], style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectPerDayStartTime(context, dayIndex),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  _perDayStartTimes[dayIndex]?.format(context) ??
                                      _recurringStartTime?.format(context) ??
                                      'Start time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: (_perDayStartTimes[dayIndex] != null || _recurringStartTime != null)
                                        ? Colors.black
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectPerDayEndTime(context, dayIndex),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  _perDayEndTimes[dayIndex]?.format(context) ??
                                      _recurringEndTime?.format(context) ??
                                      'End time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: (_perDayEndTimes[dayIndex] != null || _recurringEndTime != null)
                                        ? Colors.black
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Build recurrence description
  String _buildRecurrenceDescription() {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final selectedDayNames = _selectedDays.map((i) => days[i]).toList()..sort();

    final dayStr = selectedDayNames.join(', ');
    final startStr = '${_recurringStartDate!.day}/${_recurringStartDate!.month}/${_recurringStartDate!.year}';
    final endStr = _recurringEndDate != null
        ? '${_recurringEndDate!.day}/${_recurringEndDate!.month}/${_recurringEndDate!.year}'
        : 'Ongoing';

    // Add generation info
    final generationInfo = _hasEndDate
        ? '\n\nAll sessions until end date will be generated'
        : '\n\nSessions will be generated for $_monthsAhead ${_monthsAhead == 1 ? 'month' : 'months'} ahead';

    return 'Every $dayStr\nFrom $startStr to $endStr$generationInfo';
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

  // Recurring session date/time pickers
  Future<void> _selectRecurringStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recurringStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _recurringStartDate = picked);
    }
  }

  Future<void> _selectRecurringEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recurringEndDate ?? (_recurringStartDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _recurringStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _recurringEndDate = picked);
    }
  }

  Future<void> _selectRecurringStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _recurringStartTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _recurringStartTime = picked);
    }
  }

  Future<void> _selectRecurringEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _recurringEndTime ?? TimeOfDay.now());

    if (picked != null) {
      setState(() => _recurringEndTime = picked);
    }
  }

  // Per-day time pickers
  Future<void> _selectPerDayStartTime(BuildContext context, int dayIndex) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _perDayStartTimes[dayIndex] ?? _recurringStartTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _perDayStartTimes[dayIndex] = picked);
    }
  }

  Future<void> _selectPerDayEndTime(BuildContext context, int dayIndex) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _perDayEndTimes[dayIndex] ?? _recurringEndTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _perDayEndTimes[dayIndex] = picked);
    }
  }

  Future<void> _saveSession() async {
    if (!_oneTimeFormKey.currentState!.validate()) {
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

      final sessionData = <String, dynamic>{
        'classroom_id': _selectedClassroomId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'session_date': _selectedDate!.toIso8601String().split('T')[0],
        'start_time':
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
        'end_time': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00',
        'meeting_url': _meetingUrlController.text.trim(), // Now required
        'status': 'scheduled',
        'session_type': 'live',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isEditing) {
        // Check if this is a recurring instance being edited
        if (widget.session!.isRecurringInstance && widget.session!.recurringSessionId != null) {
          // Break from series by setting recurring_session_id to NULL
          sessionData['recurring_session_id'] = null;
          sessionData['is_recurring_instance'] = false;
        }

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

  Future<void> _saveRecurringSession() async {
    if (!_recurringFormKey.currentState!.validate()) {
      return;
    }

    // Validate recurring-specific fields
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select at least one day for recurrence')));
      return;
    }

    if (_recurringStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a start date')));
      return;
    }

    // Validate times based on mode
    if (_useDifferentTimes) {
      // Validate per-day times
      bool allTimesSet = true;
      for (int day in _selectedDays) {
        if (_perDayStartTimes[day] == null || _perDayEndTimes[day] == null) {
          allTimesSet = false;
          break;
        }

        // Validate end time is after start time for each day
        final startMinutes = _perDayStartTimes[day]!.hour * 60 + _perDayStartTimes[day]!.minute;
        final endMinutes = _perDayEndTimes[day]!.hour * 60 + _perDayEndTimes[day]!.minute;

        if (endMinutes <= startMinutes) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('End time must be after start time for ${_getDayName(day)}')));
          return;
        }
      }

      if (!allTimesSet) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select start and end times for all selected days')));
        return;
      }
    } else {
      // Validate global times
      if (_recurringStartTime == null || _recurringEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end times')));
        return;
      }

      // Validate end time is after start time
      final startMinutes = _recurringStartTime!.hour * 60 + _recurringStartTime!.minute;
      final endMinutes = _recurringEndTime!.hour * 60 + _recurringEndTime!.minute;

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
        return;
      }
    }

    // Validate end date is after start date (if provided)
    if (_hasEndDate && _recurringEndDate != null) {
      if (_recurringEndDate!.isBefore(_recurringStartDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be after start date')));
        return;
      }

      // Validate minimum duration of 30 days (1 month)
      final durationInDays = _recurringEndDate!.difference(_recurringStartDate!).inDays;
      if (durationInDays < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recurring sessions must span at least 30 days (1 month).\n'
              'Current duration: $durationInDays days.\n'
              'Please extend the end date or select "No end date".',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
    } else if (!_hasEndDate) {
      // If no end date is set, it's considered valid (ongoing session)
      // The system will use the monthsAhead parameter for generation
    }

    // CLIENT-SIDE VALIDATION: Calculate and validate hours BEFORE any backend call
    final minimumRequired = _getSelectedClassroomMinimumHours();

    // Determine start and end times
    final startTime = _useDifferentTimes ? _perDayStartTimes[_selectedDays.first]! : _recurringStartTime!;
    final endTime = _useDifferentTimes ? _perDayEndTimes[_selectedDays.first]! : _recurringEndTime!;

    // Calculate hours per session
    final hoursPerSession = (endTime.hour * 60 + endTime.minute - startTime.hour * 60 - startTime.minute) / 60.0;

    // Calculate sessions per week
    final sessionsPerWeek = _selectedDays.length;

    // Calculate duration
    final effectiveDuration = _hasEndDate && _recurringEndDate != null
        ? _recurringEndDate!.difference(_recurringStartDate!).inDays
        : 30 * _monthsAhead;

    // Calculate total and monthly hours
    final totalWeeks = effectiveDuration / 7.0;
    final totalHours = hoursPerSession * sessionsPerWeek * totalWeeks;
    final monthlyHours = (totalHours * 30.0) / effectiveDuration;

    print('📊 Client-side validation:');
    print('   Hours per session: ${hoursPerSession.toStringAsFixed(2)}');
    print('   Sessions per week: $sessionsPerWeek');
    print('   Duration: $effectiveDuration days');
    print('   Calculated monthly hours: ${monthlyHours.toStringAsFixed(2)}');
    print('   Minimum required: ${minimumRequired.toStringAsFixed(2)}');

    // VALIDATE: Check if hours meet minimum requirement
    if (minimumRequired > 0 && monthlyHours < minimumRequired) {
      // Hours are insufficient - show error dialog and stop
      final shortfall = minimumRequired - monthlyHours;
      final percentageShort = (shortfall / minimumRequired * 100).toStringAsFixed(0);

      print('❌ Validation failed: Insufficient hours');
      print('   Required: ${minimumRequired.toStringAsFixed(1)} hrs/month');
      print('   Calculated: ${monthlyHours.toStringAsFixed(1)} hrs/month');
      print('   Shortfall: ${shortfall.toStringAsFixed(1)} hrs ($percentageShort% short)');

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Text('Insufficient Session Hours'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This classroom requires at least ${minimumRequired.toStringAsFixed(0)} hours per month.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Text('Current schedule provides:'),
              const SizedBox(height: 8),
              _buildValidationInfo('Monthly Hours', '${monthlyHours.toStringAsFixed(1)} hrs', false),
              _buildValidationInfo('Sessions per Week', '$sessionsPerWeek', true),
              _buildValidationInfo('Hours per Session', '${hoursPerSession.toStringAsFixed(1)} hrs', true),
              _buildValidationInfo('Duration', '$effectiveDuration days', true),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Suggestions:',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Add more days per week', style: TextStyle(fontSize: 13)),
                    const Text('• Extend session duration', style: TextStyle(fontSize: 13)),
                    const Text('• Extend the end date', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK, I\'ll Adjust'))],
        ),
      );
      return; // Stop here - don't proceed to backend
    }

    print('✅ Client-side validation passed! Proceeding with session creation...');

    // ALL VALIDATIONS PASSED - Now proceed with backend save
    setState(() => _isSaving = true);

    try {
      final teacherService = TeacherService();

      // Validation successful - now create the recurring session
      print('🔄 Starting recurring session creation...');
      final supabase = Supabase.instance.client;

      // Determine start and end times for the recurring session template
      TimeOfDay templateStartTime;
      TimeOfDay templateEndTime;

      if (_useDifferentTimes) {
        print('📅 Using different times for each day');
        // Use the times from the first selected day as template
        final firstDay = _selectedDays.first;
        templateStartTime = _perDayStartTimes[firstDay]!;
        templateEndTime = _perDayEndTimes[firstDay]!;
        print(
          '   First day: $firstDay, Start: ${templateStartTime.format(context)}, End: ${templateEndTime.format(context)}',
        );
      } else {
        print('📅 Using global times');
        // Use global times
        templateStartTime = _recurringStartTime!;
        templateEndTime = _recurringEndTime!;
        print('   Start: ${templateStartTime.format(context)}, End: ${templateEndTime.format(context)}');
      }

      // Create recurring session model
      final recurringSession = RecurringSessionModel(
        id: supabase.auth.currentUser!.id, // Temporary, will be replaced by database
        classroomId: _recurringClassroomId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        recurrenceType: 'weekly',
        recurrenceDays: _selectedDays.toList()..sort(),
        startTime:
            '${templateStartTime.hour.toString().padLeft(2, '0')}:${templateStartTime.minute.toString().padLeft(2, '0')}:00',
        endTime:
            '${templateEndTime.hour.toString().padLeft(2, '0')}:${templateEndTime.minute.toString().padLeft(2, '0')}:00',
        startDate: _recurringStartDate!,
        endDate: _hasEndDate ? _recurringEndDate : null,
        sessionType: 'live',
        meetingUrl: _meetingUrlController.text.trim(), // Now required
        isRecorded: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📝 Recurring session details:');
      print('   Classroom ID: ${_recurringClassroomId}');
      print('   Title: ${_titleController.text.trim()}');
      print('   Recurrence days: ${_selectedDays.toList()..sort()}');
      print('   Start date: ${_recurringStartDate}');
      print('   End date: ${_hasEndDate ? _recurringEndDate : 'Ongoing'}');
      print('   Meeting URL: ${_meetingUrlController.text.trim()}');

      // Create recurring session in database
      print('💾 Creating recurring session in database...');
      final recurringSessionId = await teacherService.createRecurringSession(recurringSession);
      print('✅ Recurring session created with ID: $recurringSessionId');

      int generatedCount = 0;

      // If using different times per day, generate instances manually
      if (_useDifferentTimes) {
        print('🔧 Generating instances with custom times...');
        generatedCount = await _generateInstancesWithCustomTimes(supabase, recurringSessionId, _recurringClassroomId!);
        print('✅ Generated $generatedCount instances with custom times');
      } else {
        print('🔧 Generating instances using standard function (${_monthsAhead} months ahead)...');
        // Use standard generation function
        generatedCount = await teacherService.generateSessionInstances(
          recurringSessionId: recurringSessionId,
          monthsAhead: _monthsAhead,
        );
        print('✅ Generated $generatedCount instances');
      }

      print('🎉 Recurring session creation complete!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recurring session created successfully! $generatedCount sessions generated.')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e, stackTrace) {
      print('❌ Error creating recurring session: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating recurring session: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Generate instances with custom per-day times
  Future<int> _generateInstancesWithCustomTimes(
    SupabaseClient supabase,
    String recurringSessionId,
    String classroomId,
  ) async {
    final startDate = _recurringStartDate!;
    final endDate = _hasEndDate && _recurringEndDate != null
        ? _recurringEndDate!
        : startDate.add(Duration(days: 30 * _monthsAhead));

    // Safety: max 1 year
    final maxDate = DateTime.now().add(const Duration(days: 365));
    final actualEndDate = endDate.isAfter(maxDate) ? maxDate : endDate;

    int count = 0;
    DateTime currentDate = startDate;

    while (currentDate.isBefore(actualEndDate) || currentDate.isAtSameMomentAs(actualEndDate)) {
      final dayOfWeek = currentDate.weekday % 7; // Convert to 0=Sun format

      if (_selectedDays.contains(dayOfWeek)) {
        // Get times for this day (fallback to default if not set)
        final startTime = _perDayStartTimes[dayOfWeek] ?? _recurringStartTime!;
        final endTime = _perDayEndTimes[dayOfWeek] ?? _recurringEndTime!;

        // Create session instance
        await supabase.from('class_sessions').insert({
          'classroom_id': classroomId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          'session_date': currentDate.toIso8601String().split('T')[0],
          'start_time':
              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
          'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
          'session_type': 'live',
          'meeting_url': _meetingUrlController.text.trim(), // Now required
          'is_recorded': false,
          'status': 'scheduled',
          'recurring_session_id': recurringSessionId,
          'is_recurring_instance': true,
        });

        count++;
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return count;
  }

  // Helper widget to display validation info rows
  Widget _buildValidationInfo(String label, String value, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isValid ? Colors.grey[800] : Colors.red[700],
                ),
              ),
              if (!isValid) ...[const SizedBox(width: 4), Icon(Icons.warning_amber, size: 14, color: Colors.red[700])],
            ],
          ),
        ],
      ),
    );
  }

  // Get minimum hours for selected classroom
  double _getSelectedClassroomMinimumHours() {
    if (_recurringClassroomId == null) return 0;

    final classroom = _classrooms.firstWhere((c) => c['id'] == _recurringClassroomId, orElse: () => {});

    final minimumHours = classroom['minimum_monthly_hours'];
    if (minimumHours == null) return 0;

    return (minimumHours as num).toDouble();
  }

  // Build minimum hours info widget
  Widget _buildMinimumHoursInfo() {
    final minimumHours = _getSelectedClassroomMinimumHours();

    if (minimumHours <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This classroom requires at least ${minimumHours.toStringAsFixed(0)} hours per month',
              style: TextStyle(fontSize: 13, color: Colors.blue[900], fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
