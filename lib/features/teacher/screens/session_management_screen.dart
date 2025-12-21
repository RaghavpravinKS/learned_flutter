import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/session_model.dart';
import '../providers/session_provider.dart';
import 'create_session_screen.dart';
import 'attendance_marking_screen.dart';

class SessionManagementScreen extends ConsumerStatefulWidget {
  const SessionManagementScreen({super.key});

  @override
  ConsumerState<SessionManagementScreen> createState() => _SessionManagementScreenState();
}

class _SessionManagementScreenState extends ConsumerState<SessionManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upcomingSessionsAsync = ref.watch(upcomingSessionsProvider);
    final pastSessionsAsync = ref.watch(pastSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sessions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(teacherSessionsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(
              text: upcomingSessionsAsync.when(
                data: (sessions) => 'Upcoming (${sessions.length})',
                loading: () => 'Upcoming',
                error: (_, __) => 'Upcoming',
              ),
            ),
            Tab(
              text: pastSessionsAsync.when(
                data: (sessions) => 'Past (${sessions.length})',
                loading: () => 'Past',
                error: (_, __) => 'Past',
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsList(upcomingSessionsAsync, isUpcoming: true),
          _buildSessionsList(pastSessionsAsync, isUpcoming: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateSession(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }

  Widget _buildSessionsList(AsyncValue<List<SessionModel>> sessionsAsync, {required bool isUpcoming}) {
    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading sessions',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => ref.invalidate(teacherSessionsProvider), child: const Text('Try Again')),
          ],
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isUpcoming ? Icons.event_available : Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  isUpcoming ? 'No Upcoming Sessions' : 'No Past Sessions',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  isUpcoming ? 'Create your first session to get started' : 'Past sessions will appear here',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                if (isUpcoming) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateSession(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Session'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) => _buildSessionCard(sessions[index], isUpcoming: isUpcoming),
        );
      },
    );
  }

  Widget _buildSessionCard(SessionModel session, {required bool isUpcoming}) {
    final theme = Theme.of(context);
    final isToday = session.isToday;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isToday ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday ? BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showSessionDetails(session, isUpcoming: isUpcoming),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Classroom name
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session.classroomName,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date and time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(session.formattedDate, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    session.formattedTimeRange,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),

              // Meeting link if available
              if (session.meetingUrl != null && session.meetingUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.video_call, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Meeting link available', style: TextStyle(color: Colors.blue[700], fontSize: 13)),
                      ),
                      if (isUpcoming)
                        TextButton(
                          onPressed: () => _launchMeetingUrl(session.meetingUrl!),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Join'),
                        ),
                    ],
                  ),
                ),
              ],

              // Action buttons
              if (isUpcoming) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _markAttendance(session),
                      icon: const Icon(Icons.how_to_reg, size: 18),
                      label: const Text('Attendance'),
                      style: TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                    TextButton.icon(
                      onPressed: () => _editSession(session),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                    TextButton.icon(
                      onPressed: () => _cancelSession(session),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ] else ...[
                // For past sessions, still show attendance button
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _markAttendance(session),
                      icon: const Icon(Icons.how_to_reg, size: 18),
                      label: const Text('View/Mark Attendance'),
                      style: TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateSession() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateSessionScreen()));

    if (result == true) {
      // Refresh the list
      ref.invalidate(teacherSessionsProvider);
    }
  }

  void _editSession(SessionModel session) async {
    // Check if this is a recurring instance
    if (session.isRecurringInstance && session.recurringSessionId != null) {
      // Show dialog to choose edit option
      final editOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Recurring Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This is part of a recurring series.', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
              const Text('What would you like to edit?'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, 'this'), child: const Text('This Session Only')),
            TextButton(onPressed: () => Navigator.pop(context, 'future'), child: const Text('All Future Sessions')),
          ],
        ),
      );

      if (editOption == null || !mounted) return;

      if (editOption == 'this') {
        // Edit this instance only - it will break from the series
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateSessionScreen(session: session)),
        );

        if (result == true) {
          ref.invalidate(teacherSessionsProvider);
        }
      } else if (editOption == 'future') {
        // TODO: Implement edit all future sessions (Phase 6 enhancement)
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Edit all future sessions coming soon!')));
        }
      }
    } else {
      // Regular one-time session or already broken from series
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateSessionScreen(session: session)),
      );

      if (result == true) {
        ref.invalidate(teacherSessionsProvider);
      }
    }
  }

  void _deleteSession(SessionModel session) async {
    // Check if this is a recurring instance
    if (session.isRecurringInstance && session.recurringSessionId != null) {
      // Show dialog to choose delete option
      final deleteOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Recurring Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This is part of a recurring series.', style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
              const Text('What would you like to delete?'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, 'this'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('This Session Only'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'future'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('All Future Sessions'),
            ),
          ],
        ),
      );

      if (deleteOption == null || !mounted) return;

      // Confirm deletion
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            deleteOption == 'this'
                ? 'Are you sure you want to delete this session?'
                : 'Are you sure you want to delete all future sessions in this series?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      try {
        if (deleteOption == 'this') {
          // Delete this instance only
          await Supabase.instance.client.from('class_sessions').delete().eq('id', session.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted successfully')));
            ref.invalidate(teacherSessionsProvider);
          }
        } else if (deleteOption == 'future') {
          // Delete all future sessions including this one
          final recurringId = session.recurringSessionId;
          if (recurringId != null) {
            await Supabase.instance.client
                .from('class_sessions')
                .delete()
                .eq('recurring_session_id', recurringId)
                .gte('session_date', session.sessionDate.toIso8601String().split('T')[0]);

            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Future sessions deleted successfully')));
              ref.invalidate(teacherSessionsProvider);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting session: $e')));
        }
      }
    } else {
      // Regular one-time session
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Session'),
          content: Text('Are you sure you want to delete "${session.title}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        try {
          await Supabase.instance.client.from('class_sessions').delete().eq('id', session.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted successfully')));
            ref.invalidate(teacherSessionsProvider);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting session: $e')));
          }
        }
      }
    }
  }

  void _cancelSession(SessionModel session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: Text('Are you sure you want to cancel "${session.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await Supabase.instance.client.from('class_sessions').update({'status': 'cancelled'}).eq('id', session.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session cancelled successfully')));
          ref.invalidate(teacherSessionsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cancelling session: $e')));
        }
      }
    }
  }

  void _markAttendance(SessionModel session) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceMarkingScreen(session: session)));
  }

  void _showSessionDetails(SessionModel session, {required bool isUpcoming}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                session.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.school, 'Classroom', session.classroomName),
              _buildDetailRow(Icons.calendar_today, 'Date', session.formattedDate),
              _buildDetailRow(Icons.access_time, 'Time', session.formattedTimeRange),
              if (session.description != null && session.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(session.description!),
              ],
              if (session.meetingUrl != null && session.meetingUrl!.isNotEmpty) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchMeetingUrl(session.meetingUrl!),
                    icon: const Icon(Icons.video_call),
                    label: const Text('Join Meeting'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],

              // Action buttons for upcoming sessions
              if (isUpcoming) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editSession(session);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteSession(session);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _launchMeetingUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // Use platformDefault for better compatibility
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);

      if (launched) {
      } else {
        throw 'Could not open meeting link';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open meeting link: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
