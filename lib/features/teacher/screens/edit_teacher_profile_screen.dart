import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/theme/app_colors.dart';

class EditTeacherProfileScreen extends StatefulWidget {
  final Map<String, dynamic> teacherData;

  const EditTeacherProfileScreen({super.key, required this.teacherData});

  @override
  State<EditTeacherProfileScreen> createState() => _EditTeacherProfileScreenState();
}

class _EditTeacherProfileScreenState extends State<EditTeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _qualificationsController;
  late final TextEditingController _specializationController;
  late final TextEditingController _experienceController;

  File? _selectedImage;
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    print('=== EDIT PROFILE INIT ===');
    print('Teacher Data: ${widget.teacherData}');

    final userData = widget.teacherData['users'];
    print('User Data: $userData');

    // Combine first_name and last_name for full_name field
    final firstName = userData['first_name'] ?? '';
    final lastName = userData['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    print('First Name: $firstName');
    print('Last Name: $lastName');
    print('Full Name: $fullName');

    _fullNameController = TextEditingController(text: fullName);
    _phoneController = TextEditingController(text: userData['phone'] ?? '');
    _bioController = TextEditingController(text: widget.teacherData['bio'] ?? '');
    _qualificationsController = TextEditingController(text: widget.teacherData['qualifications'] ?? '');

    // Handle specializations - could be an array, convert to string
    final specializations = widget.teacherData['specializations'];
    print('Specializations from DB: $specializations (type: ${specializations.runtimeType})');
    String specializationText = '';
    if (specializations != null) {
      if (specializations is List) {
        specializationText = specializations.join(', ');
      } else {
        specializationText = specializations.toString();
      }
    }
    _specializationController = TextEditingController(text: specializationText);

    _experienceController = TextEditingController(text: widget.teacherData['experience_years']?.toString() ?? '');

    print('Phone: ${userData['phone']}');
    print('Bio: ${widget.teacherData['bio']}');
    print('Qualifications: ${widget.teacherData['qualifications']}');
    print('Specialization Text: $specializationText');
    print('Experience Years: ${widget.teacherData['experience_years']}');
    print('Profile Image URL: ${userData['profile_image_url']}');
    print('=========================');
    _currentImageUrl = userData['profile_image_url'];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _qualificationsController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    super.dispose();
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
      print('=== UPLOADING PROFILE IMAGE ===');
      final teacherId = widget.teacherData['id'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'teachers/$teacherId/profile_$timestamp.jpg';

      print('Teacher ID: $teacherId');
      print('File name: $fileName');

      final bytes = await _selectedImage!.readAsBytes();
      print('Image size: ${bytes.length} bytes');

      // Delete old file if exists (to avoid conflicts)
      if (_currentImageUrl != null && _currentImageUrl!.contains('profile-images')) {
        try {
          final oldFileName = _currentImageUrl!.split('/profile-images/').last;
          print('Attempting to delete old file: $oldFileName');
          await Supabase.instance.client.storage.from('profile-images').remove([oldFileName]);
          print('Old file deleted');
        } catch (e) {
          print('Could not delete old file (may not exist): $e');
        }
      }

      print('Uploading to storage bucket: profile-images');
      final uploadResponse = await Supabase.instance.client.storage
          .from('profile-images')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

      print('Upload response: $uploadResponse');

      // Generate a signed URL (valid for 1 year) instead of public URL for better security
      final signedUrl = await Supabase.instance.client.storage
          .from('profile-images')
          .createSignedUrl(fileName, 31536000); // 1 year in seconds

      print('Signed URL: $signedUrl');
      print('=== IMAGE UPLOAD COMPLETE ===');

      return signedUrl;
    } catch (e, stackTrace) {
      print('=== IMAGE UPLOAD ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('==========================');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<void> _saveProfile() async {
    print('=== SAVE BUTTON PRESSED ===');
    print('Controller values at save time:');
    print('  Full Name: "${_fullNameController.text}"');
    print('  Phone: "${_phoneController.text}"');
    print('  Bio: "${_bioController.text}"');
    print('  Qualifications: "${_qualificationsController.text}"');
    print('  Specialization: "${_specializationController.text}"');
    print('  Experience: "${_experienceController.text}"');
    print('===========================');

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    print('=== SAVING PROFILE ===');
    setState(() => _isUploading = true);

    try {
      // Upload image if selected
      String? imageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        print('Uploading new profile image...');
        imageUrl = await _uploadProfileImage();
        print('Image uploaded: $imageUrl');
      }

      final teacherId = widget.teacherData['id'];
      final userId = widget.teacherData['users']['id'];

      print('Teacher ID: $teacherId');
      print('User ID: $userId');

      // Split full name into first and last name
      final nameParts = _fullNameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      print('Full Name Input: ${_fullNameController.text.trim()}');
      print('Split into - First: $firstName, Last: $lastName');
      print('Phone Input: ${_phoneController.text.trim()}');

      // Prepare users update data
      final usersUpdateData = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'profile_image_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Users Update Data: $usersUpdateData');

      // Update users table
      print('Updating users table...');
      final usersResponse = await Supabase.instance.client
          .from('users')
          .update(usersUpdateData)
          .eq('id', userId)
          .select();
      print('Users table updated successfully');
      print('Users update response: $usersResponse');

      // Parse specializations as array
      List<String>? specializationsList;
      if (_specializationController.text.trim().isNotEmpty) {
        specializationsList = _specializationController.text
            .trim()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      print('Bio Input: ${_bioController.text.trim()}');
      print('Qualifications Input: ${_qualificationsController.text.trim()}');
      print('Specializations Input: ${_specializationController.text.trim()}');
      print('Specializations List: $specializationsList');
      print('Experience Input: ${_experienceController.text.trim()}');

      // Prepare teachers update data
      final teachersUpdateData = {
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'qualifications': _qualificationsController.text.trim().isEmpty ? null : _qualificationsController.text.trim(),
        'specializations': specializationsList,
        'experience_years': _experienceController.text.trim().isEmpty
            ? null
            : int.tryParse(_experienceController.text.trim()),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Teachers Update Data: $teachersUpdateData');

      // Update teachers table
      print('Updating teachers table...');
      final teachersResponse = await Supabase.instance.client
          .from('teachers')
          .update(teachersUpdateData)
          .eq('id', teacherId)
          .select();
      print('Teachers table updated successfully');
      print('Teachers update response: $teachersResponse');

      print('=== PROFILE SAVE COMPLETE ===');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      print('=== ERROR SAVING PROFILE ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('============================');

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null) as ImageProvider?,
                      child: _selectedImage == null && _currentImageUrl == null
                          ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Full Name
              _buildSectionTitle('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullNameController,
                decoration: _inputDecoration('Enter your full name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Phone Number
              _buildSectionTitle('Phone Number (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Enter your phone number'),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Bio
              _buildSectionTitle('Bio (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                decoration: _inputDecoration('Tell us about yourself'),
                maxLines: 4,
                maxLength: 500,
              ),

              const SizedBox(height: 24),

              // Qualifications
              _buildSectionTitle('Qualifications (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qualificationsController,
                decoration: _inputDecoration('e.g., B.Ed, M.Sc Mathematics'),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Specialization
              _buildSectionTitle('Specialization (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _specializationController,
                decoration: _inputDecoration('e.g., Mathematics, Science'),
              ),

              const SizedBox(height: 24),

              // Years of Experience
              _buildSectionTitle('Years of Experience (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceController,
                decoration: _inputDecoration('Enter years of experience'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final experience = int.tryParse(value);
                    if (experience == null || experience < 0 || experience > 50) {
                      return 'Please enter a valid experience (0-50 years)';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Save Changes', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
