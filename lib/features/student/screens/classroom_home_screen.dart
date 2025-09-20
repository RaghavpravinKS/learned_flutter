import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';

class ClassroomHomeScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomHomeScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroomAsync = ref.watch(classroomDetailsProvider(classroomId));

    return Scaffold(
      body: classroomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading classroom: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(classroomDetailsProvider(classroomId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (classroom) => _buildClassroomHome(context, ref, classroom),
      ),
    );
  }

  Widget _buildClassroomHome(BuildContext context, WidgetRef ref, Map<String, dynamic> classroom) {
    final theme = Theme.of(context);
    final teacherName = classroom['teacher_name'] ?? 'Unknown Teacher';

    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              classroom['name'] ?? 'Classroom',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40), // Account for app bar
                  Icon(Icons.school, size: 48, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(height: 8),
                  Text(
                    '${classroom['subject']} • Grade ${classroom['grade_level']}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                  ),
                  Text('with $teacherName', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => context.push('/classroom-details/$classroomId'),
              tooltip: 'View Details',
            ),
          ],
        ),

        // Main Content
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.waving_hand, color: Colors.amber.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Welcome back!',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ready to continue your learning journey in ${classroom['name']}?',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildActionCard(
                            context,
                            icon: Icons.play_circle_fill,
                            title: 'Start Lesson',
                            subtitle: 'Continue learning',
                            color: Colors.green,
                            onTap: () => _showComingSoon(context, 'Lessons'),
                          ),
                          _buildActionCard(
                            context,
                            icon: Icons.assignment,
                            title: 'Assignments',
                            subtitle: 'View tasks',
                            color: Colors.blue,
                            onTap: () => _showComingSoon(context, 'Assignments'),
                          ),
                          _buildActionCard(
                            context,
                            icon: Icons.quiz,
                            title: 'Practice',
                            subtitle: 'Take quiz',
                            color: Colors.purple,
                            onTap: () => _showComingSoon(context, 'Practice'),
                          ),
                          _buildActionCard(
                            context,
                            icon: Icons.chat,
                            title: 'Discussion',
                            subtitle: 'Ask questions',
                            color: Colors.orange,
                            onTap: () => _showComingSoon(context, 'Discussion'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Your Progress',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: 0.35, // Placeholder progress
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '35% Complete',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '7 of 20 lessons',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Keep up the great work! You\'re making excellent progress.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Recent Activity
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Activity',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildActivityItem(
                        context,
                        icon: Icons.check_circle,
                        title: 'Completed: Introduction to Algebra',
                        time: '2 hours ago',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildActivityItem(
                        context,
                        icon: Icons.assignment_turned_in,
                        title: 'Submitted: Practice Problems Set 1',
                        time: '1 day ago',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildActivityItem(
                        context,
                        icon: Icons.star,
                        title: 'Earned badge: Quick Learner',
                        time: '3 days ago',
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 80), // Bottom padding
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature feature coming soon!'), duration: const Duration(seconds: 2)));
  }
}
