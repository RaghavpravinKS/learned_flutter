import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

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
      // Old format: separate date and time strings
      _startTime = DateTime.parse('$sessionDate $startTimeStr').toLocal();
      _endTime = DateTime.parse('$sessionDate $endTimeStr').toLocal();
    } else if (startTimeStr != null && endTimeStr != null) {
      // New format: ISO 8601 strings from SessionModel.toJson()
      try {
        _startTime = DateTime.parse(startTimeStr).toLocal();
        _endTime = DateTime.parse(endTimeStr).toLocal();
      } catch (e) {
        // Fallback to current time if parsing fails
        _startTime = DateTime.now();
        _endTime = DateTime.now().add(const Duration(hours: 1));
      }
    } else {
      // Fallback to current time if data is missing
      _startTime = DateTime.now();
      _endTime = DateTime.now().add(const Duration(hours: 1));
    }
  }

  Future<void> _checkIfCanJoin() async {
    final now = DateTime.now();

    setState(() {
      // Allow joining anytime before the session ends
      _canJoin = now.isBefore(_endTime);
    });
  }

  Future<void> _joinSession() async {
    if (!_canJoin) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get meeting URL from session data
      final meetingUrl = _sessionData['meeting_url'] as String?;

      print('📞 Attempting to join session with URL: $meetingUrl');

      if (meetingUrl == null || meetingUrl.isEmpty) {
        throw 'No meeting URL available for this session';
      }

      // Validate URL format
      if (!meetingUrl.startsWith('http://') && !meetingUrl.startsWith('https://')) {
        throw 'Invalid meeting URL format. URL must start with http:// or https://';
      }

      // Launch the meeting URL
      final uri = Uri.parse(meetingUrl);
      print('🔗 Parsed URI: $uri');

      // Try to launch with platformDefault first (opens in browser or app)
      // This is more reliable than externalApplication on Android
      try {
        print('✅ Attempting to launch URL...');
        final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);

        if (launched) {
          print('✅ URL launched successfully');
        } else {
          print('❌ Launch returned false');
          throw 'Failed to open meeting URL';
        }
      } catch (launchError) {
        print('❌ Launch error: $launchError');
        throw 'Could not open meeting URL. Error: $launchError';
      }
    } catch (e) {
      print('❌ Error joining session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining session: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
          ),
        );
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

    // Handle two data formats:
    // 1. Nested format from schedule screen: { classrooms: { subject, teacher: { users: { first_name, last_name } } } }
    // 2. Flat format from SessionModel.toJson(): { subject, teacher_name }

    String subject;
    String teacherName;

    if (_sessionData['classrooms'] != null) {
      // Nested format from schedule screen
      final classroom = _sessionData['classrooms'] as Map<String, dynamic>? ?? {};
      final teacher = classroom['teacher'] as Map<String, dynamic>? ?? {};
      final teacherUser = teacher['users'] as Map<String, dynamic>? ?? {};

      subject = classroom['subject'] as String? ?? 'No Subject';

      final firstName = teacherUser['first_name'] as String? ?? '';
      final lastName = teacherUser['last_name'] as String? ?? '';
      teacherName = '$firstName $lastName'.trim();
    } else {
      // Flat format from SessionModel.toJson()
      subject = _sessionData['subject'] as String? ?? 'No Subject';
      teacherName = _sessionData['teacher_name'] as String? ?? 'Teacher';
    }

    if (teacherName.isEmpty) {
      teacherName = 'Teacher';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Session'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    : Text(_canJoin ? 'Join Session' : 'Session Ended', style: const TextStyle(fontSize: 16)),
              ),
            ),

            if (!_canJoin) ...[
              const SizedBox(height: 16),
              Text(
                'This session has already ended.',
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
