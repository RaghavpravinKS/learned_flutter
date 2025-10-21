class AttendanceModel {
  final String? id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String attendanceStatus; // present, absent, late, excused
  final DateTime? joinTime;
  final DateTime? leaveTime;
  final Duration? totalDuration;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceModel({
    this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.attendanceStatus = 'absent',
    this.joinTime,
    this.leaveTime,
    this.totalDuration,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPresent => attendanceStatus == 'present';
  bool get isAbsent => attendanceStatus == 'absent';
  bool get isLate => attendanceStatus == 'late';
  bool get isExcused => attendanceStatus == 'excused';

  String get statusDisplay {
    switch (attendanceStatus) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Late';
      case 'excused':
        return 'Excused';
      default:
        return 'Unknown';
    }
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    Duration? duration;
    if (map['total_duration'] != null) {
      // PostgreSQL interval format
      final durationStr = map['total_duration'].toString();
      final parts = durationStr.split(':');
      if (parts.length >= 2) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        duration = Duration(hours: hours, minutes: minutes);
      }
    }

    return AttendanceModel(
      id: map['id'] as String?,
      sessionId: map['session_id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String? ?? 'Unknown Student',
      studentEmail: map['student_email'] as String?,
      attendanceStatus: map['attendance_status'] as String? ?? 'absent',
      joinTime: map['join_time'] != null ? DateTime.parse(map['join_time'] as String) : null,
      leaveTime: map['leave_time'] != null ? DateTime.parse(map['leave_time'] as String) : null,
      totalDuration: duration,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'session_id': sessionId,
      'student_id': studentId,
      'attendance_status': attendanceStatus,
      'join_time': joinTime?.toIso8601String(),
      'leave_time': leaveTime?.toIso8601String(),
      'total_duration': totalDuration?.toString(),
      'notes': notes,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? attendanceStatus,
    DateTime? joinTime,
    DateTime? leaveTime,
    Duration? totalDuration,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      joinTime: joinTime ?? this.joinTime,
      leaveTime: leaveTime ?? this.leaveTime,
      totalDuration: totalDuration ?? this.totalDuration,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
