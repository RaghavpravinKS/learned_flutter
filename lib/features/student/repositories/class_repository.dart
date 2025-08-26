import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_model.dart';

class ClassRepository {
  final SupabaseClient _supabaseClient;

  ClassRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  // Get upcoming classes for a student
  Future<List<ClassModel>> getUpcomingClasses(String studentId) async {
    try {
      final response = await _supabaseClient
          .from('class_sessions')
          .select('''
            *, 
            subjects:subject_id(name),
            teachers:teacher_id(name)
          ''')
          .eq('student_id', studentId)
          .gte('start_time', DateTime.now().toIso8601String())
          .order('start_time', ascending: true)
          .limit(5);

      if (response == null) return [];

      return (response as List)
          .map((json) => ClassModel.fromJson({
                'id': json['id'],
                'subject': json['subjects']?['name'] ?? 'No Subject',
                'topic': json['topic'] ?? 'No Topic',
                'teacher_name': json['teachers']?['name'] ?? 'Teacher',
                'start_time': json['start_time'],
                'end_time': json['end_time'],
                'is_live': json['is_live'] ?? false,
              }))
          .toList();
    } catch (e) {
      print('Error fetching upcoming classes: $e');
      rethrow;
    }
  }

  // Join a class session
  Future<void> joinClass(String classId, String studentId) async {
    try {
      await _supabaseClient.from('class_attendance').insert({
        'class_id': classId,
        'student_id': studentId,
        'joined_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error joining class: $e');
      rethrow;
    }
  }
}
