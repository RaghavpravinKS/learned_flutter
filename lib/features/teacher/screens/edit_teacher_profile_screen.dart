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

    final userData = widget.teacherData['users'];
    _fullNameController = TextEditingController(text: userData['full_name'] ?? '');
    _phoneController = TextEditingController(text: userData['phone_number'] ?? '');
    _bioController = TextEditingController(text: widget.teacherData['bio'] ?? '');
    _qualificationsController = TextEditingController(text: widget.teacherData['qualifications'] ?? '');
    _specializationController = TextEditingController(text: widget.teacherData['specialization'] ?? '');
    _experienceController = TextEditingController(text: widget.teacherData['years_of_experience']?.toString() ?? '');
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
      final teacherId = widget.teacherData['id'];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'teachers/$teacherId/profile_$timestamp.jpg';

      final bytes = await _selectedImage!.readAsBytes();
      await Supabase.instance.client.storage
          .from('profile-images')
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

      final publicUrl = Supabase.instance.client.storage.from('profile-images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Image upload error: $e');
      throw Exception('Failed to upload profile image');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload image if selected
      String? imageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadProfileImage();
      }

      final teacherId = widget.teacherData['id'];
      final userId = widget.teacherData['users']['id'];

      // Update users table
      await Supabase.instance.client
          .from('users')
          .update({
            'full_name': _fullNameController.text.trim(),
            'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            'profile_image_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Update teachers table
      await Supabase.instance.client
          .from('teachers')
          .update({
            'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
            'qualifications': _qualificationsController.text.trim().isEmpty
                ? null
                : _qualificationsController.text.trim(),
            'specialization': _specializationController.text.trim().isEmpty
                ? null
                : _specializationController.text.trim(),
            'years_of_experience': _experienceController.text.trim().isEmpty
                ? null
                : int.tryParse(_experienceController.text.trim()),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', teacherId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
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
