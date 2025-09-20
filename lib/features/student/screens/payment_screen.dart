import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/features/student/services/classroom_service.dart';
import 'package:learned_flutter/features/student/screens/my_classes_screen.dart';
import 'package:learned_flutter/features/student/providers/student_profile_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> classroom;
  final String action;

  const PaymentScreen({super.key, required this.classroom, required this.action});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isProcessing = false;
  String? _selectedPaymentMethod = 'card';
  int _selectedPlanIndex = 0; // Track selected payment plan

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pricingList = widget.classroom['classroom_pricing'] as List? ?? [];

    // Debug: Print pricing list info
    print('🔍 PaymentScreen: Building with ${pricingList.length} pricing options');
    print('🔍 PaymentScreen: Selected plan index: $_selectedPlanIndex');
    for (int i = 0; i < pricingList.length; i++) {
      final pricing = pricingList[i];
      final plan = pricing['payment_plans'] as Map<String, dynamic>?;
      print('🔍 Plan $i: ${plan?['name']} - \$${pricing['price']}');
    }

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
                            '\$${price.toStringAsFixed(2)}',
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
                            '\$${price.toStringAsFixed(2)}',
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
                                      print('🔍 Payment plan selected: index $_selectedPlanIndex');
                                      final selectedPlan = pricingList[_selectedPlanIndex];
                                      final planData = selectedPlan['payment_plans'] as Map<String, dynamic>?;
                                      print('🔍 Selected plan: ${planData?['name']} - \$${selectedPlan['price']}');
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
                                      '\$${planPrice.toStringAsFixed(2)}',
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
                                      '\$${planPrice.toStringAsFixed(2)}',
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
                          children: [Icon(Icons.credit_card), SizedBox(width: 8), Text('Credit/Debit Card')],
                        ),
                        value: 'card',
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
                          children: [Icon(Icons.account_balance_wallet), SizedBox(width: 8), Text('PayPal')],
                        ),
                        value: 'paypal',
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
                        value: 'bank',
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

              // Payment Details (Card)
              if (_selectedPaymentMethod == 'card') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Card Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Cardholder Name', border: OutlineInputBorder()),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter cardholder name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cardNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Card Number',
                            border: OutlineInputBorder(),
                            hintText: '1234 5678 9012 3456',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.length < 16) {
                              return 'Please enter a valid card number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryController,
                                decoration: const InputDecoration(
                                  labelText: 'MM/YY',
                                  border: OutlineInputBorder(),
                                  hintText: '12/25',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.length < 5) {
                                    return 'Invalid expiry';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _cvvController,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  border: OutlineInputBorder(),
                                  hintText: '123',
                                ),
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.length < 3) {
                                    return 'Invalid CVV';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Other Payment Methods
              if (_selectedPaymentMethod == 'paypal') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'You will be redirected to PayPal to complete your payment.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (_selectedPaymentMethod == 'bank') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance, size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Bank transfer instructions will be sent to your email after confirming the enrollment.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Process Payment Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _processPayment,
                  icon: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.payment),
                  label: Text(_isProcessing ? 'Processing...' : 'Pay \$${price.toStringAsFixed(2)}'),
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
    if (_selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('🔍 _processPayment: Starting payment simulation...');

      // Simulate instant payment processing (bypassed for testing)
      await Future.delayed(const Duration(milliseconds: 500));

      print('🔍 _processPayment: Payment simulated successfully');

      // Get pricing info based on selected plan
      final pricingList = widget.classroom['classroom_pricing'] as List?;
      final pricingInfo = pricingList != null && pricingList.isNotEmpty
          ? pricingList[_selectedPlanIndex] as Map<String, dynamic>?
          : null;
      final price = pricingInfo?['price'] ?? 0.0;
      final paymentPlan = pricingInfo?['payment_plans'] as Map<String, dynamic>?;

      print('🔍 _processPayment: Selected plan index: $_selectedPlanIndex');
      print('🔍 _processPayment: Price: $price, Payment plan: ${paymentPlan?['name']}');

      // Enroll student (mock student ID for now)
      final classroomService = ClassroomService();
      print('🔍 _processPayment: Calling enrollStudent...');

      await classroomService.enrollStudent(
        studentId: null, // Use authenticated student ID
        classroomId: widget.classroom['id'],
        paymentPlanId: paymentPlan?['id'] ?? 'default-plan',
        amountPaid: price.toDouble(),
      );

      print('🔍 _processPayment: Enrollment successful');

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text('Payment Successful!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Welcome to ${widget.classroom['name']}!', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'You have been successfully enrolled. You will receive a confirmation email shortly.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: \$${price.toStringAsFixed(2)}',
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
                child: const Text('View My Classes'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('🔍 _processPayment: ERROR - $e');
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
}
