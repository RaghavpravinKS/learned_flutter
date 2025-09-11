import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/features/student/models/course_progress_model.dart';
import 'package:learned_flutter/features/student/providers/course_progress_provider.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/routes/app_routes.dart';

class CourseProgressSection extends ConsumerWidget {
  const CourseProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(courseProgressProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/student/courses'),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Failed to load courses. Please try again later.',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            data: (courses) => courses.isEmpty
                ? const Center(
                    child: Text(
                      'No courses in progress',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return GestureDetector(
                        onTap: () => context.go(
                          '${AppRoutes.studentSessionDetails}/${course.courseId}',
                        ),
                        child: _buildCourseProgressCard(course, context),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseProgressCard(CourseProgress course, BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              Text(
                '${(course.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.courseName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: course.progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              course.progress >= 70
                  ? Colors.green
                  : course.progress >= 30
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.completedLessons} of ${course.totalLessons} lessons',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
