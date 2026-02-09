import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyResetCodeScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyResetCodeScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends ConsumerState<VerifyResetCodeScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  bool _hasResent = false;
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.resetPasswordForEmail(widget.email);

      if (mounted) {
        setState(() => _hasResent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset code resent! Please check your email.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to resend: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.verifyOTP(
        email: widget.email,
        token: _otpController.text.trim(),
        type: OtpType.recovery,
      );

      if (mounted) {
        if (response.session != null) {
          // Success - navigate to reset password screen
          context.go('/reset-password');
        } else {
          throw Exception('Verification failed');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or expired code. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Reset Code')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Header
                Icon(Icons.lock_reset, size: 80, color: Colors.red.shade600),
                const SizedBox(height: 24),
                Text(
                  'Reset Your Password',
                  style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'ve sent a reset code to:',
                  style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter the 6-digit code from your email to continue',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // OTP Input
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Enter 6-digit code',
                    hintText: '000000',
                    counterText: '',
                    prefixIcon: const Icon(Icons.pin),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade600, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the reset code';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Verify Code', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),

                const SizedBox(height: 16),

                // Resend Code Button
                TextButton(
                  onPressed: _isResending || _hasResent ? null : _resendCode,
                  child: _isResending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          _hasResent ? 'Code Resent! Check your email' : 'Didn\'t receive code? Resend',
                          style: GoogleFonts.poppins(
                            color: _hasResent ? Colors.green.shade700 : Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                ),

                const SizedBox(height: 8),

                // Help Text
                Text(
                  'Check your spam folder if you don\'t see the email',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Back to Login
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
