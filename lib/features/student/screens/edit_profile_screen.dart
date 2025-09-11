import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/debug/helpers/auth_debug_helper.dart';
import 'package:learned_flutter/features/student/providers/student_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolController = TextEditingController();
  final _learningGoalsController = TextEditingController();

  String? _selectedGrade;
  String? _selectedBoard;
  bool _isLoading = false;
  bool _hasChanges = false;

  final List<String> _grades = List.generate(12, (index) => 'Grade ${index + 1}');
  final List<String> _boards = ['CBSE', 'ICSE', 'State Board', 'IB', 'IGCSE'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    _learningGoalsController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic> studentProfile) {
    final userInfo = studentProfile['users'] as Map<String, dynamic>;
    
    _firstNameController.text = userInfo['first_name'] ?? '';
    _lastNameController.text = userInfo['last_name'] ?? '';
    _phoneController.text = studentProfile['phone'] ?? '';
    _schoolController.text = studentProfile['school_name'] ?? '';
    _learningGoalsController.text = studentProfile['learning_goals'] ?? '';
    
    final gradeLevel = studentProfile['grade_level'];
    if (gradeLevel != null) {
      _selectedGrade = 'Grade $gradeLevel';
    }
    
    _selectedBoard = studentProfile['board'];
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Update user information
      await supabase.from('users').update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      // Update student-specific information
      final gradeNumber = _selectedGrade != null 
          ? int.tryParse(_selectedGrade!.replaceAll('Grade ', ''))
          : null;

      await supabase.from('students').update({
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'school_name': _schoolController.text.trim().isEmpty ? null : _schoolController.text.trim(),
        'learning_goals': _learningGoalsController.text.trim().isEmpty ? null : _learningGoalsController.text.trim(),
        'grade_level': gradeNumber,
        'board': _selectedBoard,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', currentUser.id);

      // Invalidate the profile provider to refresh data
      ref.invalidate(currentStudentProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
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
    final studentProfileAsync = ref.watch(currentStudentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => AuthDebugHelper.showAuthDebugDialog(context),
            tooltip: 'Debug Authentication',
          ),
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : const Text('Save'),
          ),
        ],
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
                  Text('Please contact support if this issue persists', 
                       style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Populate fields with data if not already done
          if (!_hasChanges && _firstNameController.text.isEmpty) {
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                        ),
                        child: const Icon(Icons.person, size: 60, color: AppColors.primary),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form Fields
                  _buildFormField(
                    label: 'First Name',
                    controller: _firstNameController,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFormField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildFormField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    required: false,
                  ),
                  const SizedBox(height: 16),

                  _buildFormField(
                    label: 'School Name',
                    controller: _schoolController,
                    icon: Icons.school_outlined,
                    required: false,
                  ),
                  const SizedBox(height: 16),

                  // Grade Level Dropdown
                  _buildDropdownField(
                    label: 'Grade Level',
                    value: _selectedGrade,
                    items: _grades,
                    onChanged: (value) => setState(() => {
                      _selectedGrade = value;
                      _hasChanges = true;
                    }),
                    icon: Icons.grade_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Board Dropdown
                  _buildDropdownField(
                    label: 'Board',
                    value: _selectedBoard,
                    items: _boards,
                    onChanged: (value) => setState(() => {
                      _selectedBoard = value;
                      _hasChanges = true;
                    }),
                    icon: Icons.account_balance_outlined,
                  ),
                  const SizedBox(height: 16),

                  _buildFormField(
                    label: 'Learning Goals',
                    controller: _learningGoalsController,
                    icon: Icons.psychology_outlined,
                    maxLines: 3,
                    required: false,
                    hint: 'What would you like to achieve through learning?',
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
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
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself...',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                ),
              ),

              // Change Password Button
              TextButton(
                onPressed: () {
                  // Navigate to change password screen
                },
                child: const Text('Change Password'),
              ),
            ],
          ),
        ),
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
      validator: required ? (validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your ${label.toLowerCase()}';
        }
        return null;
      }) : validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        // Optional field, no validation required
        return null;
      },
    );
  }
}
