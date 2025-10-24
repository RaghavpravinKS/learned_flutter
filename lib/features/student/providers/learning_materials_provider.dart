import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../teacher/models/learning_material_model.dart';

// Provider to fetch learning materials for a specific classroom
final classroomLearningMaterialsProvider = FutureProvider.family<List<LearningMaterialModel>, String>((
  ref,
  classroomId,
) async {
  try {
    final supabase = Supabase.instance.client;

    print('=== Fetching learning materials for classroom: $classroomId ===');

    // Fetch learning materials from Supabase
    final response = await supabase
        .from('learning_materials')
        .select()
        .eq('classroom_id', classroomId)
        .order('upload_date', ascending: false)
        .limit(10); // Get most recent 10 materials

    print('=== Learning materials response: ${response.length} items ===');

    if (response.isEmpty) {
      print('=== No learning materials found for classroom ===');
      return [];
    }

    final materials = (response as List).map((item) {
      final material = LearningMaterialModel.fromMap(item as Map<String, dynamic>);
      print('=== Material: ${material.title}, URL: ${material.fileUrl} ===');
      return material;
    }).toList();

    print('=== Successfully parsed ${materials.length} learning materials ===');

    return materials;
  } catch (e, stackTrace) {
    print('=== Error fetching learning materials: $e ===');
    print('=== Stack trace: $stackTrace ===');
    rethrow;
  }
});

// Provider to fetch recent learning materials (top 3) for a classroom
final recentClassroomMaterialsProvider = FutureProvider.family<List<LearningMaterialModel>, String>((
  ref,
  classroomId,
) async {
  try {
    final supabase = Supabase.instance.client;

    print('=== Fetching recent learning materials for classroom: $classroomId ===');

    // Fetch top 3 most recent learning materials
    final response = await supabase
        .from('learning_materials')
        .select()
        .eq('classroom_id', classroomId)
        .order('upload_date', ascending: false)
        .limit(3);

    print('=== Recent materials response: ${response.length} items ===');

    if (response.isEmpty) {
      print('=== No recent materials found ===');
      return [];
    }

    final materials = (response as List).map((item) {
      final material = LearningMaterialModel.fromMap(item as Map<String, dynamic>);
      print('=== Material: ${material.title}, Type: ${material.materialType}, URL: ${material.fileUrl} ===');
      return material;
    }).toList();

    print('=== Successfully fetched ${materials.length} recent materials ===');

    return materials;
  } catch (e, stackTrace) {
    print('=== Error fetching recent materials: $e ===');
    print('=== Stack trace: $stackTrace ===');
    rethrow;
  }
});

// Provider to fetch all learning materials for all enrolled classrooms
final allStudentMaterialsProvider = FutureProvider<List<LearningMaterialModel>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return [];
    }

    print('=== Fetching all learning materials for student ===');

    // Get student's enrolled classrooms
    final studentResponse = await supabase.from('students').select('id').eq('user_id', userId).maybeSingle();

    if (studentResponse == null) {
      print('=== No student record found ===');
      return [];
    }

    final studentId = studentResponse['id'] as String;

    // Get classroom IDs where student is enrolled
    final enrollmentsResponse = await supabase
        .from('student_enrollments')
        .select('classroom_id')
        .eq('student_id', studentId);

    if (enrollmentsResponse.isEmpty) {
      print('=== No enrollments found ===');
      return [];
    }

    final classroomIds = (enrollmentsResponse as List).map((e) => e['classroom_id'] as String).toList();

    print('=== Found ${classroomIds.length} enrolled classrooms ===');

    // Fetch learning materials from all enrolled classrooms with classroom and teacher names
    final response = await supabase
        .from('learning_materials')
        .select('''
          *,
          classrooms!inner(name),
          teachers!inner(
            users!inner(first_name, last_name)
          )
        ''')
        .inFilter('classroom_id', classroomIds)
        .order('upload_date', ascending: false);

    print('=== Learning materials response: ${response.length} items ===');

    if (response.isEmpty) {
      return [];
    }

    final materials = (response as List).map((item) {
      final map = item as Map<String, dynamic>;

      // Extract classroom name
      final classroom = map['classrooms'] as Map<String, dynamic>?;
      final classroomName = classroom?['name'] as String?;

      // Extract teacher name
      final teacher = map['teachers'] as Map<String, dynamic>?;
      final users = teacher?['users'] as Map<String, dynamic>?;
      final firstName = users?['first_name'] as String?;
      final lastName = users?['last_name'] as String?;
      final teacherName = firstName != null && lastName != null ? '$firstName $lastName' : firstName ?? lastName;

      // Add classroom and teacher names to the map
      final materialMap = Map<String, dynamic>.from(map);
      materialMap['classroom_name'] = classroomName;
      materialMap['teacher_name'] = teacherName;

      return LearningMaterialModel.fromMap(materialMap);
    }).toList();

    print('=== Successfully fetched ${materials.length} materials ===');

    return materials;
  } catch (e, stackTrace) {
    print('=== Error fetching all student materials: $e ===');
    print('=== Stack trace: $stackTrace ===');
    rethrow;
  }
});
