import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/features/student/services/payment_service.dart';
import 'package:learned_flutter/features/student/screens/my_classes_screen.dart';
import 'package:learned_flutter/features/student/providers/student_profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> classroom;
  final String action;

  const PaymentScreen({super.key, required this.classroom, required this.action});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;
  String? _selectedPaymentMethod = 'upi';
  int _selectedPlanIndex = 0; // Track selected payment plan
  XFile? _paymentProofImage;

  // Payment details constants
  static const String upiId = 'learnedplatform@paytm';
  static const String bankAccountName = 'LearnED Platform';
  static const String bankAccountNumber = '1234567890';
  static const String ifscCode = 'SBIN0001234';
  static const String bankName = 'State Bank of India';
  static const String bankBranch = 'Main Branch';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricingList = widget.classroom['classroom_pricing'] as List? ?? [];

    // Get selected pricing info
    final selectedPricing = pricingList.isNotEmpty ? pricingList[_selectedPlanIndex] : null;
    final price = selectedPricing?['price'] ?? 0.0;
    final paymentPlan = selectedPricing?['payment_plans'] as Map<String, dynamic>?;
    final billingCycle = paymentPlan?['billing_cycle'] ?? 'month';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Summary', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.school, color: theme.colorScheme.onPrimaryContainer, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.classroom['name'] ?? 'Unknown Classroom',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.classroom['subject']} • Grade ${widget.classroom['grade_level']}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Taught by: ${widget.classroom['teacher_name'] ?? 'Unknown'}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Enrollment Fee', style: theme.textTheme.titleMedium),
                          Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Billing Cycle',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            'Every $billingCycle',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Plan Selection
              if (pricingList.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pricingList.length > 1 ? 'Select Plan' : 'Plan Details',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...pricingList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final pricingInfo = entry.value;
                          final planPrice = pricingInfo['price'] ?? 0.0;
                          final plan = pricingInfo['payment_plans'] as Map<String, dynamic>?;
                          final cycle = plan?['billing_cycle'] ?? 'month';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: pricingList.length > 1
                                ? RadioListTile<int>(
                                    value: index,
                                    groupValue: _selectedPlanIndex,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPlanIndex = value ?? 0;
                                      });
                                    },
                                    title: Text(plan?['name'] ?? 'Plan ${index + 1}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Every $cycle'),
                                        if (plan?['features'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            List<String>.from(plan!['features']).take(2).join(' • '),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    secondary: Text(
                                      '₹${planPrice.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  )
                                : ListTile(
                                    leading: Icon(Icons.check_circle, color: theme.colorScheme.primary),
                                    title: Text(plan?['name'] ?? 'Plan ${index + 1}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Every $cycle'),
                                        if (plan?['features'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            List<String>.from(plan!['features']).take(2).join(' • '),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Text(
                                      '₹${planPrice.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Payment Method Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Method', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      RadioListTile<String>(
                        title: const Row(
                          children: [Icon(Icons.account_balance_wallet), SizedBox(width: 8), Text('UPI Payment')],
                        ),
                        value: 'upi',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        title: const Row(
                          children: [Icon(Icons.account_balance), SizedBox(width: 8), Text('Bank Transfer')],
                        ),
                        value: 'bank_transfer',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Payment Details
              if (_selectedPaymentMethod == 'upi') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPI Payment Details',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // UPI ID Display with copy and open functionality
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.primary, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pay to this UPI ID:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _launchUPI(),
                                      child: Text(
                                        upiId,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                                    onPressed: () {
                                      Clipboard.setData(const ClipboardData(text: upiId));
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(const SnackBar(content: Text('UPI ID copied to clipboard')));
                                    },
                                    tooltip: 'Copy UPI ID',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap on the UPI ID to open your payment app',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Amount: ₹${price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (_selectedPaymentMethod == 'bank_transfer') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Transfer Details',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.secondary, width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBankDetailRow('Account Name', bankAccountName, theme),
                              const Divider(height: 16),
                              _buildBankDetailRow('Account Number', bankAccountNumber, theme),
                              const Divider(height: 16),
                              _buildBankDetailRow('IFSC Code', ifscCode, theme),
                              const Divider(height: 16),
                              _buildBankDetailRow('Bank Name', bankName, theme),
                              const Divider(height: 16),
                              _buildBankDetailRow('Branch', bankBranch, theme),
                              const Divider(height: 16),
                              _buildBankDetailRow('Amount', '₹${price.toStringAsFixed(2)}', theme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Payment Proof Upload
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Payment Proof',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a screenshot of your payment confirmation',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '* Required - Payment cannot be submitted without proof',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display selected image or placeholder
                      if (_paymentProofImage != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_paymentProofImage!.path), fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickPaymentProof(ImageSource.gallery),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Change Image'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _paymentProofImage = null;
                                });
                              },
                              icon: const Icon(Icons.delete),
                              tooltip: 'Remove',
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 48, color: theme.colorScheme.primary),
                              const SizedBox(height: 8),
                              Text('No image selected', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _pickPaymentProof(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Choose from Gallery'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: () => _pickPaymentProof(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Take Photo'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Process Payment Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _processPayment,
                  icon: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload),
                  label: Text(_isProcessing ? 'Submitting...' : 'Submit Payment'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),

              const SizedBox(height: 16),

              // Security Notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your payment information is secure and encrypted.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_paymentProofImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please upload payment proof'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get pricing info based on selected plan
      final pricingList = widget.classroom['classroom_pricing'] as List?;
      final pricingInfo = pricingList != null && pricingList.isNotEmpty
          ? pricingList[_selectedPlanIndex] as Map<String, dynamic>?
          : null;
      final price = pricingInfo?['price'] ?? 0.0;
      final paymentPlan = pricingInfo?['payment_plans'] as Map<String, dynamic>?;

      // Create pending payment with proof
      final paymentService = PaymentService();
      final result = await paymentService.createPendingPayment(
        classroomId: widget.classroom['id'],
        paymentPlanId: paymentPlan?['id'] ?? 'default-plan',
        amount: price.toDouble(),
        paymentMethod: _selectedPaymentMethod ?? 'upi',
        proofImage: _paymentProofImage!,
        transactionId: null, // Transaction ID will be added by admin during verification
      );

      if (mounted) {
        if (result['success'] == true) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.pending_actions, color: Colors.orange, size: 64),
              title: const Text('Payment Submitted!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your payment for ${widget.classroom['name']} has been submitted for verification.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You will be notified once the admin verifies your payment. This usually takes 1-2 business days.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ₹${price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    // Invalidate providers to refresh data
                    ref.invalidate(enrolledClassroomsProvider);
                    ref.invalidate(studentEnrollmentStatsProvider);
                    ref.invalidate(currentStudentProfileProvider);

                    context.pop(); // Close dialog
                    context.go('/student/sessions'); // Navigate to My Classes
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment submission failed: ${result['error']}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Helper method to pick payment proof image
  Future<void> _pickPaymentProof(ImageSource source) async {
    try {
      final paymentService = PaymentService();
      final image = await paymentService.pickPaymentProof(source: source);
      if (image != null) {
        setState(() {
          _paymentProofImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // Helper method to launch UPI app
  Future<void> _launchUPI() async {
    final url = Uri.parse(
      'upi://pay?pa=$upiId&pn=$bankAccountName&cu=INR&am=${widget.classroom['classroom_pricing']?[_selectedPlanIndex]?['price'] ?? 0}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Copy UPI ID to clipboard
        await Clipboard.setData(const ClipboardData(text: upiId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UPI ID copied to clipboard. Please open your payment app manually.')),
          );
        }
      }
    } catch (e) {
      // Fallback: Copy UPI ID to clipboard
      await Clipboard.setData(const ClipboardData(text: upiId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied to clipboard')));
      }
    }
  }

  // Helper method to build bank detail rows
  Widget _buildBankDetailRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
        ),
        Row(
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
              },
              child: Icon(Icons.copy, size: 16, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ],
    );
  }
}
