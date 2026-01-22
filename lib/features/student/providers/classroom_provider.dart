import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/classroom_service.dart';
import '../services/payment_service.dart';

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  return ClassroomService();
});

// Simple provider that fetches all classrooms once
final allClassroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(classroomServiceProvider);
  return service.getAvailableClassrooms();
});

// Provider that fetches only enrolled classrooms for the current student
final enrolledClassroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(classroomServiceProvider);
  return service.getEnrolledClassrooms(null);
});

// Provider to get the next upcoming session for a classroom
final nextClassroomSessionProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((
  ref,
  classroomId,
) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();

  final response = await supabase
      .from('class_sessions')
      .select()
      .eq('classroom_id', classroomId)
      .gte('session_date', now.toIso8601String().split('T')[0])
      .order('session_date', ascending: true)
      .order('start_time', ascending: true)
      .limit(1);

  if (response.isEmpty) return null;
  return response.first;
});

// Provider to get attendance statistics for a classroom
final classroomAttendanceProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((
  ref,
  classroomId,
) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  // Get student record
  final studentResponse = await supabase.from('students').select('id').eq('user_id', userId).single();

  final studentId = studentResponse['id'] as String;

  // Get all sessions for this classroom
  final sessionsResponse = await supabase.from('class_sessions').select('id').eq('classroom_id', classroomId);

  final sessionIds = (sessionsResponse as List).map((s) => s['id'] as String).toList();

  if (sessionIds.isEmpty) {
    return {'totalSessions': 0, 'attended': 0, 'absent': 0, 'late': 0, 'excused': 0, 'attendanceRate': 0.0};
  }

  // Get attendance records for these sessions
  final attendanceResponse = await supabase
      .from('session_attendance')
      .select('attendance_status')
      .eq('student_id', studentId)
      .inFilter('session_id', sessionIds);

  final attendanceRecords = attendanceResponse as List;

  final present = attendanceRecords.where((a) => a['attendance_status'] == 'present').length;
  final absent = attendanceRecords.where((a) => a['attendance_status'] == 'absent').length;
  final late = attendanceRecords.where((a) => a['attendance_status'] == 'late').length;
  final excused = attendanceRecords.where((a) => a['attendance_status'] == 'excused').length;

  final totalSessions = sessionIds.length;
  final attended = present + late; // Count late as attended
  final attendanceRate = totalSessions > 0 ? (attended / totalSessions) * 100 : 0.0;

  return {
    'totalSessions': totalSessions,
    'attended': attended,
    'absent': absent,
    'late': late,
    'excused': excused,
    'attendanceRate': attendanceRate,
  };
});

// Provider to get sessions filtered by attendance status
final sessionsByAttendanceStatusProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String classroomId, String status})>((ref, params) async {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get student record
      final studentResponse = await supabase.from('students').select('id').eq('user_id', userId).single();
      final studentId = studentResponse['id'] as String;

      // First, get attendance records with the specific status for this student
      final attendanceResponse = await supabase
          .from('session_attendance')
          .select('session_id')
          .eq('student_id', studentId)
          .eq('attendance_status', params.status);

      final sessionIds = (attendanceResponse as List).map((a) => a['session_id'] as String).toList();

      if (sessionIds.isEmpty) {
        return [];
      }

      // Then, get the session details for those session IDs
      final sessionsResponse = await supabase
          .from('class_sessions')
          .select('*')
          .eq('classroom_id', params.classroomId)
          .inFilter('id', sessionIds)
          .order('session_date', ascending: false)
          .order('start_time', ascending: false);

      return (sessionsResponse as List).cast<Map<String, dynamic>>();
    });

// Check if student is enrolled in a specific classroom
final studentEnrollmentStatusProvider = FutureProvider.autoDispose.family<bool, String>((ref, classroomId) async {
  final service = ref.watch(classroomServiceProvider);
  final enrolledClassrooms = await service.getEnrolledClassrooms(null);
  return enrolledClassrooms.any((classroom) => classroom['id'] == classroomId);
});

// Legacy provider kept for compatibility with other parts of the app
final availableClassroomsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Map<String, dynamic>?>((ref, filters) async {
      final service = ref.watch(classroomServiceProvider);
      return service.getAvailableClassrooms(
        subject: filters?['subject'],
        board: filters?['board'],
        gradeLevel: filters?['grade_level'],
      );
    });

final classroomDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((
  ref,
  classroomId,
) async {
  final service = ref.watch(classroomServiceProvider);
  return service.getClassroomById(classroomId);
});

final studentEnrollmentsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((
  ref,
  studentId,
) async {
  // This would normally fetch the student's enrollments
  return {'enrollments': [], 'active_subscriptions': [], 'upcoming_sessions': []};
});

// Check if student has a pending payment for a specific classroom
final pendingPaymentForClassroomProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((
  ref,
  classroomId,
) async {
  final paymentService = PaymentService();
  final pendingPayments = await paymentService.getPendingPayments();

  // Find a pending payment for this specific classroom
  try {
    return pendingPayments.firstWhere((payment) => payment['classroom_id'] == classroomId);
  } catch (e) {
    return null; // No pending payment found
  }
});

// Get enrollment details including subscription expiry for a classroom
final enrollmentDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((
  ref,
  classroomId,
) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    return null;
  }

  try {
    // Get student ID
    final studentResponse = await supabase.from('students').select('id').eq('user_id', userId).maybeSingle();

    if (studentResponse == null) {
      return null;
    }

    final studentId = studentResponse['id'] as String;

    // First, check if there's an enrollment record with expiry date
    final enrollmentResponse = await supabase
        .from('student_enrollments')
        .select('*, payment_plans(name, billing_cycle)')
        .eq('student_id', studentId)
        .eq('classroom_id', classroomId)
        .eq('status', 'active')
        .maybeSingle();

    if (enrollmentResponse != null) {
      return enrollmentResponse;
    }

    // Fallback: Check completed payments for this classroom to get expiry
    final paymentResponse = await supabase
        .from('payments')
        .select('*, payment_plans(name, billing_cycle)')
        .eq('student_id', studentId)
        .eq('classroom_id', classroomId)
        .eq('status', 'completed')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return paymentResponse;
  } catch (e) {
    return null;
  }
});
