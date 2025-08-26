class ClassModel {
  final String id;
  final String subject;
  final String topic;
  final String teacherName;
  final DateTime startTime;
  final DateTime endTime;
  final bool isLive;

  ClassModel({
    required this.id,
    required this.subject,
    required this.topic,
    required this.teacherName,
    required this.startTime,
    required this.endTime,
    this.isLive = false,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      teacherName: json['teacher_name'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      isLive: json['is_live'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'teacher_name': teacherName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_live': isLive,
    };
  }
}
