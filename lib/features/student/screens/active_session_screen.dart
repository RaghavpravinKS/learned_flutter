import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? sessionData;

  const ActiveSessionScreen({
    super.key,
    required this.sessionId,
    this.sessionData,
  });

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  bool _isMuted = false;
  bool _isVideoOn = true;
  bool _isScreenSharing = false;
  bool _isChatOpen = false;
  bool _isHandRaised = false;
  bool _isConnected = true;
  Duration _elapsedTime = Duration.zero;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // TODO: Initialize video call with the session data
  }

  @override
  void dispose() {
    _timer.cancel();
    // TODO: Clean up video call resources
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime += const Duration(seconds: 1);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // TODO: Update audio state in the video call
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOn = !_isVideoOn;
    });
    // TODO: Update video state in the video call
  }

  void _toggleScreenShare() {
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });
    // TODO: Handle screen sharing
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  void _toggleHandRaise() {
    setState(() {
      _isHandRaised = !_isHandRaised;
    });
    // TODO: Send hand raise signal to teacher
  }

  Future<void> _endSession() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Would you like to provide feedback about this session?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Don't provide feedback
            },
            child: const Text('No Thanks'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Provide feedback
            },
            child: const Text('Provide Feedback'),
          ),
        ],
      ),
    );

    if (shouldEnd != null && mounted) {
      if (shouldEnd) {
        // Navigate to feedback screen
        final currentPath = GoRouterState.of(context).matchedLocation;
        context.push(
          '$currentPath/feedback',
          extra: widget.sessionData,
        );
      } else {
        // Just go back to the previous screen
        if (mounted) {
          context.pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classroom = widget.sessionData?['classrooms'] as Map<String, dynamic>? ?? {};
    final subject = widget.sessionData?['subject'] as Map<String, dynamic>? ?? {};
    final teacher = classroom['teacher'] as Map<String, dynamic>? ?? {};
    final teacherName = '${teacher['first_name'] ?? ''} ${teacher['last_name'] ?? ''}'.trim();

    return WillPopScope(
      onWillPop: () async {
        await _endSession();
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Main video area
              Column(
                children: [
                  // Teacher's video (or placeholder)
                  Expanded(
                    child: Container(
                      color: Colors.grey[900],
                      child: Stack(
                        children: [
                          // Placeholder for teacher's video
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  teacherName.isNotEmpty ? teacherName : 'Teacher',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_isConnected) ...[
                                  const SizedBox(height: 8),
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.signal_wifi_off, color: Colors.red, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Reconnecting...',
                                        style: TextStyle(color: Colors.red, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Session info overlay
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _isConnected ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDuration(_elapsedTime),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    subject['name'] ?? 'Class',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Student's video preview (or placeholder)
                  if (_isVideoOn)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 160,
                        height: 120,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.primaryColor, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_off, size: 32, color: Colors.white54),
                            const SizedBox(height: 8),
                            Text(
                              'You',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
              // Bottom controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        isActive: !_isMuted,
                        onPressed: _toggleMute,
                      ),
                      _buildControlButton(
                        icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                        label: _isVideoOn ? 'Stop Video' : 'Start Video',
                        isActive: _isVideoOn,
                        onPressed: _toggleVideo,
                      ),
                      _buildControlButton(
                        icon: Icons.screen_share,
                        label: 'Share',
                        isActive: _isScreenSharing,
                        onPressed: _toggleScreenShare,
                      ),
                      _buildControlButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        isActive: _isChatOpen,
                        onPressed: _toggleChat,
                      ),
                      _buildControlButton(
                        icon: _isHandRaised ? Icons.back_hand : Icons.back_hand_outlined,
                        label: _isHandRaised ? 'Lower Hand' : 'Raise Hand',
                        isActive: _isHandRaised,
                        onPressed: _toggleHandRaise,
                      ),
                      const SizedBox(width: 8),
                      // End call button
                      FloatingActionButton(
                        onPressed: _endSession,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.call_end, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Chat panel (conditionally shown)
              if (_isChatOpen)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 120,
                  width: 300,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Chat header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: _toggleChat,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        // Chat messages
                        Expanded(
                          child: Center(
                            child: Text(
                              'Chat is not implemented yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                        // Message input
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () {
                                  // TODO: Send message
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: isActive ? Colors.white : Colors.red),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
