import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Success Message
              Text(
                'Payment Successful!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'You have successfully enrolled in the classroom. You can now access all the course materials and join scheduled sessions.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Navigate to classroom or dashboard
                    context.go('/classrooms');
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to My Classes'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  // Navigate to home
                  context.go('/');
                },
                child: const Text('Back to Home'),
              ),
              
              const SizedBox(height: 24),
              
              // Order Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildOrderItem('Order Number', '#${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
                    const SizedBox(height: 8),
                    _buildOrderItem('Date', _formatDate(DateTime.now())),
                    const SizedBox(height: 8),
                    _buildOrderItem('Total', '\$29.99', isBold: true),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Help Section
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement contact support
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Need help? Contact support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderItem(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${_getMonth(date.month)} ${date.day}, ${date.year}';
  }
  
  String _getMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
