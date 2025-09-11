import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomDetailScreen({super.key, required this.classroomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔍 ClassroomDetailScreen: Building with classroomId: $classroomId');
    final classroomAsync = ref.watch(classroomDetailsProvider(classroomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: classroomAsync.when(
        loading: () {
          print('🔍 ClassroomDetailScreen: Loading state');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('🔍 ClassroomDetailScreen: Error state - $error');
          print('🔍 ClassroomDetailScreen: Stack trace - $stack');
          return Center(
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
          );
        },
        data: (classroom) {
          print('🔍 ClassroomDetailScreen: Data loaded successfully');
          print('🔍 ClassroomDetailScreen: Classroom data keys: ${classroom.keys.toList()}');
          print('🔍 ClassroomDetailScreen: Classroom name: ${classroom['name']}');
          print('🔍 ClassroomDetailScreen: Teacher data: ${classroom['teachers']}');
          print('🔍 ClassroomDetailScreen: Pricing data: ${classroom['classroom_pricing']}');
          return _buildClassroomDetails(context, ref, classroom);
        },
      ),
    );
  }

  Widget _buildClassroomDetails(BuildContext context, WidgetRef ref, Map<String, dynamic> classroom) {
    print('🔍 _buildClassroomDetails: Processing classroom data');
    final theme = Theme.of(context);

    // Debug pricing information
    final pricingList = classroom['classroom_pricing'] as List?;
    print('🔍 _buildClassroomDetails: Pricing list: $pricingList');
    print('🔍 _buildClassroomDetails: Pricing list length: ${pricingList?.length}');

    final pricingInfo = pricingList?.firstOrNull as Map<String, dynamic>?;
    print('🔍 _buildClassroomDetails: Pricing info: $pricingInfo');

    final price = pricingInfo?['price'] ?? 0.0;
    print('🔍 _buildClassroomDetails: Price: $price');

    final paymentPlan = pricingInfo?['payment_plans'] as Map<String, dynamic>?;
    print('🔍 _buildClassroomDetails: Payment plan: $paymentPlan');

    final billingCycle = paymentPlan?['billing_cycle'] ?? 'month';
    print('🔍 _buildClassroomDetails: Billing cycle: $billingCycle');

    // Debug teacher information
    final teacher = classroom['teachers'] as Map<String, dynamic>?;
    print('🔍 _buildClassroomDetails: Teacher data: $teacher');

    final teacherUser = teacher?['users'] as Map<String, dynamic>?;
    print('🔍 _buildClassroomDetails: Teacher user data: $teacherUser');
    print('🔍 _buildClassroomDetails: Teacher name from classroom: ${classroom['teacher_name']}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Classroom Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classroom['name'] ?? 'Unnamed Classroom',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${classroom['subject'] ?? 'N/A'} • Grade ${classroom['grade_level'] ?? 'N/A'}',
                              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                            ),
                            if (classroom['board'] != null) ...[
                              const SizedBox(height: 4),
                              Text('Board: ${classroom['board']}', style: theme.textTheme.bodyMedium),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Chip(
                            label: Text('${classroom['student_count'] ?? 0}/${classroom['max_students'] ?? 'N/A'}'),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('per $billingCycle', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  if (classroom['description'] != null) ...[
                    const SizedBox(height: 16),
                    Text(classroom['description'], style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Teacher Information
          if (teacher != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instructor', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: teacherUser?['profile_image_url'] != null
                              ? NetworkImage(teacherUser!['profile_image_url'])
                              : null,
                          child: teacherUser?['profile_image_url'] == null
                              ? Text(
                                  (teacherUser?['first_name']?[0] ?? 'T').toUpperCase(),
                                  style: theme.textTheme.titleLarge,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classroom['teacher_name'] ?? 'Teacher Info Unavailable',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (teacher['qualifications'] != null) ...[
                                const SizedBox(height: 4),
                                Text(teacher['qualifications'], style: theme.textTheme.bodyMedium),
                              ],
                              if (teacher['experience_years'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${teacher['experience_years']} years experience',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                              if (teacher['rating'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                                    const SizedBox(width: 4),
                                    Text('${teacher['rating']}/5', style: theme.textTheme.bodySmall),
                                    if (teacher['total_reviews'] != null)
                                      Text(
                                        ' (${teacher['total_reviews']} reviews)',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (teacher['bio'] != null) ...[
                      const SizedBox(height: 16),
                      Text(teacher['bio'], style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Payment Plan Details
          if (paymentPlan != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Plan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.payment, color: theme.colorScheme.primary),
                      title: Text(paymentPlan['name'] ?? 'Standard Plan'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (paymentPlan['description'] != null) Text(paymentPlan['description']),
                          const SizedBox(height: 4),
                          Text('Billing: Every $billingCycle', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      trailing: Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (paymentPlan['features'] != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Included Features:',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...List<String>.from(paymentPlan['features']).map(
                        (feature) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Expanded(child: Text(feature)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Enroll Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _handleEnrollment(context, classroom),
              icon: const Icon(Icons.school),
              label: const Text('Enroll Now'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEnrollment(BuildContext context, Map<String, dynamic> classroom) {
    print('🔍 _handleEnrollment: Starting enrollment process');
    print('🔍 _handleEnrollment: Classroom ID: ${classroom['id']}');
    print('🔍 _handleEnrollment: Classroom name: ${classroom['name']}');
    print('🔍 _handleEnrollment: Pricing data: ${classroom['classroom_pricing']}');

    // Navigate to payment screen
    print('🔍 _handleEnrollment: Navigating to payment screen');
    try {
      context.push('/payment', extra: {'classroom': classroom, 'action': 'enrollment'});
      print('🔍 _handleEnrollment: Navigation successful');
    } catch (e) {
      print('🔍 _handleEnrollment: Navigation error - $e');
    }
  }
}
