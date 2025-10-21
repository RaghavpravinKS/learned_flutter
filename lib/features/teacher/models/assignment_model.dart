class AssignmentModel {
  final String? id;
  final String classroomId;
  final String? classroomName;
  final String teacherId;
  final String title;
  final String? description;
  final String assignmentType;
  final int totalPoints;
  final int? timeLimitMinutes;
  final DateTime? dueDate;
  final bool isPublished;
  final String? instructions;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional fields for display
  final int? submissionCount;
  final int? gradedCount;

  AssignmentModel({
    this.id,
    required this.classroomId,
    this.classroomName,
    required this.teacherId,
    required this.title,
    this.description,
    required this.assignmentType,
    required this.totalPoints,
    this.timeLimitMinutes,
    this.dueDate,
    this.isPublished = false,
    this.instructions,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.submissionCount,
    this.gradedCount,
  });

  // Helper getters
  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  bool get isPastDue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    final now = DateTime.now();
    final difference = dueDate!.difference(now);

    if (difference.inDays < 0) {
      return 'Overdue by ${-difference.inDays} days';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays} days';
    } else {
      return 'Due ${dueDate!.toLocal().toString().split(' ')[0]}';
    }
  }

  String get typeDisplay {
    switch (assignmentType.toLowerCase()) {
      case 'quiz':
        return 'Quiz';
      case 'test':
        return 'Test';
      case 'assignment':
        return 'Assignment';
      case 'project':
        return 'Project';
      default:
        return assignmentType;
    }
  }

  double? get completionPercentage {
    if (submissionCount == null || submissionCount == 0) return null;
    // This would need total enrolled students count to be accurate
    return null;
  }

  // Factory method to create from Supabase map
  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] as String?,
      classroomId: map['classroom_id'] as String,
      classroomName: map['classroom_name'] as String?,
      teacherId: map['teacher_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      assignmentType: map['assignment_type'] as String,
      totalPoints: map['total_points'] as int,
      timeLimitMinutes: map['time_limit_minutes'] as int?,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      isPublished: map['is_published'] as bool? ?? false,
      instructions: map['instructions'] as String?,
      status: map['status'] as String? ?? 'draft',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      submissionCount: map['submission_count'] as int?,
      gradedCount: map['graded_count'] as int?,
    );
  }

  // Convert to map for Supabase insert/update
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'classroom_id': classroomId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'assignment_type': assignmentType,
      'total_points': totalPoints,
      'time_limit_minutes': timeLimitMinutes,
      'due_date': dueDate?.toIso8601String(),
      'is_published': isPublished,
      'instructions': instructions,
      'status': status,
    };
  }

  // Create a copy with updated fields
  AssignmentModel copyWith({
    String? id,
    String? classroomId,
    String? classroomName,
    String? teacherId,
    String? title,
    String? description,
    String? assignmentType,
    int? totalPoints,
    int? timeLimitMinutes,
    DateTime? dueDate,
    bool? isPublished,
    String? instructions,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? submissionCount,
    int? gradedCount,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      classroomName: classroomName ?? this.classroomName,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignmentType: assignmentType ?? this.assignmentType,
      totalPoints: totalPoints ?? this.totalPoints,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      dueDate: dueDate ?? this.dueDate,
      isPublished: isPublished ?? this.isPublished,
      instructions: instructions ?? this.instructions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submissionCount: submissionCount ?? this.submissionCount,
      gradedCount: gradedCount ?? this.gradedCount,
    );
  }
}
