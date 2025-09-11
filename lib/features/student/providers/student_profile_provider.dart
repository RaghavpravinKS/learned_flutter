import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/student_service.dart';
import '../services/classroom_service.dart';

// Provider for StudentService
final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService();
});

// Provider for current student profile
final currentStudentProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final studentService = ref.watch(studentServiceProvider);
  print('🔍 StudentProfileProvider: Fetching current student profile...');
  
  final profile = await studentService.getCurrentStudentProfile();
  
  if (profile != null) {
    print('🔍 StudentProfileProvider: Profile found for student: ${profile['student_id']}');
    print('🔍 StudentProfileProvider: Student name: ${profile['users']['first_name']} ${profile['users']['last_name']}');
  } else {
    print('🔍 StudentProfileProvider: No student profile found');
  }
  
  return profile;
});

// Provider for current student ID
final currentStudentIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final studentService = ref.watch(studentServiceProvider);
  print('🔍 StudentProfileProvider: Fetching current student ID...');
  
  final studentId = await studentService.getCurrentStudentId();
  print('🔍 StudentProfileProvider: Student ID: $studentId');
  
  return studentId;
});

// Provider to check if current user is an authenticated student
final isAuthenticatedStudentProvider = Provider<bool>((ref) {
  final studentService = ref.watch(studentServiceProvider);
  return studentService.isAuthenticatedStudent;
});

// Provider for student enrollment statistics
final studentEnrollmentStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final studentService = ref.watch(studentServiceProvider);
  print('🔍 StudentProfileProvider: Fetching enrollment statistics...');
  
  try {
    final studentId = await studentService.getCurrentStudentId();
    if (studentId == null) {
      print('🔍 StudentProfileProvider: No student ID found for stats');
      return {'total': 0, 'active': 0, 'completed': 0};
    }

    // Get enrollment data from ClassroomService
    final classroomService = ClassroomService();
    final enrolledClassrooms = await classroomService.getEnrolledClassrooms(studentId);
    
    final stats = {
      'total': enrolledClassrooms.length,
      'active': enrolledClassrooms.where((c) => c['status'] == 'active').length,
      'completed': enrolledClassrooms.where((c) => (c['progress'] as double?) == 1.0).length,
    };
    
    print('🔍 StudentProfileProvider: Enrollment stats: $stats');
    return stats;
    
  } catch (e) {
    print('🔍 StudentProfileProvider: Error fetching enrollment stats: $e');
    return {'total': 0, 'active': 0, 'completed': 0};
  }
});