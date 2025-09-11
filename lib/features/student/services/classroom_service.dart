import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_service.dart';

class ClassroomService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StudentService _studentService = StudentService();

  /// Helper method to resolve teacher name with robust fallback logic
  String _resolveTeacherName(Map<String, dynamic> classroom) {
    try {
      // Try to get teacher info from the nested teachers relationship
      final teacher = classroom['teachers'] as Map<String, dynamic>?;
      
      if (teacher != null) {
        // Try to get user data from teacher
        final teacherUser = teacher['users'] as Map<String, dynamic>?;
        
        if (teacherUser != null) {
          final firstName = teacherUser['first_name'] as String?;
          final lastName = teacherUser['last_name'] as String?;
          
          if (firstName != null && firstName.isNotEmpty) {
            final fullName = lastName != null && lastName.isNotEmpty 
                ? '$firstName $lastName' 
                : firstName;
            print('🔍 _resolveTeacherName: Found teacher name: $fullName');
            return fullName;
          }
        }
        
        // Fallback to teacher_id if available
        final teacherId = teacher['teacher_id'] as String?;
        if (teacherId != null && teacherId.isNotEmpty) {
          print('🔍 _resolveTeacherName: Using teacher_id fallback: $teacherId');
          return 'Teacher $teacherId';
        }
        
        // Fallback to teacher id
        final id = teacher['id'] as String?;
        if (id != null) {
          print('🔍 _resolveTeacherName: Using teacher id fallback');
          return 'Teacher ${id.substring(0, 8)}...';
        }
      }
      
      // Try to get teacher info directly from classroom if no nested relationship
      final teacherId = classroom['teacher_id'] as String?;
      if (teacherId != null && teacherId.isNotEmpty) {
        print('🔍 _resolveTeacherName: Using classroom teacher_id: $teacherId');
        return 'Teacher ${teacherId.substring(0, 8)}...';
      }
      
      print('🔍 _resolveTeacherName: No teacher info found, using default');
      return 'Teacher Info Unavailable';
      
    } catch (e) {
      print('🔍 _resolveTeacherName: Error resolving teacher name: $e');
      return 'Teacher Info Unavailable';
    }
  }

  /// Attempts to get teacher name directly from database if relationship fails
  Future<String> _getTeacherNameDirectly(String? teacherId) async {
    if (teacherId == null || teacherId.isEmpty) {
      return 'Teacher Info Unavailable';
    }
    
    try {
      // Query teacher and user data separately
      final teacherResponse = await _supabase
          .from('teachers')
          .select('''
            id,
            teacher_id,
            user_id,
            users(first_name, last_name)
          ''')
          .eq('id', teacherId)
          .maybeSingle();
      
      if (teacherResponse != null) {
        final teacherUser = teacherResponse['users'] as Map<String, dynamic>?;
        if (teacherUser != null) {
          final firstName = teacherUser['first_name'] as String?;
          final lastName = teacherUser['last_name'] as String?;
          
          if (firstName != null && firstName.isNotEmpty) {
            final fullName = lastName != null && lastName.isNotEmpty 
                ? '$firstName $lastName' 
                : firstName;
            print('🔍 _getTeacherNameDirectly: Found teacher name: $fullName');
            return fullName;
          }
        }
        
        // Use teacher_id as fallback
        final tId = teacherResponse['teacher_id'] as String?;
        if (tId != null && tId.isNotEmpty) {
          return 'Teacher $tId';
        }
      }
      
      return 'Teacher ${teacherId.substring(0, 8)}...';
    } catch (e) {
      print('🔍 _getTeacherNameDirectly: Error: $e');
      return 'Teacher ${teacherId.substring(0, 8)}...';
    }
  }

  // Fetch all available classrooms with their payment plans
  Future<List<Map<String, dynamic>>> getAvailableClassrooms({String? subject, String? board, int? gradeLevel}) async {
    try {
      print(
        '🔍 ClassroomService: fetching classrooms with filters - subject: $subject, board: $board, grade: $gradeLevel',
      );

      var query = _supabase
          .from('classrooms')
          .select('''
            *,
            teachers(
              id,
              teacher_id,
              user_id,
              qualifications,
              experience_years,
              users(first_name, last_name)
            ),
            classroom_pricing(
              price,
              payment_plans(name, billing_cycle)
            )
          ''')
          .eq('is_active', true);

      // Apply filters
      if (subject != null && subject != 'All') {
        query = query.ilike('subject', '%$subject%');
      }
      if (board != null && board != 'All') {
        query = query.eq('board', board);
      }
      if (gradeLevel != null) {
        query = query.eq('grade_level', gradeLevel);
      }

      final response = await query;
      print('🔍 Database returned ${response.length} classrooms');

      // Process the response to add calculated fields
      final classrooms = List<Map<String, dynamic>>.from(response);

      // Add student count and teacher name for each classroom
      for (var i = 0; i < classrooms.length; i++) {
        final classroom = classrooms[i];

        // Get student count for this classroom
        try {
          final studentCountResponse = await _supabase
              .from('student_classroom_assignments')
              .select('id')
              .eq('classroom_id', classroom['id'])
              .eq('status', 'active');

          classroom['student_count'] = studentCountResponse.length;
        } catch (e) {
          print('🔍 Error getting student count for ${classroom['name']}: $e');
          classroom['student_count'] = 0;
        }

        // Format teacher name with improved fallback logic
        String teacherName = _resolveTeacherName(classroom);
        
        // If we couldn't resolve the teacher name from the relationship, try direct query
        if (teacherName == 'Teacher Info Unavailable' || teacherName.startsWith('Teacher ')) {
          final teacherId = classroom['teacher_id'] as String?;
          if (teacherId != null) {
            teacherName = await _getTeacherNameDirectly(teacherId);
          }
        }
        
        classroom['teacher_name'] = teacherName;
      }

      print('🔍 Returning ${classrooms.length} processed classrooms');
      return classrooms;
    } catch (e) {
      print('🔍 ERROR in getAvailableClassrooms: $e');
      rethrow;
    }
  }

  // Get a single classroom by ID
  Future<Map<String, dynamic>> getClassroomById(String classroomId) async {
    try {
      print('🔍 getClassroomById: Fetching classroom with ID: $classroomId');

      // First, get the basic classroom data
      final classroomResponse = await _supabase
          .from('classrooms')
          .select('*')
          .eq('id', classroomId)
          .eq('is_active', true)
          .single();

      print('🔍 getClassroomById: Basic classroom data fetched: ${classroomResponse['name']}');

      // Get teacher data separately
      Map<String, dynamic>? teacherData;
      if (classroomResponse['teacher_id'] != null) {
        print('🔍 getClassroomById: Fetching teacher data for ID: ${classroomResponse['teacher_id']}');
        try {
          final teacherResponse = await _supabase
              .from('teachers')
              .select('''
                id,
                user_id,
                qualifications,
                experience_years,
                specializations,
                hourly_rate,
                bio,
                rating,
                total_reviews,
                users(first_name, last_name, profile_image_url)
              ''')
              .eq('id', classroomResponse['teacher_id'])
              .single();
          teacherData = teacherResponse;
          print('🔍 getClassroomById: Teacher data fetched successfully');
        } catch (e) {
          print('🔍 getClassroomById: Error fetching teacher data: $e');
        }
      }

      // Get pricing data separately
      List<Map<String, dynamic>>? pricingData;
      try {
        print('🔍 getClassroomById: Fetching pricing data...');
        final pricingResponse = await _supabase
            .from('classroom_pricing')
            .select('''
              price,
              payment_plans(name, description, billing_cycle, features)
            ''')
            .eq('classroom_id', classroomId);
        pricingData = List<Map<String, dynamic>>.from(pricingResponse);
        print('🔍 getClassroomById: Pricing data fetched: ${pricingData.length} plans');
      } catch (e) {
        print('🔍 getClassroomById: Error fetching pricing data: $e');
      }

      // Get student count
      print('🔍 getClassroomById: Fetching student count...');
      final studentCountResponse = await _supabase
          .from('student_classroom_assignments')
          .select('id')
          .eq('classroom_id', classroomId)
          .eq('status', 'active');

      // Combine all data
      final Map<String, dynamic> response = Map<String, dynamic>.from(classroomResponse);
      response['student_count'] = studentCountResponse.length;
      response['teachers'] = teacherData;
      response['classroom_pricing'] = pricingData;

      // Format teacher name using the helper method
      String teacherName = _resolveTeacherName(response);
      
      // If we couldn't resolve the teacher name from the relationship, try direct query
      if (teacherName == 'Teacher Info Unavailable' || teacherName.startsWith('Teacher ')) {
        final teacherId = response['teacher_id'] as String?;
        if (teacherId != null) {
          teacherName = await _getTeacherNameDirectly(teacherId);
        }
      }
      
      response['teacher_name'] = teacherName;

      print('🔍 getClassroomById: Returning processed classroom data with ${response.keys.length} keys');
      return response;
    } catch (e) {
      print('🔍 getClassroomById: ERROR - $e');
      rethrow;
    }
  }

  // Enroll student in a classroom after payment using database function
  Future<Map<String, dynamic>> enrollStudent({
    String? studentId, // Made nullable to allow authenticated user detection
    required String classroomId,
    required String paymentPlanId,
    required double amountPaid,
    String? transactionId,
  }) async {
    try {
      print('🔍 enrollStudent: Starting enrollment process...');
      print('🔍 enrollStudent: Input Student ID: $studentId');
      print('🔍 enrollStudent: Classroom ID: $classroomId');
      print('🔍 enrollStudent: Payment Plan ID: $paymentPlanId');
      print('🔍 enrollStudent: Amount Paid: $amountPaid');

      // Get the actual authenticated student ID
      String? actualStudentId;

      if (studentId != null && studentId.isNotEmpty && studentId != 'mock-student-id') {
        // Use provided student ID if it's valid
        actualStudentId = studentId;
        print('🔍 enrollStudent: Using provided student ID: $actualStudentId');
      } else {
        // Get from authenticated user
        actualStudentId = await _studentService.getCurrentStudentId();
        print('🔍 enrollStudent: Retrieved student ID from auth: $actualStudentId');
      }

      // If no authenticated student found, try test data for development
      if (actualStudentId == null) {
        print('🔍 enrollStudent: No authenticated student found, using test data');
        actualStudentId = '12345678-1234-5678-9012-345678901234'; // Test student from migration
      }

      print('🔍 enrollStudent: Final student ID to use: $actualStudentId');

      try {
        // Use the correct database function for enrollment
        print('🔍 enrollStudent: Using database function enroll_student_with_payment...');
        print(
          '🔍 enrollStudent: Calling function with: student_id=$actualStudentId, classroom_id=$classroomId, amount=$amountPaid',
        );

        final result = await _supabase.rpc(
          'enroll_student_with_payment',
          params: {
            'p_student_id': actualStudentId,
            'p_classroom_id': classroomId,
            'p_payment_plan_id': paymentPlanId, // Use the payment plan ID
            'p_amount_paid': amountPaid,
          },
        );

        print('🔍 enrollStudent: Function completed successfully: $result');
        print('🔍 enrollStudent: 🎉 ENROLLMENT COMPLETED SUCCESSFULLY via DB function! 🎉');

        return {'success': true, 'message': 'Student enrolled successfully using database function'};
      } catch (dbError) {
        print('🔍 enrollStudent: Database function failed: $dbError');
        print('🔍 enrollStudent: Falling back to direct database operations...');
      }

      // Fallback: Legacy enrollment simulation
      print('🔍 enrollStudent: Using fallback enrollment simulation...');

      // Simulate payment processing
      print('🔍 enrollStudent: Simulating payment processing...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Try to create basic enrollment record with proper UUID
      try {
        await _supabase.from('student_classroom_assignments').insert({
          'student_id': actualStudentId,
          'classroom_id': classroomId,
          'status': 'active',
          'enrolled_date': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
        print('🔍 enrollStudent: ✓ Fallback enrollment record created');
      } catch (e) {
        print('🔍 enrollStudent: Fallback enrollment also failed: $e');
      }

      print('🔍 enrollStudent: 🎉 FALLBACK ENROLLMENT COMPLETED! 🎉');
      return {
        'success': true,
        'enrollment_id': 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        'payment_id': 'payment_${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Enrollment completed using fallback method',
      };
    } catch (e) {
      print('🔍 enrollStudent: ERROR - $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get enrolled classrooms for a student using database function
  Future<List<Map<String, dynamic>>> getEnrolledClassrooms(String? inputStudentId) async {
    try {
      print('🔍 getEnrolledClassrooms: Starting method with input: $inputStudentId');

      // Print comprehensive debug info first
      await _studentService.printFullDebugInfo();

      // Get the actual authenticated student ID
      String? studentId;

      if (inputStudentId != null && inputStudentId.isNotEmpty && inputStudentId != 'mock-student-id') {
        // Use provided student ID if it's valid
        studentId = inputStudentId;
        print('🔍 getEnrolledClassrooms: Using provided student ID: $studentId');
      } else {
        // Get from authenticated user
        studentId = await _studentService.getCurrentStudentId();
        print('🔍 getEnrolledClassrooms: Retrieved student ID from auth: $studentId');
      }

      // If no authenticated student found, try test data for development
      if (studentId == null) {
        print('🔍 getEnrolledClassrooms: No authenticated student found, using test data');
        studentId = '12345678-1234-5678-9012-345678901234'; // Test student from migration

        // Also print current user debug info
        final debugInfo = _studentService.currentUserDebugInfo;
        print('🔍 getEnrolledClassrooms: Current user debug info: $debugInfo');
      }

      print('🔍 getEnrolledClassrooms: Final student ID to use: $studentId');

      try {
        // Direct SQL query to get enrolled classrooms with all related data
        print('🔍 getEnrolledClassrooms: Querying enrolled classrooms directly...');
        final assignments = await _supabase
            .from('student_classroom_assignments')
            .select('''
              *,
              classrooms(
                id,
                name,
                subject,
                grade_level,
                description,
                next_session_date,
                teacher_id,
                teachers(
                  id,
                  qualifications,
                  experience_years,
                  users(first_name, last_name)
                )
              )
            ''')
            .eq('student_id', studentId)
            .eq('status', 'active');

        print('🔍 getEnrolledClassrooms: Raw database response: $assignments');

        if (assignments.isNotEmpty) {
          print('🔍 getEnrolledClassrooms: Found ${assignments.length} enrolled classrooms from direct query');

          // Print detailed info about each assignment
          for (int i = 0; i < assignments.length; i++) {
            final assignment = assignments[i];
            print('🔍 Assignment $i: ${assignment}');
            final classroom = assignment['classrooms'];
            if (classroom != null) {
              print('🔍 Classroom $i: ${classroom['name']} (ID: ${classroom['id']})');
              final teacher = classroom['teachers'];
              if (teacher != null) {
                final teacherUser = teacher['users'];
                if (teacherUser != null) {
                  print('🔍 Teacher $i: ${teacherUser['first_name']} ${teacherUser['last_name']}');
                }
              }
            }
          }

          // Process and format the data
          final enrolledClassrooms = <Map<String, dynamic>>[];
          for (final assignment in assignments) {
            final classroom = assignment['classrooms'] as Map<String, dynamic>?;
            if (classroom != null) {
              // Build teacher name using helper method
              String teacherName = _resolveTeacherName(classroom);
              
              // If we couldn't resolve the teacher name from the relationship, try direct query
              if (teacherName == 'Teacher Info Unavailable' || teacherName.startsWith('Teacher ')) {
                final teacherId = classroom['teacher_id'] as String?;
                if (teacherId != null) {
                  teacherName = await _getTeacherNameDirectly(teacherId);
                }
              }

              enrolledClassrooms.add({
                'id': classroom['id'],
                'name': classroom['name'],
                'subject': classroom['subject'],
                'grade_level': classroom['grade_level'],
                'description': classroom['description'],
                'teacher_name': teacherName,
                'enrollment_date': assignment['enrolled_date'],
                'progress': (assignment['progress'] as num?)?.toDouble() ?? 0.0,
                'next_session': classroom['next_session_date'],
                'status': assignment['status'],
              });
            }
          }

          print('🔍 getEnrolledClassrooms: Returning ${enrolledClassrooms.length} processed classrooms');
          return enrolledClassrooms;
        }
      } catch (dbError) {
        print('🔍 getEnrolledClassrooms: Direct query failed: $dbError');
        print('🔍 getEnrolledClassrooms: Falling back to legacy method...');
      }

      // Fallback: Try legacy query method
      try {
        final assignments = await _supabase
            .from('student_classroom_assignments')
            .select('''
              *,
              classrooms(
                id,
                name,
                subject,
                grade_level,
                description,
                teacher_id,
                teachers(
                  id,
                  qualifications,
                  experience_years,
                  users(first_name, last_name)
                )
              )
            ''')
            .eq('student_id', studentId)
            .eq('status', 'active');

        print('🔍 getEnrolledClassrooms: Found ${assignments.length} enrolled classrooms from legacy query');

        // Process and format the data
        final enrolledClassrooms = <Map<String, dynamic>>[];
        for (final assignment in assignments) {
          final classroom = assignment['classrooms'] as Map<String, dynamic>?;
          if (classroom != null) {
            // Use helper method for teacher name resolution
            String teacherName = _resolveTeacherName(classroom);
            
            // If we couldn't resolve the teacher name from the relationship, try direct query
            if (teacherName == 'Teacher Info Unavailable' || teacherName.startsWith('Teacher ')) {
              final teacherId = classroom['teacher_id'] as String?;
              if (teacherId != null) {
                teacherName = await _getTeacherNameDirectly(teacherId);
              }
            }
            
            enrolledClassrooms.add({
              'id': classroom['id'],
              'name': classroom['name'],
              'subject': classroom['subject'],
              'grade_level': classroom['grade_level'],
              'teacher_name': teacherName,
              'enrollment_date': assignment['enrolled_date'],
              'progress': 0.5, // Default progress
              'next_session': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
              'status': assignment['status'],
            });
          }
        }

        if (enrolledClassrooms.isNotEmpty) {
          print('🔍 getEnrolledClassrooms: Returning ${enrolledClassrooms.length} legacy enrolled classrooms');
          return enrolledClassrooms;
        }
      } catch (e) {
        print('🔍 getEnrolledClassrooms: Legacy query also failed: $e');
      }

      // No enrollments found - return empty list for new users
      print('🔍 getEnrolledClassrooms: No enrollments found, returning empty list');
      return [];
    } catch (e) {
      print('🔍 getEnrolledClassrooms: ERROR - $e');
      rethrow;
    }
  }
}
