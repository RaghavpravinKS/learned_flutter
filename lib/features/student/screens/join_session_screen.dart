import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class JoinSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? sessionData;

  const JoinSessionScreen({super.key, required this.sessionId, this.sessionData});

  @override
  ConsumerState<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends ConsumerState<JoinSessionScreen> {
  bool _isLoading = false;
  bool _canJoin = false;
  late Map<String, dynamic> _sessionData;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _sessionData = widget.sessionData ?? {};
    _initializeSessionData();
    _checkIfCanJoin();
  }

  void _initializeSessionData() {
    // Parse session date and times
    final sessionDate = _sessionData['session_date'] as String?;
    final startTimeStr = _sessionData['start_time'] as String?;
    final endTimeStr = _sessionData['end_time'] as String?;

    if (sessionDate != null && startTimeStr != null && endTimeStr != null) {
      _startTime = DateTime.parse('$sessionDate $startTimeStr').toLocal();
      _endTime = DateTime.parse('$sessionDate $endTimeStr').toLocal();
    } else {
      // Fallback to current time if data is missing
      _startTime = DateTime.now();
      _endTime = DateTime.now().add(const Duration(hours: 1));
    }
  }

  Future<void> _checkIfCanJoin() async {
    final now = DateTime.now();
    final joinTime = _startTime.subtract(const Duration(minutes: 5));

    setState(() {
      _canJoin = now.isAfter(joinTime) && now.isBefore(_endTime);
    });
  }

  Future<void> _joinSession() async {
    if (!_canJoin) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Add any pre-session checks or initialization
      await Future.delayed(const Duration(seconds: 1)); // Simulate network call

      if (mounted) {
        // Navigate to active session screen
        // Using push instead of go to maintain the navigation stack
        // This allows users to go back to the join screen if needed
        final currentPath = GoRouterState.of(context).matchedLocation;
        context.push('$currentPath/active', extra: _sessionData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error joining session: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classroom = _sessionData['classrooms'] as Map<String, dynamic>? ?? {};
    final teacher = classroom['teacher'] as Map<String, dynamic>? ?? {};
    final teacherUser = teacher['users'] as Map<String, dynamic>? ?? {};

    // Get subject from classroom
    final subject = classroom['subject'] as String? ?? 'No Subject';

    // Get teacher name
    final firstName = teacherUser['first_name'] as String? ?? '';
    final lastName = teacherUser['last_name'] as String? ?? '';
    final teacherName = '$firstName $lastName'.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to schedule screen
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          radius: 30,
                          child: Icon(Icons.school, size: 32, color: theme.primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                teacherName.isNotEmpty ? teacherName : 'No Teacher',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(Icons.access_time, '${DateFormat('EEEE, MMM d, y').format(_startTime)}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.schedule,
                      '${DateFormat.jm().format(_startTime)} - ${DateFormat.jm().format(_endTime)}',
                    ),
                    if (_sessionData['meeting_url'] != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.videocam, 'Online Session', isOnline: true),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Join Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canJoin && !_isLoading ? _joinSession : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_canJoin ? 'Join Session' : 'Session Not Started', style: const TextStyle(fontSize: 16)),
              ),
            ),

            if (!_canJoin) ...[
              const SizedBox(height: 16),
              Text(
                'You can join the session 5 minutes before the scheduled start time.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // Session Instructions
            Text('Instructions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildInstructionItem('1. Make sure you have a stable internet connection.', Icons.wifi),
            _buildInstructionItem('2. Use headphones for better audio quality.', Icons.headphones),
            _buildInstructionItem('3. Find a quiet and well-lit place for the session.', Icons.lightbulb_outline),
            _buildInstructionItem('4. Have your learning materials ready.', Icons.menu_book),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isOnline = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isOnline ? Colors.green : null),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: isOnline ? Colors.green : null)),
      ],
    );
  }

  Widget _buildInstructionItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
