class RecurringSessionModel {
  final String id;
  final String classroomId;
  final String title;
  final String? description;
  final String recurrenceType; // 'weekly' or 'daily'
  final List<int> recurrenceDays; // 0=Sunday, 1=Monday, ..., 6=Saturday
  final String startTime; // HH:MM format
  final String endTime; // HH:MM format
  final DateTime startDate;
  final DateTime? endDate; // null = ongoing forever
  final String sessionType;
  final String? meetingUrl;
  final bool isRecorded;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringSessionModel({
    required this.id,
    required this.classroomId,
    required this.title,
    this.description,
    required this.recurrenceType,
    required this.recurrenceDays,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    this.endDate,
    this.sessionType = 'live',
    this.meetingUrl,
    this.isRecorded = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringSessionModel.fromMap(Map<String, dynamic> map) {
    return RecurringSessionModel(
      id: map['id'] as String,
      classroomId: map['classroom_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      recurrenceType: map['recurrence_type'] as String,
      recurrenceDays: (map['recurrence_days'] as List<dynamic>).map((e) => e as int).toList(),
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      sessionType: map['session_type'] as String? ?? 'live',
      meetingUrl: map['meeting_url'] as String?,
      isRecorded: map['is_recorded'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classroom_id': classroomId,
      'title': title,
      'description': description,
      'recurrence_type': recurrenceType,
      'recurrence_days': recurrenceDays,
      'start_time': startTime,
      'end_time': endTime,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'session_type': sessionType,
      'meeting_url': meetingUrl,
      'is_recorded': isRecorded,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RecurringSessionModel copyWith({
    String? id,
    String? classroomId,
    String? title,
    String? description,
    String? recurrenceType,
    List<int>? recurrenceDays,
    String? startTime,
    String? endTime,
    DateTime? startDate,
    DateTime? endDate,
    String? sessionType,
    String? meetingUrl,
    bool? isRecorded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringSessionModel(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      title: title ?? this.title,
      description: description ?? this.description,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceDays: recurrenceDays ?? this.recurrenceDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sessionType: sessionType ?? this.sessionType,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      isRecorded: isRecorded ?? this.isRecorded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to get day names from recurrence_days
  List<String> get dayNames {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return recurrenceDays.map((day) => days[day]).toList();
  }

  // Helper to get formatted date range
  String get formattedDateRange {
    final start = '${startDate.day}/${startDate.month}/${startDate.year}';
    if (endDate == null) {
      return '$start - Ongoing';
    }
    final end = '${endDate!.day}/${endDate!.month}/${endDate!.year}';
    return '$start - $end';
  }

  // Helper to get formatted time range
  String get formattedTimeRange {
    return '$startTime - $endTime';
  }

  // Helper to check if recurring session is still active
  bool get isActive {
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }
}
