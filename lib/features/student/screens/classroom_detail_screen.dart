import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/providers/classroom_provider.dart';
import 'package:learned_flutter/features/student/services/payment_service.dart';
import 'package:intl/intl.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final String classroomId;

  const ClassroomDetailScreen({super.key, required this.classroomId});

  // Helper method to get the lowest price from pricing list
  double _getLowestPrice(List pricingList) {
    if (pricingList.isEmpty) return 0.0;

    return pricingList
        .map<double>((pricing) {
          return (pricing['price'] ?? 0.0).toDouble();
        })
        .reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroomAsync = ref.watch(classroomDetailsProvider(classroomId));
    final enrollmentStatusAsync = ref.watch(studentEnrollmentStatusProvider(classroomId));
    final pendingPaymentAsync = ref.watch(pendingPaymentForClassroomProvider(classroomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
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
        data: (classroom) => enrollmentStatusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildClassroomDetails(context, ref, classroom, false, null),
          data: (isEnrolled) => pendingPaymentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildClassroomDetails(context, ref, classroom, isEnrolled, null),
            data: (pendingPayment) => _buildClassroomDetails(context, ref, classroom, isEnrolled, pendingPayment),
          ),
        ),
      ),
    );
  }

  Widget _buildClassroomDetails(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> classroom,
    bool isEnrolled,
    Map<String, dynamic>? pendingPayment,
  ) {
    final theme = Theme.of(context);

    // Debug pricing information
    final pricingList = classroom['classroom_pricing'] as List?;

    // Debug teacher information
    final teacher = classroom['teachers'] as Map<String, dynamic>?;
    final teacherUser = teacher?['users'] as Map<String, dynamic>?;

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
                          if (pricingList != null && pricingList.isNotEmpty)
                            Text('Starting from', style: theme.textTheme.bodySmall),
                          if (pricingList != null && pricingList.isNotEmpty)
                            Text(
                              '\$${_getLowestPrice(pricingList).toStringAsFixed(2)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

          // Pricing Plans Section
          if (pricingList != null && pricingList.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose Your Plan', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...pricingList.map<Widget>((pricingInfo) {
                      final price = pricingInfo['price'] ?? 0.0;
                      final paymentPlan = pricingInfo['payment_plans'] as Map<String, dynamic>?;
                      final billingCycle = paymentPlan?['billing_cycle'] ?? 'month';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            paymentPlan?['name'] ?? 'Standard Plan',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (paymentPlan?['description'] != null) ...[
                                const SizedBox(height: 4),
                                Text(paymentPlan!['description']),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Billing: Every $billingCycle',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                              ),
                              if (paymentPlan?['features'] != null) ...[
                                const SizedBox(height: 8),
                                ...List<String>.from(paymentPlan!['features'])
                                    .take(3)
                                    .map(
                                      (feature) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 1),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text(feature, style: theme.textTheme.bodySmall)),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text('per $billingCycle', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Enroll Button
          if (pricingList != null && pricingList.isNotEmpty) ...[
            Text(
              pricingList.length > 1
                  ? 'Choose your preferred plan during enrollment'
                  : 'Ready to enroll in this classroom?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],

          // Conditional UI based on enrollment status
          if (isEnrolled) ...[
            // Enrolled Student UI
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You are enrolled in this classroom',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToClassroom(context, classroom),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Learning'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _viewProgress(context, classroom),
                            icon: const Icon(Icons.analytics),
                            label: const Text('View Progress'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade600),
                              foregroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else if (pendingPayment != null) ...[
            // Pending Payment UI
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pending, color: Colors.orange.shade700, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Pending Verification',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your payment is under review by the admin',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Payment Details
                    _buildPaymentDetailRow(
                      theme,
                      'Amount',
                      '₹${(pendingPayment['amount'] ?? 0.0).toStringAsFixed(2)}',
                      Icons.currency_rupee,
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentDetailRow(
                      theme,
                      'Payment Method',
                      _getPaymentMethodDisplay(pendingPayment['payment_method']),
                      Icons.payment,
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentDetailRow(
                      theme,
                      'Submitted',
                      _formatDate(pendingPayment['created_at']),
                      Icons.calendar_today,
                    ),

                    // Payment Proof Preview
                    if (pendingPayment['payment_proof_path'] != null) ...[
                      const Divider(height: 24),
                      Text('Payment Proof', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      FutureBuilder<String>(
                        future: PaymentService().getPaymentProofUrl(pendingPayment['payment_proof_path']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Container(
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.red),
                                    SizedBox(height: 8),
                                    Text('Failed to load image'),
                                  ],
                                ),
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              snapshot.data!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verification typically takes 1-2 business days. You will be notified once approved.',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Non-enrolled Student UI - No pending payment
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Ready to start your learning journey?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _handleEnrollment(context, classroom),
                        icon: const Icon(Icons.school),
                        label: Text(
                          pricingList != null && pricingList.length > 1 ? 'Choose Plan & Enroll' : 'Enroll Now',
                        ),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleEnrollment(BuildContext context, Map<String, dynamic> classroom) {
    // Navigate to payment screen
    try {
      context.push('/payment', extra: {'classroom': classroom, 'action': 'enrollment'});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigation error: $e')));
    }
  }

  void _navigateToClassroom(BuildContext context, Map<String, dynamic> classroom) {
    // Navigate to classroom home for enrolled students
    context.push('/classroom-home/${classroom['id']}');
  }

  void _viewProgress(BuildContext context, Map<String, dynamic> classroom) {
    // TODO: Navigate to student progress screen
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress tracking coming soon!')));
  }

  // Helper method to build payment detail rows
  Widget _buildPaymentDetailRow(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Helper method to format date
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Helper method to display payment method
  String _getPaymentMethodDisplay(String? method) {
    switch (method?.toLowerCase()) {
      case 'upi':
        return 'UPI Payment';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'card':
        return 'Card Payment';
      default:
        return method ?? 'Unknown';
    }
  }
}
