import 'dart:async';
import 'dart:math';

class MockPaymentService {
  // Simulate payment processing
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String paymentMethodId,
    required Map<String, dynamic> metadata,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // 90% success rate for testing
    final isSuccess = Random().nextDouble() > 0.1;
    
    if (isSuccess) {
      return {
        'success': true,
        'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'currency': 'USD',
        'status': 'succeeded',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata,
      };
    } else {
      throw Exception('Payment failed: Insufficient funds');
    }
  }
  
  // Get available payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      {
        'id': 'pm_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'card',
        'card': {
          'brand': 'visa',
          'last4': '4242',
          'expMonth': 12,
          'expYear': 2025,
        },
        'isDefault': true,
      },
      {
        'id': 'pm_${DateTime.now().millisecondsSinceEpoch + 1}',
        'type': 'card',
        'card': {
          'brand': 'mastercard',
          'last4': '4444',
          'expMonth': 6,
          'expYear': 2026,
        },
        'isDefault': false,
      },
    ];
  }
}
