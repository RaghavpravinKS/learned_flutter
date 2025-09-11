class SessionModel {
  final String id;
  final String subject;
  final String topic;
  final String teacherName;
  final String classroomId;
  final String classroomName;
  final DateTime startTime;
  final DateTime endTime;
  final bool isLive;

  SessionModel({
    required this.id,
    required this.subject,
    required this.topic,
    required this.teacherName,
    required this.classroomId,
    required this.classroomName,
    required this.startTime,
    required this.endTime,
    this.isLive = false,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      subject: map['subject'] as String,
      topic: map['topic'] as String,
      teacherName: map['teacher_name'] as String,
      classroomId: map['classroom_id'] as String,
      classroomName: map['classroom_name'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      isLive: map['is_live'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'teacher_name': teacherName,
      'classroom_id': classroomId,
      'classroom_name': classroomName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_live': isLive,
    };
  }
}
