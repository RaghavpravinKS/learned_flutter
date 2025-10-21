class SubmissionModel {
  final String? id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final int attemptNumber;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final double? score;
  final double? maxScore;
  final double? percentage;
  final Duration? timeTaken;
  final Map<String, dynamic>? answers;
  final String? feedback;
  final bool isGraded;
  final String? gradedBy;
  final DateTime? gradedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubmissionModel({
    this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.attemptNumber = 1,
    this.startedAt,
    this.submittedAt,
    this.score,
    this.maxScore,
    this.percentage,
    this.timeTaken,
    this.answers,
    this.feedback,
    this.isGraded = false,
    this.gradedBy,
    this.gradedAt,
    this.createdAt,
    this.updatedAt,
  });

  // Helper getters
  bool get isSubmitted => submittedAt != null;
  bool get isPending => isSubmitted && !isGraded;
  bool get isLateSubmission {
    // This would need due date from assignment to calculate
    // For now, just return false
    return false;
  }

  String get submissionStatus {
    if (!isSubmitted) return 'Not Submitted';
    if (isGraded) return 'Graded';
    return 'Pending Review';
  }

  String get formattedSubmittedDate {
    if (submittedAt == null) return 'Not submitted';

    final now = DateTime.now();
    final difference = now.difference(submittedAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${submittedAt!.day}/${submittedAt!.month}/${submittedAt!.year}';
    }
  }

  String get formattedTimeTaken {
    if (timeTaken == null) return 'N/A';

    final hours = timeTaken!.inHours;
    final minutes = timeTaken!.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get scoreDisplay {
    if (score == null || maxScore == null) return 'Not graded';
    return '${score!.toStringAsFixed(1)}/${maxScore!.toStringAsFixed(0)}';
  }

  String get percentageDisplay {
    if (percentage == null) return 'N/A';
    return '${percentage!.toStringAsFixed(1)}%';
  }

  // Factory method to create from Supabase map
  factory SubmissionModel.fromMap(Map<String, dynamic> map) {
    Duration? timeTaken;
    if (map['time_taken'] != null) {
      // PostgreSQL interval format: "HH:MM:SS" or similar
      final timeParts = map['time_taken'].toString().split(':');
      if (timeParts.length >= 2) {
        final hours = int.tryParse(timeParts[0]) ?? 0;
        final minutes = int.tryParse(timeParts[1]) ?? 0;
        timeTaken = Duration(hours: hours, minutes: minutes);
      }
    }

    return SubmissionModel(
      id: map['id'] as String?,
      assignmentId: map['assignment_id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String? ?? 'Unknown Student',
      studentEmail: map['student_email'] as String?,
      attemptNumber: map['attempt_number'] as int? ?? 1,
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at'] as String) : null,
      submittedAt: map['submitted_at'] != null ? DateTime.parse(map['submitted_at'] as String) : null,
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
      maxScore: map['max_score'] != null ? (map['max_score'] as num).toDouble() : null,
      percentage: map['percentage'] != null ? (map['percentage'] as num).toDouble() : null,
      timeTaken: timeTaken,
      answers: map['answers'] as Map<String, dynamic>?,
      feedback: map['feedback'] as String?,
      isGraded: map['is_graded'] as bool? ?? false,
      gradedBy: map['graded_by'] as String?,
      gradedAt: map['graded_at'] != null ? DateTime.parse(map['graded_at'] as String) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  // Convert to map for Supabase insert/update
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'assignment_id': assignmentId,
      'student_id': studentId,
      'attempt_number': attemptNumber,
      'started_at': startedAt?.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'score': score,
      'max_score': maxScore,
      'percentage': percentage,
      'time_taken': timeTaken?.toString(),
      'answers': answers,
      'feedback': feedback,
      'is_graded': isGraded,
      'graded_by': gradedBy,
      'graded_at': gradedAt?.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? studentEmail,
    int? attemptNumber,
    DateTime? startedAt,
    DateTime? submittedAt,
    double? score,
    double? maxScore,
    double? percentage,
    Duration? timeTaken,
    Map<String, dynamic>? answers,
    String? feedback,
    bool? isGraded,
    String? gradedBy,
    DateTime? gradedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      percentage: percentage ?? this.percentage,
      timeTaken: timeTaken ?? this.timeTaken,
      answers: answers ?? this.answers,
      feedback: feedback ?? this.feedback,
      isGraded: isGraded ?? this.isGraded,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
