import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
            },
          ),
        ],
      ),
      body: ScheduleBody(
        focusedDay: _focusedDay,
        selectedDay: _selectedDay,
        calendarFormat: _calendarFormat,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        onTodayPressed: () {
          setState(() {
            _focusedDay = DateTime.now();
            _selectedDay = _focusedDay;
          });
        },
      ),
    );
  }
}

// Separate body widget that can be used independently
class ScheduleBody extends ConsumerWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(CalendarFormat format) onFormatChanged;
  final void Function(DateTime focusedDay) onPageChanged;
  final VoidCallback onTodayPressed;

  const ScheduleBody({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.onTodayPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Calendar View
        TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(selectedDay, day);
          },
          onDaySelected: onDaySelected,
          calendarFormat: calendarFormat,
          onFormatChanged: onFormatChanged,
          onPageChanged: onPageChanged,
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            formatButtonTextStyle: const TextStyle(color: Colors.white),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
          ),
        ),
        const Divider(),
        // Schedule List
        Expanded(child: _buildScheduleList(context, ref)),
      ],
    );
  }

  Widget _buildScheduleList(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(selectedDaySessionsProvider(selectedDay ?? focusedDay));

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Error loading schedule: $error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ref.refresh(scheduleProvider.future), child: const Text('Retry')),
          ],
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                Text('No sessions scheduled', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Check back later or contact your teacher',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(scheduleProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];

              // Parse session date and times
              final sessionDate = session['session_date'] as String?;
              final startTimeStr = session['start_time'] as String?;
              final endTimeStr = session['end_time'] as String?;

              if (sessionDate == null || startTimeStr == null || endTimeStr == null) {
                return const SizedBox.shrink(); // Skip invalid sessions
              }

              // Combine date and time
              final startTime = DateTime.parse('$sessionDate $startTimeStr').toLocal();
              final endTime = DateTime.parse('$sessionDate $endTimeStr').toLocal();

              final classroom = session['classrooms'] as Map<String, dynamic>? ?? {};
              final teacher = classroom['teacher'] as Map<String, dynamic>? ?? {};
              final teacherUser = teacher['users'] as Map<String, dynamic>? ?? {};

              // Get subject from classroom
              final subject = classroom['subject'] as String? ?? 'No Subject';

              // Get teacher name safely
              final firstName = teacherUser['first_name'] as String? ?? '';
              final lastName = teacherUser['last_name'] as String? ?? '';
              final teacherName = '$firstName $lastName'.trim();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(Icons.video_call, color: Theme.of(context).primaryColor),
                  ),
                  title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        teacherName.isNotEmpty ? teacherName : 'No Teacher',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (session['meeting_url'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.videocam, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Online Session',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final sessionId = session['id'] as String?;
                    if (session['meeting_url'] != null && sessionId != null) {
                      context.push('/student/schedule/session/join/$sessionId', extra: session);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
