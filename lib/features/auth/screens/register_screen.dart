import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_validator/form_validator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? userType;

  const RegisterScreen({Key? key, this.userType}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State for student-specific fields
  String? _selectedGrade;
  String? _selectedBoard;

  // Options for dropdowns
  final List<String> _grades = List.generate(12, (index) => 'Grade ${index + 1}');
  final List<String> _boards = ['CBSE', 'ICSE', 'State Board', 'IB', 'IGCSE'];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _userType = 'student'; // 'student' or 'parent'

  // Get auth service
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();

    // Set the user type from the route parameter if provided
    if (widget.userType != null) {
      _userType = widget.userType!;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Navigate back to user type selection
  void _navigateBackToUserTypeSelection() {
    if (mounted) {
      context.go('/select-user-type');
    }
  }

  // Show error message in a snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  // Handle authentication errors
  void _handleAuthError(dynamic error) {
    String errorMessage = 'An error occurred during registration';

    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          errorMessage = 'Invalid email or password';
          break;
        case '422':
          errorMessage = 'Invalid email format';
          break;
        case '429':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = error.message;
      }
    } else if (error is Exception) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
    }

    _showErrorSnackBar(errorMessage);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    if (!_acceptTerms) {
      _showErrorSnackBar('Please accept the terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      // Create user metadata for Supabase Auth
      // Using separate first_name and last_name as expected by our trigger function
      final Map<String, dynamic> userMetadata = {
        'first_name': firstName,
        'last_name': lastName,
        'user_type': _userType,
        'full_name': '$firstName $lastName',
      };

      // Add student-specific data if user is a student
      if (_userType == 'student') {
        final gradeNumber = _selectedGrade != null ? int.tryParse(_selectedGrade!.replaceAll('Grade ', '')) : null;
        userMetadata['grade_level'] = gradeNumber;
        userMetadata['board'] = _selectedBoard;
      }

      // Register user with Supabase
      final response = await _authService.signUp(email: email, password: password, userMetadata: userMetadata);

      if (response.user == null) {
        throw Exception('Failed to create user account');
      }

      // Navigate to email verification on success
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please verify your email.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to email verification
        if (mounted) {
          final email = _emailController.text.trim();
          final encodedEmail = Uri.encodeComponent(email);
          final userType = _userType;
          context.go('/verify-email?email=$encodedEmail&userType=$userType');
        }
      }
    } catch (e) {
      _handleAuthError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _navigateBackToUserTypeSelection),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and welcome text
                Column(
                  children: [
                    Icon(Icons.school_outlined, size: 60, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Create an account', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Join our learning community',
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // First Name and Last Name fields
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: ValidationBuilder()
                            .minLength(2, 'First name must be at least 2 characters')
                            .required('First name is required')
                            .build(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: ValidationBuilder()
                            .minLength(2, 'Last name must be at least 2 characters')
                            .required('Last name is required')
                            .build(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: ValidationBuilder()
                      .email('Please enter a valid email')
                      .required('Email is required')
                      .build(),
                ),
                const SizedBox(height: 16),

                // User type selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('I am a', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'student', label: Text('Student'), icon: Icon(Icons.school_outlined)),
                        ButtonSegment(
                          value: 'parent',
                          label: Text('Parent'),
                          icon: Icon(Icons.family_restroom_outlined),
                        ),
                      ],
                      selected: {_userType},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          _userType = selection.first;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.primary,
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Note: Teacher accounts are created by administrators.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                // Show grade and board selection only for students
                if (_userType == 'student') ...[
                  const SizedBox(height: 16),
                  // Grade Level Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(labelText: 'Grade Level', prefixIcon: Icon(Icons.grade_outlined)),
                    items: _grades.map((String grade) {
                      return DropdownMenuItem<String>(value: grade, child: Text(grade));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGrade = newValue;
                      });
                    },
                    validator: (value) {
                      if (_userType == 'student' && (value == null || value.isEmpty)) {
                        return 'Please select your grade';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Board Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedBoard,
                    decoration: const InputDecoration(labelText: 'Board', prefixIcon: Icon(Icons.book_outlined)),
                    items: _boards.map((String board) {
                      return DropdownMenuItem<String>(value: board, child: Text(board));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBoard = newValue;
                      });
                    },
                    validator: (value) {
                      if (_userType == 'student' && (value == null || value.isEmpty)) {
                        return 'Please select your board';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: ValidationBuilder()
                      .minLength(6, 'Password must be at least 6 characters')
                      .required('Password is required')
                      .build(),
                ),
                const SizedBox(height: 16),

                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Terms and conditions
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text('I agree to the Terms of Service and Privacy Policy', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Register button
                FilledButton(
                  onPressed: _isLoading ? null : _register,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 16),

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: _isLoading ? null : () => context.go('/login'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
