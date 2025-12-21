import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../../core/theme/app_colors.dart';
import '../models/learning_material_model.dart';
import '../services/teacher_service.dart';

class UploadMaterialScreen extends StatefulWidget {
  final LearningMaterialModel? material; // For editing existing material

  const UploadMaterialScreen({super.key, this.material});

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final TeacherService _teacherService = TeacherService();

  // Form fields
  String? _selectedClassroom;
  String _selectedType = 'document';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;

  // File upload
  File? _selectedFile;
  String? _fileName;
  int? _fileSize;
  String? _mimeType;
  bool _isUploading = false;

  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoadingClassrooms = true;

  final List<Map<String, dynamic>> _materialTypes = [
    {'value': 'note', 'label': 'Note', 'icon': Icons.note},
    {'value': 'document', 'label': 'Document', 'icon': Icons.description},
    {'value': 'video', 'label': 'Video', 'icon': Icons.videocam},
    {'value': 'presentation', 'label': 'Presentation', 'icon': Icons.slideshow},
  ];

  @override
  void initState() {
    super.initState();
    _loadClassrooms();

    // If editing, populate fields
    if (widget.material != null) {
      _titleController.text = widget.material!.title;
      _descriptionController.text = widget.material!.description ?? '';
      _selectedClassroom = widget.material!.classroomId;
      _selectedType = widget.material!.materialType;
      _isPublic = widget.material!.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClassrooms() async {
    try {
      final teacherId = await _teacherService.getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher not found');
      }

      final classrooms = await _teacherService.getTeacherClassrooms(teacherId);
      setState(() {
        _classrooms = classrooms;
        _isLoadingClassrooms = false;

        // Auto-select if only one classroom
        if (_classrooms.length == 1 && _selectedClassroom == null) {
          _selectedClassroom = _classrooms[0]['id'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingClassrooms = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading classrooms: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4', 'mov', 'avi', 'jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
          _fileSize = result.files.single.size;
          _mimeType = _getMimeType(result.files.single.extension ?? '');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video/mp4';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassroom == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a classroom'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final teacherId = await _teacherService.getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher not found');
      }

      String? fileUrl;

      // Upload file to Supabase Storage if a new file is selected
      if (_selectedFile != null) {
        fileUrl = await _uploadFileToStorage();
      } else if (widget.material != null) {
        // Keep existing file URL when editing
        fileUrl = widget.material!.fileUrl;
      }

      // Create or update material in database
      final materialData = {
        'teacher_id': teacherId,
        'classroom_id': _selectedClassroom!,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'material_type': _selectedType,
        'file_url': fileUrl,
        'file_size': _fileSize ?? widget.material?.fileSize,
        'mime_type': _mimeType ?? widget.material?.mimeType,
        'is_public': _isPublic,
        'upload_date': widget.material?.uploadDate.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.material != null) {
        // Update existing material
        await Supabase.instance.client.from('learning_materials').update(materialData).eq('id', widget.material!.id!);
      } else {
        // Insert new material
        materialData['created_at'] = DateTime.now().toIso8601String();
        await Supabase.instance.client.from('learning_materials').insert(materialData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.material != null ? 'Material updated successfully!' : 'Material uploaded successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  Future<String> _uploadFileToStorage() async {
    if (_selectedFile == null || _fileName == null) {
      throw Exception('No file selected');
    }

    try {
      // Create a unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'materials/${timestamp}_$_fileName';

      // Upload to Supabase Storage
      final bytes = await _selectedFile!.readAsBytes();
      await Supabase.instance.client.storage
          .from('learning-materials')
          .uploadBinary(uniqueFileName, bytes, fileOptions: FileOptions(contentType: _mimeType));

      // Get public URL
      final publicUrl = Supabase.instance.client.storage.from('learning-materials').getPublicUrl(uniqueFileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.material != null ? 'Edit Material' : 'Upload Material',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingClassrooms
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Classroom selection
                    _buildSectionTitle('Classroom'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedClassroom,
                      decoration: InputDecoration(
                        hintText: 'Select classroom',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _classrooms.map((classroom) {
                        return DropdownMenuItem<String>(
                          value: classroom['id'] as String,
                          child: Text(
                            '${classroom['name']} - ${classroom['subject']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassroom = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a classroom';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Material Type
                    _buildSectionTitle('Material Type'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _materialTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.white : Colors.grey[700],
                              ),
                              const SizedBox(width: 6),
                              Text(type['label'] as String),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = type['value'] as String;
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    _buildSectionTitle('Title'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter material title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Description
                    _buildSectionTitle('Description (Optional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Enter material description',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),

                    // File upload
                    _buildSectionTitle('File'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedFile != null || widget.material?.fileUrl != null
                                ? AppColors.primary
                                : Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile != null || widget.material?.fileUrl != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload,
                              size: 48,
                              color: _selectedFile != null || widget.material?.fileUrl != null
                                  ? AppColors.primary
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _fileName ??
                                  (widget.material?.fileUrl != null ? 'File already uploaded' : 'Tap to select file'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                            if (_fileSize != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatFileSize(_fileSize!),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Supported: PDF, DOC, PPT, MP4, Images',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Public toggle
                    SwitchListTile(
                      title: const Text('Make public'),
                      subtitle: const Text('Allow students from other classrooms to view'),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _submit,
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
                            : Text(
                                widget.material != null ? 'Update Material' : 'Upload Material',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
