import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_progress_model.dart';

class CourseProgressRepository {
  final SupabaseClient _supabaseClient;

  CourseProgressRepository({required SupabaseClient supabaseClient}) 
      : _supabaseClient = supabaseClient;

  Future<List<CourseProgress>> getStudentCourseProgress(String studentId) async {
    final response = await _supabaseClient
        .rpc('get_student_course_progress', params: {'student_id': studentId})
        .select();

    return (response as List)
        .map((json) => CourseProgress.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateLastAccessed({
    required String courseId,
    required String studentId,
  }) async {
    await _supabaseClient
        .from('student_course_progress')
        .upsert({
          'student_id': studentId,
          'course_id': courseId,
          'last_accessed': DateTime.now().toIso8601String(),
        });
  }
}
