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
          classrooms:classroom_id(*, teacher:teacher_id(*))
        ''')
        .gte('session_date', DateTime.now().toIso8601String().split('T')[0])
        .order('session_date')
        .order('start_time');

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Error fetching schedule: $e');
    rethrow;
  }
});

final selectedDaySessionsProvider = FutureProvider.family<List<Map<String, dynamic>>, DateTime>((
  ref,
  selectedDay,
) async {
  try {
    final allSessions = await ref.watch(scheduleProvider.future);

    // Filter sessions for the selected day
    return allSessions.where((session) {
      final sessionDate = session['session_date'];
      if (sessionDate == null) return false;

      final date = DateTime.parse(sessionDate);
      return date.year == selectedDay.year && date.month == selectedDay.month && date.day == selectedDay.day;
    }).toList();
  } catch (e) {
    debugPrint('Error filtering sessions: $e');
    rethrow;
  }
});
