import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get teacher's assigned classrooms with student counts and basic stats
  Future<List<Map<String, dynamic>>> getTeacherClassrooms(String teacherId) async {
    try {
      // Get classrooms assigned to this teacher
      final classroomsResponse = await _supabase
          .from('classrooms')
          .select('''
            id,
            name,
            description,
            subject,
            grade_level,
            board,
            max_students,
            current_students,
            is_active,
            created_at,
            updated_at
          ''')
          .eq('teacher_id', teacherId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final classrooms = List<Map<String, dynamic>>.from(classroomsResponse);

      // For each classroom, get additional statistics
      for (var classroom in classrooms) {
        final classroomId = classroom['id'];

        // Get active student enrollment count
        final enrollmentResponse = await _supabase
            .from('student_enrollments')
            .select('id')
            .eq('classroom_id', classroomId)
            .eq('status', 'active');

        classroom['active_enrollments'] = enrollmentResponse.length;

        // Set default values for counts that require RLS permissions
        // These will be loaded separately when viewing classroom details
        classroom['assignment_count'] = 0;
        classroom['materials_count'] = 0;
        classroom['recent_sessions'] = 0;
      }

      return classrooms;
    } catch (e) {
      print('Error fetching teacher classrooms: $e');
      return [];
    }
  }

  /// Get teacher profile information
  Future<Map<String, dynamic>?> getTeacherProfile(String teacherId) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select('''
            id,
            teacher_id,
            qualifications,
            experience_years,
            specializations,
            bio,
            is_verified,
            rating,
            total_reviews,
            status,
            users(
              first_name,
              last_name,
              email,
              phone_number,
              profile_image_url
            )
          ''')
          .eq('id', teacherId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching teacher profile: $e');
      return null;
    }
  }

  /// Get teacher ID from current user
  Future<String?> getCurrentTeacherId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase.from('teachers').select('id').eq('user_id', user.id).single();

      return response['id'] as String?;
    } catch (e) {
      print('Error getting current teacher ID: $e');
      return null;
    }
  }

  /// Get classroom statistics for dashboard
  Future<Map<String, int>> getTeacherStatistics(String teacherId) async {
    try {
      // Get total classrooms
      final classroomsResponse = await _supabase
          .from('classrooms')
          .select('id')
          .eq('teacher_id', teacherId)
          .eq('is_active', true);

      final totalClassrooms = classroomsResponse.length;

      // Get total students across all classrooms
      final enrollmentsResponse = await _supabase
          .from('student_enrollments')
          .select('id, classroom_id')
          .eq('status', 'active');

      final teacherClassroomIds = classroomsResponse.map((c) => c['id']).toList();
      final totalStudents = enrollmentsResponse
          .where((enrollment) => teacherClassroomIds.contains(enrollment['classroom_id']))
          .length;

      // Get total assignments
      final assignmentsResponse = await _supabase.from('assignments').select('id').eq('teacher_id', teacherId);

      final totalAssignments = assignmentsResponse.length;

      // Get total learning materials
      final materialsResponse = await _supabase.from('learning_materials').select('id').eq('teacher_id', teacherId);

      final totalMaterials = materialsResponse.length;

      return {
        'totalClassrooms': totalClassrooms,
        'totalStudents': totalStudents,
        'totalAssignments': totalAssignments,
        'totalMaterials': totalMaterials,
      };
    } catch (e) {
      print('Error fetching teacher statistics: $e');
      return {'classrooms': 0, 'students': 0, 'assignments': 0, 'materials': 0};
    }
  }

  /// Get recent activities for teacher dashboard
  Future<List<Map<String, dynamic>>> getRecentActivities(String teacherId, {int limit = 10}) async {
    try {
      // This is a simplified version - you can expand based on your needs
      final activities = <Map<String, dynamic>>[];

      // Get recent assignments
      final recentAssignments = await _supabase
          .from('assignments')
          .select('id, title, created_at, classroom_id, classrooms(name)')
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false)
          .limit(limit ~/ 2);

      for (var assignment in recentAssignments) {
        activities.add({
          'type': 'assignment_created',
          'title': 'Created assignment: ${assignment['title']}',
          'subtitle': 'in ${assignment['classrooms']['name']}',
          'time': assignment['created_at'],
          'icon': 'assignment',
        });
      }

      // Get recent materials
      final recentMaterials = await _supabase
          .from('learning_materials')
          .select('id, title, created_at, classroom_id, classrooms(name)')
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false)
          .limit(limit ~/ 2);

      for (var material in recentMaterials) {
        activities.add({
          'type': 'material_uploaded',
          'title': 'Uploaded: ${material['title']}',
          'subtitle': 'to ${material['classrooms']['name']}',
          'time': material['created_at'],
          'icon': 'file_upload',
        });
      }

      // Sort by time and limit
      activities.sort((a, b) => DateTime.parse(b['time']).compareTo(DateTime.parse(a['time'])));
      return activities.take(limit).toList();
    } catch (e) {
      print('Error fetching recent activities: $e');
      return [];
    }
  }
}
