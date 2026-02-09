import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:learned_flutter/features/student/services/payment_service.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';

// Provider for payment history
final paymentHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final paymentService = PaymentService();
  return await paymentService.getStudentPayments();
});

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentHistoryAsync = ref.watch(paymentHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(paymentHistoryProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: paymentHistoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading payments: $error'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => ref.refresh(paymentHistoryProvider), child: const Text('Retry')),
            ],
          ),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No payments yet', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Your payment history will appear here',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(paymentHistoryProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _PaymentCard(payment: payment);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatefulWidget {
  final Map<String, dynamic> payment;

  const _PaymentCard({required this.payment});

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _showProof = false;

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.cancel;
      case 'refunded':
        return Icons.replay;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.payment['status'] as String?;
    final amount = widget.payment['amount'] ?? 0.0;
    final classroom = widget.payment['classrooms'] as Map<String, dynamic>?;
    final paymentPlan = widget.payment['payment_plans'] as Map<String, dynamic>?;
    final createdAt = widget.payment['created_at'] as String?;
    final remarks = widget.payment['remarks'] as String?;
    final proofPath = widget.payment['payment_proof_path'] as String?;
    final paymentMethod = widget.payment['payment_method'] as String?;
    final transactionId = widget.payment['transaction_id'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        classroom?['name'] ?? 'Unknown Classroom',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Chip(
                      avatar: Icon(_getStatusIcon(status), size: 16, color: Colors.white),
                      label: Text(
                        status?.toUpperCase() ?? 'UNKNOWN',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(status),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Classroom details
                if (classroom != null) ...[
                  Row(
                    children: [
                      Icon(Icons.subject, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${classroom['subject']} • Grade ${classroom['grade_level']}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.currency_rupee, size: 20, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        amount.toStringAsFixed(2),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const Divider(),
                const SizedBox(height: 8),

                // Payment details
                _buildDetailRow(context, icon: Icons.calendar_today, label: 'Date', value: _formatDate(createdAt)),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  icon: Icons.payment,
                  label: 'Method',
                  value: _getPaymentMethodDisplay(paymentMethod),
                ),
                if (transactionId != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(context, icon: Icons.receipt, label: 'Transaction ID', value: transactionId),
                ],
                if (paymentPlan != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    icon: Icons.event_repeat,
                    label: 'Plan',
                    value: '${paymentPlan['name']} (${paymentPlan['billing_cycle']})',
                  ),
                ],

                // Remarks (if any)
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.note, size: 16, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'Admin Remarks:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(remarks, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],

                // Payment proof section
                if (proofPath != null && proofPath.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showProof = !_showProof;
                      });
                    },
                    icon: Icon(_showProof ? Icons.visibility_off : Icons.visibility),
                    label: Text(_showProof ? 'Hide Payment Proof' : 'View Payment Proof'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                  ),
                ],
              ],
            ),
          ),

          // Payment proof image (expanded)
          if (_showProof && proofPath != null && proofPath.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Proof Screenshot',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: PaymentService().getPaymentProofUrl(proofPath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error loading image: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (snapshot.hasData) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            snapshot.data!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.red),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Failed to load image', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
