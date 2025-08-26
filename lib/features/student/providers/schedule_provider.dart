import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final scheduleProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    // Get the current user
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    // Fetch scheduled sessions for the current user
    final response = await Supabase.instance.client
        .from('class_sessions')
        .select('''
          *,
          classrooms:classroom_id(*, teacher:teacher_id(*)),
          subject:subject_id(*)
        ''')
        .eq('student_id', user.id)
        .gte('scheduled_start', DateTime.now().toIso8601String())
        .order('scheduled_start');

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Error fetching schedule: $e');
    rethrow;
  }
});

final selectedDaySessionsProvider = FutureProvider.family<List<Map<String, dynamic>>, DateTime>(
  (ref, selectedDay) async {
    try {
      final allSessions = await ref.watch(scheduleProvider.future);
      
      // Filter sessions for the selected day
      return allSessions.where((session) {
        final sessionDate = DateTime.parse(session['scheduled_start']).toLocal();
        return sessionDate.year == selectedDay.year &&
            sessionDate.month == selectedDay.month &&
            sessionDate.day == selectedDay.day;
      }).toList();
    } catch (e) {
      debugPrint('Error filtering sessions: $e');
      rethrow;
    }
  },
);
