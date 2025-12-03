import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recurring_session_model.dart';

class RecurringSessionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new recurring session template
  Future<String> createRecurringSession(RecurringSessionModel session) async {
    try {
      print('🔧 RecurringSessionService.createRecurringSession called');

      // Debug: Check auth session and JWT
      final currentSession = _supabase.auth.currentSession;
      print('🔐 Auth Session Check:');
      print('   Session exists: ${currentSession != null}');
      print(
        '   Access Token: ${currentSession?.accessToken != null ? "✅ Present (${currentSession!.accessToken.substring(0, 20)}...)" : "❌ Missing"}',
      );
      print('   User ID from session: ${currentSession?.user.id}');

      print('📦 Session data to insert:');
      final dataToInsert = session.toMap();

      // Remove id field - let database generate it
      dataToInsert.remove('id');

      print('   ${dataToInsert.toString()}');

      print('👤 Current user: ${_supabase.auth.currentUser?.id}');
      print('📧 Current email: ${_supabase.auth.currentUser?.email}');

      print('💾 Inserting into recurring_sessions table...');
      final response = await _supabase.from('recurring_sessions').insert(dataToInsert).select().single();

      print('✅ Insert successful! Response:');
      print('   ${response.toString()}');

      final id = response['id'] as String;
      print('🎉 Recurring session created with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error in createRecurringSession: $e');
      print('💡 Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
        print('   Details: ${e.details}');
        print('   Hint: ${e.hint}');
      }
      throw Exception('Failed to create recurring session: $e');
    }
  }

  /// Get all recurring sessions for a classroom
  Future<List<RecurringSessionModel>> getRecurringSessionsForClassroom(String classroomId) async {
    try {
      final response = await _supabase
          .from('recurring_sessions')
          .select()
          .eq('classroom_id', classroomId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => RecurringSessionModel.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recurring sessions: $e');
    }
  }

  /// Get a single recurring session by ID
  Future<RecurringSessionModel> getRecurringSession(String id) async {
    try {
      final response = await _supabase.from('recurring_sessions').select().eq('id', id).single();

      return RecurringSessionModel.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch recurring session: $e');
    }
  }

  /// Update a recurring session template and optionally update future instances
  /// Returns the number of instances updated
  Future<int> updateRecurringSeries({
    required String recurringSessionId,
    required Map<String, dynamic> updates,
    bool updateFutureOnly = true,
  }) async {
    try {
      final response = await _supabase.rpc(
        'update_recurring_series',
        params: {
          'p_recurring_session_id': recurringSessionId,
          'p_update_data': updates,
          'p_update_future_only': updateFutureOnly,
        },
      );

      return response as int;
    } catch (e) {
      throw Exception('Failed to update recurring series: $e');
    }
  }

  /// Delete a recurring series and optionally its instances
  /// Returns the number of instances deleted
  Future<int> deleteRecurringSeries({
    required String recurringSessionId,
    bool deleteFutureOnly = false,
    DateTime? fromDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'delete_recurring_series',
        params: {
          'p_recurring_session_id': recurringSessionId,
          'p_delete_future_only': deleteFutureOnly,
          if (fromDate != null) 'p_from_date': fromDate.toIso8601String().split('T')[0],
        },
      );

      return response as int;
    } catch (e) {
      throw Exception('Failed to delete recurring series: $e');
    }
  }

  /// Generate session instances for a recurring session
  /// Returns the number of sessions generated
  Future<int> generateSessionInstances({required String recurringSessionId, int monthsAhead = 3}) async {
    try {
      final response = await _supabase.rpc(
        'generate_recurring_sessions',
        params: {'p_recurring_session_id': recurringSessionId, 'p_months_ahead': monthsAhead},
      );

      return response as int;
    } catch (e) {
      throw Exception('Failed to generate session instances: $e');
    }
  }

  /// Delete a single recurring session instance
  /// This breaks the instance away from the recurring series
  Future<void> deleteInstance(String sessionId) async {
    try {
      await _supabase.from('class_sessions').delete().eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to delete session instance: $e');
    }
  }

  /// Update a single recurring session instance
  /// This breaks the instance away from the recurring series
  Future<void> updateInstance({required String sessionId, required Map<String, dynamic> updates}) async {
    try {
      // When updating an instance individually, break it from the series
      final updatesWithBreak = {...updates, 'recurring_session_id': null, 'is_recurring_instance': false};

      await _supabase.from('class_sessions').update(updatesWithBreak).eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to update session instance: $e');
    }
  }

  /// Preview recurring session hours before creation
  /// Returns validation data including whether the session meets minimum requirements
  Future<Map<String, dynamic>> previewRecurringSessionHours({
    required String classroomId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required List<int> recurrenceDays,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      // Format times as HH:MM:SS
      final startTimeStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

      print('🔍 Previewing recurring session hours:');
      print('   Classroom: $classroomId');
      print('   Days: $recurrenceDays');
      print('   Time: $startTimeStr - $endTimeStr');
      print('   Start Date: ${startDate.toIso8601String().split('T')[0]}');
      print('   End Date: ${endDate?.toIso8601String().split('T')[0] ?? 'No end date'}');

      final response = await _supabase.rpc(
        'preview_recurring_session_hours',
        params: {
          'p_classroom_id': classroomId,
          'p_start_time': startTimeStr,
          'p_end_time': endTimeStr,
          'p_recurrence_days': recurrenceDays,
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate?.toIso8601String().split('T')[0],
        },
      );

      print('✅ Preview response: $response');

      // Response is a list with one row
      if (response is List && response.isNotEmpty) {
        final data = response[0] as Map<String, dynamic>;
        return {
          'minimumRequiredHours': (data['minimum_required_hours'] as num?)?.toDouble() ?? 0.0,
          'calculatedMonthlyHours': (data['calculated_monthly_hours'] as num?)?.toDouble() ?? 0.0,
          'isValid': data['is_valid'] as bool? ?? false,
          'sessionsPerWeek': data['sessions_per_week'] as int? ?? 0,
          'hoursPerSession': (data['hours_per_session'] as num?)?.toDouble() ?? 0.0,
          'totalDurationDays': data['total_duration_days'] as int? ?? 0,
        };
      }

      throw Exception('Invalid response from preview function');
    } catch (e) {
      print('❌ Error previewing recurring session hours: $e');
      throw Exception('Failed to preview recurring session hours: $e');
    }
  }
}
