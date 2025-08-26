import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Courses'),
            Tab(text: 'Assessments'),
          ],
          labelColor: theme.primaryColor,
          indicatorColor: theme.primaryColor,
          unselectedLabelColor: theme.hintColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCoursesTab(),
          _buildAssessmentsTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    // Mock data - replace with actual data from provider
    final totalCourses = 5;
    final completedCourses = 2;
    final inProgressCourses = 2;
    final totalAssignments = 24;
    final completedAssignments = 15;
    final averageGrade = 87.5;
    
    final progressPercentage = (completedCourses / totalCourses * 100).round();
    final assignmentsPercentage = (completedAssignments / totalAssignments * 100).round();
    // assignmentsPercentage is used in the UI for the assignments progress indicator
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Progress',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$progressPercentage%',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completed: $completedCourses of $totalCourses courses',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '$completedAssignments of $totalAssignments assignments',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats
          Text(
            'Quick Stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Average Grade',
                '${averageGrade.toStringAsFixed(1)}%',
                Icons.school,
                Colors.blue,
              ),
              _buildStatCard(
                'In Progress',
                '$inProgressCourses Courses',
                Icons.hourglass_bottom,
                Colors.orange,
              ),
              _buildStatCard(
                'Assignments',
                '$completedAssignments/$totalAssignments',
                Icons.assignment_turned_in,
                Colors.green,
              ),
              _buildStatCard(
                'Completion',
                '$progressPercentage%',
                Icons.flag,
                Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            'Completed "Introduction to Flutter"',
            '2 hours ago',
            Icons.check_circle,
            Colors.green,
          ),
          _buildActivityItem(
            'Submitted Assignment #5',
            '1 day ago',
            Icons.assignment_turned_in,
            Colors.blue,
          ),
          _buildActivityItem(
            'Started "Advanced State Management"',
            '3 days ago',
            Icons.play_circle_fill,
            Colors.orange,
          ),
          _buildActivityItem(
            'Completed Quiz #3 with 92%',
            '1 week ago',
            Icons.quiz,
            Colors.purple,
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildCoursesTab() {
    // Mock data - replace with actual data from provider
    final courses = [
      {
        'title': 'Introduction to Flutter',
        'instructor': 'Jane Smith',
        'progress': 1.0,
        'completed': true,
        'grade': 95,
      },
      {
        'title': 'Advanced State Management',
        'instructor': 'John Doe',
        'progress': 0.6,
        'completed': false,
        'grade': null,
      },
      {
        'title': 'UI/UX Design for Developers',
        'instructor': 'Alex Johnson',
        'progress': 0.3,
        'completed': false,
        'grade': null,
      },
      {
        'title': 'Testing in Flutter',
        'instructor': 'Sarah Williams',
        'progress': 0.0,
        'completed': false,
        'grade': null,
      },
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final progress = course['progress'] as double;
        final completed = course['completed'] as bool;
        final grade = course['grade'] as int?;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        course['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (completed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Instructor: ${course['instructor']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completed ? Colors.green : Theme.of(context).primaryColor,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (grade != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.grade, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Grade: $grade%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAssessmentsTab() {
    // Mock data - replace with actual data from provider
    final assessments = [
      {
        'title': 'Mid-term Exam',
        'course': 'Introduction to Flutter',
        'score': 92,
        'total': 100,
        'date': '2023-05-15',
        'passed': true,
      },
      {
        'title': 'Assignment #3',
        'course': 'Advanced State Management',
        'score': 45,
        'total': 50,
        'date': '2023-05-10',
        'passed': true,
      },
      {
        'title': 'Quiz #2',
        'course': 'UI/UX Design',
        'score': 38,
        'total': 50,
        'date': '2023-05-05',
        'passed': true,
      },
      {
        'title': 'Final Project',
        'course': 'Testing in Flutter',
        'score': null,
        'total': 100,
        'date': '2023-06-20',
        'passed': null,
      },
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assessments.length,
      itemBuilder: (context, index) {
        final assessment = assessments[index];
        final score = assessment['score'] as int?;
        final total = assessment['total'] as int;
        final passed = assessment['passed'] as bool?;
        final percentage = score != null ? (score / total * 100).round() : null;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment['title'] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assessment['course'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (score != null) ...[
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: passed! ? Colors.green : Colors.red,
                            width: 3,
                          ),
                        ),
                        child: Text(
                          '$score/$total',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: passed ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${percentage!}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: passed ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            passed ? 'Passed' : 'Failed',
                            style: TextStyle(
                              color: passed ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Icon(Icons.timer, size: 24, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Not submitted yet'),
                    ],
                    const Spacer(),
                    Text(
                      assessment['date'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
