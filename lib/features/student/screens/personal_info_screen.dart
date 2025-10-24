import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/providers/student_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  final String _country = 'India'; // Fixed to India only
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic> studentProfile) {
    final userInfo = studentProfile['users'] as Map<String, dynamic>;

    _addressController.text = userInfo['address'] ?? '';
    _cityController.text = userInfo['city'] ?? '';
    _stateController.text = userInfo['state'] ?? '';
    _postalCodeController.text = userInfo['postal_code'] ?? '';

    // Parse date of birth
    if (userInfo['date_of_birth'] != null) {
      try {
        _selectedDateOfBirth = DateTime.parse(userInfo['date_of_birth']);
      } catch (e) {
        print('Error parsing date of birth: $e');
      }
    }
  }

  // Function to get state from Indian PIN code
  void _getStateFromPostalCode(String postalCode) {
    if (postalCode.isEmpty) {
      setState(() {
        _stateController.text = '';
      });
      return;
    }

    // Basic validation: Check if the input is exactly 6 characters long
    if (postalCode.length != 6) {
      setState(() {
        _stateController.text = 'Invalid PIN Code Length';
      });
      return;
    }

    // Extract the first two digits as an integer
    String firstTwoDigitsString = postalCode.substring(0, 2);
    int? pinPrefix = int.tryParse(firstTwoDigitsString);

    // Check if the prefix is a valid number
    if (pinPrefix == null) {
      setState(() {
        _stateController.text = 'Invalid PIN Code Format';
      });
      return;
    }

    // Use a switch statement on the first two digits
    String state;
    switch (pinPrefix) {
      // North Zone
      case 11:
        state = 'Delhi';
        break;
      case 12:
      case 13:
        state = 'Haryana';
        break;
      case 14:
      case 15:
      case 16:
        state = 'Punjab / Chandigarh';
        break;
      case 17:
        state = 'Himachal Pradesh';
        break;
      case 18:
      case 19:
        state = 'Jammu and Kashmir / Ladakh';
        break;

      // North Zone (cont.) - Uttar Pradesh / Uttarakhand
      case >= 20 && <= 28:
        state = 'Uttar Pradesh / Uttarakhand';
        break;

      // West Zone
      case >= 30 && <= 34:
        state = 'Rajasthan';
        break;
      case >= 36 && <= 39:
        state = 'Gujarat / Dadra and Nagar Haveli and Daman and Diu';
        break;

      // West Zone (cont.)
      case >= 40 && <= 44:
        state = 'Maharashtra / Goa';
        break;
      case >= 45 && <= 48:
        state = 'Madhya Pradesh';
        break;
      case 49:
        state = 'Chhattisgarh';
        break;

      // South Zone
      case 50:
      case 51:
      case 52:
      case 53:
        state = 'Telangana / Andhra Pradesh';
        break;
      case >= 56 && <= 59:
        state = 'Karnataka';
        break;

      // South Zone (cont.)
      case >= 60 && <= 64:
      case >= 65 && <= 66:
        state = 'Tamil Nadu / Puducherry';
        break;
      case >= 67 && <= 69:
        state = 'Kerala / Lakshadweep';
        break;

      // East Zone
      case >= 70 && <= 74:
        state = 'West Bengal / Andaman & Nicobar Islands / Sikkim';
        break;
      case >= 75 && <= 77:
        state = 'Odisha';
        break;
      case 78:
        state = 'Assam';
        break;
      case 79:
        state = 'North Eastern States (Arunachal Pradesh, Nagaland, etc.)';
        break;

      // East Zone (cont.)
      case >= 80 && <= 85:
        state = 'Bihar / Jharkhand';
        break;

      // Army Postal Service
      case >= 90 && <= 99:
        state = 'Army Postal Service (APS) / Field Post Office (FPO)';
        break;

      default:
        state = 'PIN Code Out of Known Range';
    }

    setState(() {
      _stateController.text = state;
      _hasChanges = true;
    });
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 15)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _savePersonalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Update user information with personal details
      await supabase
          .from('users')
          .update({
            'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
            'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
            'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
            'country': _country, // Fixed to 'India'
            'postal_code': _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id);

      // Invalidate the profile provider to refresh data
      ref.invalidate(currentStudentProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal information updated successfully!'), backgroundColor: Colors.green),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating personal information: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProfileAsync = ref.watch(currentStudentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: studentProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentStudentProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (studentProfile) {
          if (studentProfile == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No student profile found', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Please contact support if this issue persists', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Populate fields with data if not already done
          if (!_hasChanges && _addressController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _populateFields(studentProfile);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() => _hasChanges = true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Update your personal information for identification and contact purposes',
                            style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date of Birth
                  const Text('Date of Birth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDateOfBirth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined),
                          const SizedBox(width: 16),
                          Text(
                            _selectedDateOfBirth != null
                                ? DateFormat('MMMM dd, yyyy').format(_selectedDateOfBirth!)
                                : 'Select date of birth',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedDateOfBirth != null ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  _buildFormField(
                    label: 'Address',
                    controller: _addressController,
                    icon: Icons.home_outlined,
                    hint: 'Street address, apartment, etc.',
                    maxLines: 2,
                    required: false,
                  ),
                  const SizedBox(height: 16),

                  // City
                  _buildFormField(
                    label: 'City',
                    controller: _cityController,
                    icon: Icons.location_city_outlined,
                    required: false,
                  ),
                  const SizedBox(height: 16),

                  // Country - Fixed to India (Read-only)
                  TextFormField(
                    initialValue: _country,
                    decoration: InputDecoration(
                      labelText: 'Country',
                      prefixIcon: const Icon(Icons.public_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    enabled: false, // Read-only field
                  ),
                  const SizedBox(height: 16),

                  // Postal Code (PIN Code for India)
                  TextFormField(
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'PIN Code',
                      hintText: 'Enter 6-digit PIN code',
                      prefixIcon: const Icon(Icons.local_post_office_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      helperText: 'State will be auto-filled based on PIN code',
                    ),
                    onChanged: (value) {
                      _getStateFromPostalCode(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // State (Auto-filled, Read-only)
                  TextFormField(
                    controller: _stateController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'State',
                      hintText: 'Auto-filled from PIN code',
                      prefixIcon: const Icon(Icons.map_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info about state auto-fill
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'State/Province is automatically determined from your postal code',
                            style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePersonalInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = true,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: required
          ? (validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your ${label.toLowerCase()}';
                  }
                  return null;
                })
          : validator,
    );
  }
}
