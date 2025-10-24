import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/core/theme/app_colors.dart';
import 'package:learned_flutter/features/student/providers/student_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  String? _selectedGrade;
  String? _selectedBoard;
  bool _isLoading = false;
  bool _hasChanges = false;

  File? _selectedImage;
  String? _currentImageUrl;

  final List<String> _grades = List.generate(12, (index) => 'Grade ${index + 1}');
  final List<String> _boards = ['CBSE', 'ICSE', 'State Board', 'IB', 'IGCSE'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic> studentProfile) {
    print('DEBUG: _populateFields called');
    print('DEBUG: studentProfile keys: ${studentProfile.keys}');
    print('DEBUG: studentProfile data: $studentProfile');

    final userInfo = studentProfile['users'] as Map<String, dynamic>;
    print('DEBUG: userInfo keys: ${userInfo.keys}');
    print('DEBUG: userInfo data: $userInfo');

    _firstNameController.text = userInfo['first_name'] ?? '';
    _lastNameController.text = userInfo['last_name'] ?? '';
    _phoneController.text = userInfo['phone'] ?? ''; // Read phone from users table
    _schoolController.text = studentProfile['school_name'] ?? '';
    _currentImageUrl = userInfo['profile_image_url'];

    print('DEBUG: First Name: ${_firstNameController.text}');
    print('DEBUG: Last Name: ${_lastNameController.text}');
    print('DEBUG: Phone: ${_phoneController.text}');
    print('DEBUG: School: ${_schoolController.text}');

    final gradeLevel = studentProfile['grade_level'];
    if (gradeLevel != null) {
      _selectedGrade = 'Grade $gradeLevel';
    }
    print('DEBUG: Grade Level: $_selectedGrade');

    _selectedBoard = studentProfile['board'];
    print('DEBUG: Board: $_selectedBoard');
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return _currentImageUrl;

    try {
      print('DEBUG: Uploading profile image...');
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Get the student ID from the database
      final studentData = await supabase.from('students').select('id').eq('user_id', currentUser.id).single();

      final studentId = studentData['id'];
      print('DEBUG: Student ID: $studentId');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'students/$studentId/profile_$timestamp.jpg';

      print('DEBUG: User ID: ${currentUser.id}');
      print('DEBUG: File name: $fileName');

      final bytes = await _selectedImage!.readAsBytes();
      print('DEBUG: Image size: ${bytes.length} bytes');

      // Delete old file if exists
      if (_currentImageUrl != null && _currentImageUrl!.contains('profile-images')) {
        try {
          final oldFileName = _currentImageUrl!.split('/profile-images/').last;
          print('DEBUG: Attempting to delete old file: $oldFileName');
          await supabase.storage.from('profile-images').remove([oldFileName]);
          print('DEBUG: Old file deleted');
        } catch (e) {
          print('DEBUG: Could not delete old file (may not exist): $e');
        }
      }

      print('DEBUG: Uploading to storage bucket: profile-images');
      await supabase.storage
          .from('profile-images')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

      print('DEBUG: Upload successful');

      // Generate a signed URL (valid for 1 year)
      final signedUrl = await supabase.storage.from('profile-images').createSignedUrl(fileName, 31536000);

      print('DEBUG: Signed URL: $signedUrl');
      return signedUrl;
    } catch (e, stackTrace) {
      print('DEBUG: Image upload error: $e');
      print('DEBUG: Stack trace: $stackTrace');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<void> _saveProfile() async {
    print('DEBUG: _saveProfile called');
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        print('DEBUG: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      print('DEBUG: Current user ID: ${currentUser.id}');

      // Upload image if selected
      String? imageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        print('DEBUG: Uploading new profile image...');
        imageUrl = await _uploadProfileImage();
        print('DEBUG: Image uploaded: $imageUrl');
      }

      // Update user information (including phone and profile image)
      print('DEBUG: Updating users table...');
      print('DEBUG: First Name: ${_firstNameController.text.trim()}');
      print('DEBUG: Last Name: ${_lastNameController.text.trim()}');
      print('DEBUG: Phone: ${_phoneController.text.trim()}');

      await supabase
          .from('users')
          .update({
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            'profile_image_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id);

      print('DEBUG: Users table updated successfully');

      // Update student-specific information
      final gradeNumber = _selectedGrade != null ? int.tryParse(_selectedGrade!.replaceAll('Grade ', '')) : null;

      print('DEBUG: Updating students table...');
      print('DEBUG: School: ${_schoolController.text.trim()}');
      print('DEBUG: Grade Number: $gradeNumber');
      print('DEBUG: Board: $_selectedBoard');

      await supabase
          .from('students')
          .update({
            'school_name': _schoolController.text.trim().isEmpty ? null : _schoolController.text.trim(),
            'grade_level': gradeNumber,
            'board': _selectedBoard,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUser.id);

      print('DEBUG: Students table updated successfully');

      // Invalidate the profile provider to refresh data
      ref.invalidate(currentStudentProfileProvider);
      print('DEBUG: Profile provider invalidated');

      if (mounted) {
        print('DEBUG: Showing success message');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            print('DEBUG: Navigating back');
            context.pop();
          }
        });
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error updating profile: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: EditProfileScreen build called');
    final studentProfileAsync = ref.watch(currentStudentProfileProvider);
    print('DEBUG: studentProfileAsync state: ${studentProfileAsync.runtimeType}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: studentProfileAsync.when(
        loading: () {
          print('DEBUG: Loading student profile...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('DEBUG: Error loading profile: $error');
          print('DEBUG: Stack trace: $stack');
          return Center(
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
          );
        },
        data: (studentProfile) {
          print('DEBUG: Student profile data received');
          print('DEBUG: studentProfile is null: ${studentProfile == null}');
          if (studentProfile != null) {
            print('DEBUG: studentProfile keys: ${studentProfile.keys}');
          }

          if (studentProfile == null) {
            print('DEBUG: Student profile is null');
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
          if (!_hasChanges && _firstNameController.text.isEmpty) {
            print('DEBUG: Scheduling field population');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _populateFields(studentProfile);
            });
          } else {
            print(
              'DEBUG: Skipping field population - hasChanges: $_hasChanges, firstName isEmpty: ${_firstNameController.text.isEmpty}',
            );
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
                        child: _selectedImage != null
                            ? ClipOval(child: Image.file(_selectedImage!, fit: BoxFit.cover, width: 120, height: 120))
                            : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  _currentImageUrl!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, size: 60, color: AppColors.primary);
                                  },
                                ),
                              )
                            : const Icon(Icons.person, size: 60, color: AppColors.primary),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
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
                    onChanged: (value) => setState(() {
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
                    onChanged: (value) => setState(() {
                      _selectedBoard = value;
                      _hasChanges = true;
                    }),
                    icon: Icons.account_balance_outlined,
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
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        // Optional field, no validation required
        return null;
      },
    );
  }
}
