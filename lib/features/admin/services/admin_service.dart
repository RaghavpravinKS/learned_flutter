import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase;

  AdminService() : _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchTeachers() async {
    final response = await _supabase
        .from('teachers')
        .select('*, users(first_name, last_name, email)');

    // The query returns a List<dynamic>, so we cast it.
    final teachers = List<Map<String, dynamic>>.from(response as List);
    return teachers;
  }
}
