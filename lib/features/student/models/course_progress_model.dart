class CourseProgress {
  final String courseId;
  final String courseName;
  final String? courseImageUrl;
  final String teacherName;
  final int totalLessons;
  final int completedLessons;
  final DateTime? lastAccessed;
  final double progress; // 0.0 to 1.0
  final String status; // 'not_started', 'in_progress', 'completed'

  CourseProgress({
    required this.courseId,
    required this.courseName,
    this.courseImageUrl,
    required this.teacherName,
    required this.totalLessons,
    required this.completedLessons,
    this.lastAccessed,
    required this.progress,
    required this.status,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['course_id'] as String,
      courseName: json['course_name'] as String,
      courseImageUrl: json['course_image_url'] as String?,
      teacherName: json['teacher_name'] as String,
      totalLessons: json['total_lessons'] as int,
      completedLessons: json['completed_lessons'] as int,
      lastAccessed: json['last_accessed'] != null 
          ? DateTime.parse(json['last_accessed'] as String).toLocal() 
          : null,
      progress: (json['progress'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'course_name': courseName,
      'course_image_url': courseImageUrl,
      'teacher_name': teacherName,
      'total_lessons': totalLessons,
      'completed_lessons': completedLessons,
      'last_accessed': lastAccessed?.toIso8601String(),
      'progress': progress,
      'status': status,
    };
  }

  CourseProgress copyWith({
    String? courseId,
    String? courseName,
    String? courseImageUrl,
    String? teacherName,
    int? totalLessons,
    int? completedLessons,
    DateTime? lastAccessed,
    double? progress,
    String? status,
  }) {
    return CourseProgress(
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      courseImageUrl: courseImageUrl ?? this.courseImageUrl,
      teacherName: teacherName ?? this.teacherName,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}
