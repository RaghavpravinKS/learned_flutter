class SessionModel {
  final String id;
  final String classroomId;
  final String classroomName; // For display
  final String title;
  final String? description;
  final DateTime sessionDate;
  final String startTime; // Format: "HH:mm:ss"
  final String endTime; // Format: "HH:mm:ss"
  final String sessionType;
  final String? meetingUrl;
  final String? recordingUrl;
  final bool isRecorded;
  final String status; // scheduled, in_progress, completed, cancelled
  final String? recurringSessionId; // NEW: Links to recurring_sessions
  final bool isRecurringInstance; // NEW: True if auto-generated from recurring pattern
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionModel({
    required this.id,
    required this.classroomId,
    required this.classroomName,
    required this.title,
    this.description,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    this.sessionType = 'live',
    this.meetingUrl,
    this.recordingUrl,
    this.isRecorded = false,
    this.status = 'scheduled',
    this.recurringSessionId, // NEW
    this.isRecurringInstance = false, // NEW
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      classroomId: map['classroom_id'] as String,
      classroomName: map['classroom_name'] as String? ?? 'Unknown Classroom',
      title: map['title'] as String,
      description: map['description'] as String?,
      sessionDate: DateTime.parse(map['session_date'] as String),
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      sessionType: map['session_type'] as String? ?? 'live',
      meetingUrl: map['meeting_url'] as String?,
      recordingUrl: map['recording_url'] as String?,
      isRecorded: map['is_recorded'] as bool? ?? false,
      status: map['status'] as String? ?? 'scheduled',
      recurringSessionId: map['recurring_session_id'] as String?, // NEW
      isRecurringInstance: map['is_recurring_instance'] as bool? ?? false, // NEW
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
      'session_date': sessionDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'session_type': sessionType,
      'meeting_url': meetingUrl,
      'recording_url': recordingUrl,
      'is_recorded': isRecorded,
      'status': status,
      'recurring_session_id': recurringSessionId, // NEW
      'is_recurring_instance': isRecurringInstance, // NEW
    };
  }

  SessionModel copyWith({
    String? id,
    String? classroomId,
    String? classroomName,
    String? title,
    String? description,
    DateTime? sessionDate,
    String? startTime,
    String? endTime,
    String? sessionType,
    String? meetingUrl,
    String? recordingUrl,
    bool? isRecorded,
    String? status,
    String? recurringSessionId, // NEW
    bool? isRecurringInstance, // NEW
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      classroomName: classroomName ?? this.classroomName,
      title: title ?? this.title,
      description: description ?? this.description,
      sessionDate: sessionDate ?? this.sessionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionType: sessionType ?? this.sessionType,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      isRecorded: isRecorded ?? this.isRecorded,
      status: status ?? this.status,
      recurringSessionId: recurringSessionId ?? this.recurringSessionId, // NEW
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance, // NEW
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to get formatted date and time
  String get formattedDate {
    return '${sessionDate.day}/${sessionDate.month}/${sessionDate.year}';
  }

  String get formattedTimeRange {
    return '$startTime - $endTime';
  }

  // Check if session is in the future
  bool get isFuture {
    final now = DateTime.now();
    final sessionDateTime = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
    return sessionDateTime.isAfter(now) || sessionDateTime.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
  }

  // Check if session is today
  bool get isToday {
    final now = DateTime.now();
    return sessionDate.year == now.year && sessionDate.month == now.month && sessionDate.day == now.day;
  }
}
