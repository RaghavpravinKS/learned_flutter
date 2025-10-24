class Assignment {
  final String id;
  final String title;
  final String? description;
  final String classId;
  final String? className;
  final String? teacherName;
  final DateTime? dueDate;
  final DateTime? submittedAt;
  final String? submissionUrl;
  final double? score;
  final double? maxScore;
  final double? grade;
  final String? feedback;
  final String? gradedBy;
  final DateTime? gradedAt;
  final String status; // 'pending', 'submitted', 'graded', 'late'
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.title,
    this.description,
    required this.classId,
    this.className,
    this.teacherName,
    this.dueDate,
    this.submittedAt,
    this.submissionUrl,
    this.score,
    this.maxScore,
    this.grade,
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      classId: json['classroom_id'] as String,
      className: json['classroom_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String).toLocal() : null,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String).toLocal() : null,
      submissionUrl: json['submission_url'] as String?,
      score: json['score']?.toDouble(),
      maxScore: json['max_score']?.toDouble(),
      grade: json['grade']?.toDouble(),
      feedback: json['feedback'] as String?,
      gradedBy: json['graded_by'] as String?,
      gradedAt: json['graded_at'] != null ? DateTime.parse(json['graded_at'] as String).toLocal() : null,
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
      'classroom_id': classId,
      'due_date': dueDate?.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'submission_url': submissionUrl,
      'score': score,
      'max_score': maxScore,
      'grade': grade,
      'feedback': feedback,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
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
    String? className,
    String? teacherName,
    DateTime? dueDate,
    DateTime? submittedAt,
    String? submissionUrl,
    double? score,
    double? maxScore,
    double? grade,
    String? feedback,
    String? gradedBy,
    DateTime? gradedAt,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherName: teacherName ?? this.teacherName,
      dueDate: dueDate ?? this.dueDate,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionUrl: submissionUrl ?? this.submissionUrl,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
