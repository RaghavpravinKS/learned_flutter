
class Assignment {
  final String id;
  final String title;
  final String description;
  final String classId;
  final DateTime dueDate;
  final DateTime? submittedAt;
  final String? submissionUrl;
  final double? grade;
  final String status; // 'pending', 'submitted', 'graded', 'late'
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.classId,
    required this.dueDate,
    this.submittedAt,
    this.submissionUrl,
    this.grade,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      classId: json['class_id'] as String,
      dueDate: DateTime.parse(json['due_date'] as String).toLocal(),
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at'] as String).toLocal() 
          : null,
      submissionUrl: json['submission_url'] as String?,
      grade: json['grade']?.toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'class_id': classId,
      'due_date': dueDate.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'submission_url': submissionUrl,
      'grade': grade,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Assignment copyWith({
    String? id,
    String? title,
    String? description,
    String? classId,
    DateTime? dueDate,
    DateTime? submittedAt,
    String? submissionUrl,
    double? grade,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      classId: classId ?? this.classId,
      dueDate: dueDate ?? this.dueDate,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionUrl: submissionUrl ?? this.submissionUrl,
      grade: grade ?? this.grade,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
