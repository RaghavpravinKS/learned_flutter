import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../models/learning_material_model.dart';
import '../services/teacher_service.dart';
import 'upload_material_screen.dart';

class MaterialsManagementScreen extends StatefulWidget {
  const MaterialsManagementScreen({super.key});

  @override
  State<MaterialsManagementScreen> createState() => _MaterialsManagementScreenState();
}

class _MaterialsManagementScreenState extends State<MaterialsManagementScreen> {
  final TeacherService _teacherService = TeacherService();
  List<LearningMaterialModel> _materials = [];
  List<Map<String, dynamic>> _classrooms = [];
  bool _isLoading = true;
  String? _error;

  String _selectedFilter = 'all'; // 'all', 'note', 'video', 'document', 'presentation'
  String? _selectedClassroom;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teacherId = await _teacherService.getCurrentTeacherId();
      if (teacherId == null) {
        throw Exception('Teacher not found');
      }

      // Load classrooms and materials in parallel
      await Future.wait([_loadClassrooms(teacherId), _loadMaterials(teacherId)]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClassrooms(String teacherId) async {
    try {
      final classrooms = await _teacherService.getTeacherClassrooms(teacherId);
      setState(() {
        _classrooms = classrooms;
      });
    } catch (e) {
      print('Error loading classrooms: $e');
      rethrow;
    }
  }

  Future<void> _loadMaterials(String teacherId) async {
    try {
      final response = await Supabase.instance.client
          .from('learning_materials')
          .select('''
            *,
            classrooms!inner (
              name,
              subject,
              grade_level
            )
          ''')
          .eq('teacher_id', teacherId)
          .order('upload_date', ascending: false);

      final materials = (response as List).map((item) {
        return LearningMaterialModel.fromMap(item);
      }).toList();

      setState(() {
        _materials = materials;
      });
    } catch (e) {
      print('Error loading materials: $e');
      rethrow;
    }
  }

  List<LearningMaterialModel> get _filteredMaterials {
    var filtered = _materials;

    // Filter by type
    if (_selectedFilter != 'all') {
      filtered = filtered.where((m) => m.materialType == _selectedFilter).toList();
    }

    // Filter by classroom
    if (_selectedClassroom != null) {
      filtered = filtered.where((m) => m.classroomId == _selectedClassroom).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToUpload,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading materials',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('Try Again')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Filters
          _buildFilters(),

          // Materials list
          Expanded(
            child: _filteredMaterials.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMaterials.length,
                    itemBuilder: (context, index) => _buildMaterialCard(_filteredMaterials[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filters
          Row(
            children: [
              Text('Type:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', Icons.grid_view),
                      _buildFilterChip('Notes', 'note', Icons.note),
                      _buildFilterChip('Videos', 'video', Icons.videocam),
                      _buildFilterChip('Documents', 'document', Icons.description),
                      _buildFilterChip('Presentations', 'presentation', Icons.slideshow),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Classroom filter
          Row(
            children: [
              Text('Classroom:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedClassroom,
                      isExpanded: true,
                      hint: const Text('All Classrooms'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Classrooms')),
                        ..._classrooms.map((classroom) {
                          return DropdownMenuItem<String?>(value: classroom['id'], child: Text(classroom['name']));
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClassroom = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'all' && _selectedClassroom == null ? 'No materials uploaded yet' : 'No materials found',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text('Tap the upload button to add materials', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(LearningMaterialModel material) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewMaterial(material),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTypeColor(material.materialType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTypeIcon(material.materialType),
                      color: _getTypeColor(material.materialType),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          material.typeDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTypeColor(material.materialType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // More options
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editMaterial(material);
                      } else if (value == 'delete') {
                        _deleteMaterial(material);
                      } else if (value == 'view') {
                        _viewMaterial(material);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('View')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),

              if (material.description != null && material.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  material.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Metadata
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.folder, _getClassroomName(material.classroomId), Colors.blue),
                  if (material.fileSize != null)
                    _buildInfoChip(Icons.data_usage, material.fileSizeDisplay, Colors.orange),
                  _buildInfoChip(Icons.access_time, _formatDate(material.uploadDate), Colors.grey),
                  if (material.isPublic) _buildInfoChip(Icons.public, 'Public', Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'note':
        return Icons.note;
      case 'video':
        return Icons.videocam;
      case 'document':
        return Icons.description;
      case 'presentation':
        return Icons.slideshow;
      case 'recording':
        return Icons.mic;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'note':
        return Colors.amber;
      case 'video':
        return Colors.red;
      case 'document':
        return Colors.blue;
      case 'presentation':
        return Colors.orange;
      case 'recording':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getClassroomName(String classroomId) {
    final classroom = _classrooms.firstWhere((c) => c['id'] == classroomId, orElse: () => {'name': 'Unknown'});
    return classroom['name'] ?? 'Unknown';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToUpload() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadMaterialScreen()));

    if (result == true) {
      _loadData();
    }
  }

  void _viewMaterial(LearningMaterialModel material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(material.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${material.typeDisplay}'),
            const SizedBox(height: 8),
            Text('Classroom: ${_getClassroomName(material.classroomId)}'),
            if (material.description != null) ...[
              const SizedBox(height: 8),
              Text('Description: ${material.description}'),
            ],
            if (material.fileSize != null) ...[const SizedBox(height: 8), Text('Size: ${material.fileSizeDisplay}')],
            const SizedBox(height: 8),
            Text('Uploaded: ${_formatDate(material.uploadDate)}'),
          ],
        ),
        actions: [
          if (material.fileUrl != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Open file URL
              },
              child: const Text('Open File'),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _editMaterial(LearningMaterialModel material) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadMaterialScreen(material: material)),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _deleteMaterial(LearningMaterialModel material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await Supabase.instance.client.from('learning_materials').delete().eq('id', material.id!);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Material deleted successfully'), backgroundColor: Colors.green));
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting material: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
