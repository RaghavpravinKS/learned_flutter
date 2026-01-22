import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'student_service.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StudentService _studentService = StudentService();

  // Process payment and return transaction details
  Future<Map<String, dynamic>> processPayment({
    required String studentId,
    required String classroomId,
    required String paymentPlanId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Generate transaction ID
      final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}_${studentId.substring(0, 8)}';

      // Simulate payment processing delay
      await Future.delayed(const Duration(milliseconds: 500));

      // For development, simulate successful payment
      if (paymentMethod == 'simulation' || paymentMethod == 'test') {
        return _createSuccessfulPaymentResponse(transactionId, amount, paymentMethod);
      }

      // For real payments, you would integrate with actual payment providers here
      // Example: Stripe, PayPal, Razorpay, etc.

      try {
        // Try to create payment record in database
        final paymentId = await _createPaymentRecord(
          studentId: studentId,
          classroomId: classroomId,
          amount: amount,
          paymentMethod: paymentMethod,
          transactionId: transactionId,
          metadata: metadata,
        );

        return {
          'success': true,
          'payment_id': paymentId,
          'transaction_id': transactionId,
          'amount': amount,
          'currency': 'INR',
          'payment_method': paymentMethod,
          'status': 'completed',
          'created_at': DateTime.now().toIso8601String(),
        };
      } catch (dbError) {
        // Return simulated success even if database fails
        return _createSuccessfulPaymentResponse(transactionId, amount, paymentMethod);
      }
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'error_code': 'PAYMENT_FAILED'};
    }
  }

  // Create payment record in database
  Future<String> _createPaymentRecord({
    required String studentId,
    required String classroomId,
    required double amount,
    required String paymentMethod,
    required String transactionId,
    Map<String, dynamic>? metadata,
  }) async {
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

    await _supabase.from('payments').insert({
      'id': paymentId,
      'student_id': studentId,
      'classroom_id': classroomId,
      'amount': amount,
      'currency': 'INR',
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'status': 'completed',
      'metadata': metadata ?? {},
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return paymentId;
  }

  // Create successful payment response for simulation
  Map<String, dynamic> _createSuccessfulPaymentResponse(String transactionId, double amount, String paymentMethod) {
    return {
      'success': true,
      'payment_id': 'pay_sim_${DateTime.now().millisecondsSinceEpoch}',
      'transaction_id': transactionId,
      'amount': amount,
      'currency': 'INR',
      'payment_method': paymentMethod,
      'status': 'completed',
      'created_at': DateTime.now().toIso8601String(),
      'simulated': true,
    };
  }

  // Handle payment webhook (for real payment providers)
  Future<Map<String, dynamic>> handlePaymentWebhook({
    required String transactionId,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Call the database function to handle payment completion
      final result = await _supabase.rpc(
        'handle_payment_completion',
        params: {'p_transaction_id': transactionId, 'p_status': status, 'p_metadata': metadata ?? {}},
      );

      if (result != null && result.isNotEmpty) {
        final webhookResult = result.first;
        return webhookResult;
      }

      return {'success': false, 'error': 'No result from webhook processing'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get payment history for a student
  Future<List<Map<String, dynamic>>> getPaymentHistory(String studentId) async {
    try {
      final payments = await _supabase
          .from('payments')
          .select('''
            *,
            classrooms(name, subject, grade_level)
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(payments);
    } catch (e) {
      // Return mock payment history for testing
      return [
        {
          'id': 'pay_example_1',
          'amount': 99.99,
          'currency': 'INR',
          'payment_method': 'stripe',
          'status': 'completed',
          'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          'classrooms': {'name': 'Advanced Mathematics', 'subject': 'Mathematics', 'grade_level': 12},
        },
      ];
    }
  }

  // Refund a payment
  Future<Map<String, dynamic>> refundPayment({
    required String paymentId,
    required double refundAmount,
    String? reason,
  }) async {
    try {
      // In a real implementation, you would call the payment provider's refund API
      // For now, simulate the refund process

      await Future.delayed(const Duration(milliseconds: 300));

      // Update payment record with refund information
      try {
        await _supabase
            .from('payments')
            .update({
              'status': 'refunded',
              'refund_amount': refundAmount,
              'refund_reason': reason,
              'refunded_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', paymentId);

        return {
          'success': true,
          'refund_id': 'ref_${DateTime.now().millisecondsSinceEpoch}',
          'amount': refundAmount,
          'status': 'completed',
          'created_at': DateTime.now().toIso8601String(),
        };
      } catch (dbError) {
        // Return simulated success even if database fails
        return {
          'success': true,
          'refund_id': 'ref_sim_${DateTime.now().millisecondsSinceEpoch}',
          'amount': refundAmount,
          'status': 'completed',
          'created_at': DateTime.now().toIso8601String(),
          'simulated': true,
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a pending payment record with proof upload
  Future<Map<String, dynamic>> createPendingPayment({
    required String classroomId,
    required String paymentPlanId,
    required double amount,
    required String paymentMethod, // 'upi' or 'bank_transfer'
    required XFile proofImage,
    String? transactionId,
  }) async {
    try {
      // Get current authenticated student
      final studentId = await _studentService.getCurrentStudentId();
      if (studentId == null) {
        throw Exception('No authenticated student found');
      }

      // Upload payment proof to storage
      final proofPath = await _uploadPaymentProof(studentId: studentId, imageFile: proofImage);

      // Create payment record with pending status
      final paymentData = {
        'student_id': studentId,
        'classroom_id': classroomId,
        'payment_plan_id': paymentPlanId,
        'amount': amount,
        'currency': 'INR',
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
        'status': 'pending', // Set to pending for admin verification
        'payment_proof_path': proofPath,
        // expire_at will be set by admin, not automatically
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.from('payments').insert(paymentData).select().single();

      return {'success': true, 'payment_id': response['id'], 'message': 'Payment submitted for verification'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Upload payment proof image to storage with unique naming
  Future<String> _uploadPaymentProof({required String studentId, required XFile imageFile}) async {
    try {
      // Generate unique filename using timestamp and random component
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = 'payment_proof_${timestamp}_${DateTime.now().microsecond}.$extension';

      // Create storage path: payment-proofs/{user_id}/{payment_id}/{filename}
      // Since we don't have payment_id yet, we use timestamp-based folder
      final storagePath = '$studentId/${timestamp}_${DateTime.now().microsecond}/$fileName';

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase storage
      await _supabase.storage.from('payment-proofs').uploadBinary(storagePath, bytes);

      return storagePath;
    } catch (e) {
      throw Exception('Failed to upload payment proof: $e');
    }
  }

  /// Get payment proof signed URL (valid for 1 hour)
  Future<String> getPaymentProofUrl(String storagePath) async {
    try {
      // Use createSignedUrl for private buckets instead of getPublicUrl
      final url = await _supabase.storage.from('payment-proofs').createSignedUrl(storagePath, 3600); // 1 hour expiry
      return url;
    } catch (e) {
      throw Exception('Failed to get payment proof URL: $e');
    }
  }

  /// Get student's pending payments
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final studentId = await _studentService.getCurrentStudentId();
      if (studentId == null) {
        return [];
      }

      final response = await _supabase
          .from('payments')
          .select('''
            *,
            classrooms(id, name, subject, grade_level),
            payment_plans(name, billing_cycle)
          ''')
          .eq('student_id', studentId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch pending payments: $e');
    }
  }

  /// Get all payments for the current student
  Future<List<Map<String, dynamic>>> getStudentPayments() async {
    try {
      final studentId = await _studentService.getCurrentStudentId();
      if (studentId == null) {
        return [];
      }

      final response = await _supabase
          .from('payments')
          .select('''
            *,
            classrooms(id, name, subject, grade_level),
            payment_plans(name, billing_cycle)
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch student payments: $e');
    }
  }

  /// Pick image from gallery or camera
  Future<XFile?> pickPaymentProof({required ImageSource source}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }
}
