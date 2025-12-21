import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recurring_session_model.dart';
import 'recurring_session_service.dart';

class TeacherService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RecurringSessionService _recurringService = RecurringSessionService();

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
            minimum_monthly_hours,
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

        // Get assignment count
        try {
          final assignmentResponse = await _supabase.from('assignments').select('id').eq('classroom_id', classroomId);
          classroom['assignment_count'] = assignmentResponse.length;
        } catch (e) {
          classroom['assignment_count'] = 0;
        }

        // Get materials count
        try {
          final materialsResponse = await _supabase
              .from('learning_materials')
              .select('id')
              .eq('classroom_id', classroomId);
          classroom['materials_count'] = materialsResponse.length;
        } catch (e) {
          classroom['materials_count'] = 0;
        }

        // Get recent sessions count (last 30 days)
        try {
          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          final sessionsResponse = await _supabase
              .from('class_sessions')
              .select('id')
              .eq('classroom_id', classroomId)
              .gte('session_date', thirtyDaysAgo.toIso8601String().split('T')[0]);
          classroom['recent_sessions'] = sessionsResponse.length;
        } catch (e) {
          classroom['recent_sessions'] = 0;
        }
      }

      return classrooms;
    } catch (e) {
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
      return [];
    }
  }

  // ============================================================================
  // Recurring Session Methods
  // ============================================================================

  /// Create a new recurring session
  Future<String> createRecurringSession(RecurringSessionModel session) async {
    return await _recurringService.createRecurringSession(session);
  }

  /// Get all recurring sessions for a classroom
  Future<List<RecurringSessionModel>> getRecurringSessionsForClassroom(String classroomId) async {
    return await _recurringService.getRecurringSessionsForClassroom(classroomId);
  }

  /// Get a single recurring session by ID
  Future<RecurringSessionModel> getRecurringSession(String id) async {
    return await _recurringService.getRecurringSession(id);
  }

  /// Update a recurring series
  Future<int> updateRecurringSeries({
    required String recurringSessionId,
    required Map<String, dynamic> updates,
    bool updateFutureOnly = true,
  }) async {
    return await _recurringService.updateRecurringSeries(
      recurringSessionId: recurringSessionId,
      updates: updates,
      updateFutureOnly: updateFutureOnly,
    );
  }

  /// Delete a recurring series
  Future<int> deleteRecurringSeries({
    required String recurringSessionId,
    bool deleteFutureOnly = false,
    DateTime? fromDate,
  }) async {
    return await _recurringService.deleteRecurringSeries(
      recurringSessionId: recurringSessionId,
      deleteFutureOnly: deleteFutureOnly,
      fromDate: fromDate,
    );
  }

  /// Generate session instances
  Future<int> generateSessionInstances({required String recurringSessionId, int monthsAhead = 3}) async {
    return await _recurringService.generateSessionInstances(
      recurringSessionId: recurringSessionId,
      monthsAhead: monthsAhead,
    );
  }

  /// Preview recurring session hours before creation
  Future<Map<String, dynamic>> previewRecurringSessionHours({
    required String classroomId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<int> recurrenceDays,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    return await _recurringService.previewRecurringSessionHours(
      classroomId: classroomId,
      startTime: startTime,
      endTime: endTime,
      recurrenceDays: recurrenceDays,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Delete a single recurring session instance
  Future<void> deleteSessionInstance(String sessionId) async {
    await _recurringService.deleteInstance(sessionId);
  }

  /// Update a single recurring session instance
  Future<void> updateSessionInstance({required String sessionId, required Map<String, dynamic> updates}) async {
    await _recurringService.updateInstance(sessionId: sessionId, updates: updates);
  }
}
