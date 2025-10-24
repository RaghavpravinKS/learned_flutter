import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/learning_materials_provider.dart';
import '../../teacher/models/learning_material_model.dart';

class ClassroomMaterialsScreen extends ConsumerWidget {
  final String classroomId;
  final String classroomName;

  const ClassroomMaterialsScreen({super.key, required this.classroomId, required this.classroomName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(classroomLearningMaterialsProvider(classroomId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$classroomName - Materials'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: materialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Failed to load materials', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(classroomLearningMaterialsProvider(classroomId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (materials) {
          if (materials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No learning materials yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Materials will appear here once your teacher uploads them',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return _buildMaterialCard(context, material);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, LearningMaterialModel material) {
    final daysDiff = DateTime.now().difference(material.uploadDate).inDays;
    final timeAgo = daysDiff == 0
        ? 'Today'
        : daysDiff == 1
        ? 'Yesterday'
        : '$daysDiff days ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewMaterial(context, material),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getMaterialIcon(material), size: 32, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      material.typeDisplay,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '$timeAgo • ${material.fileSizeDisplay}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppColors.primary),
                onSelected: (value) async {
                  if (value == 'view') {
                    await _viewMaterial(context, material);
                  } else if (value == 'download') {
                    await _downloadMaterial(context, material);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(children: [Icon(Icons.visibility, size: 20), SizedBox(width: 12), Text('View')]),
                  ),
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(children: [Icon(Icons.download, size: 20), SizedBox(width: 12), Text('Download')]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMaterialIcon(LearningMaterialModel material) {
    switch (material.materialType.toLowerCase()) {
      case 'document':
        if (material.isPDF) {
          return Icons.picture_as_pdf;
        }
        return Icons.description;
      case 'video':
        return Icons.videocam;
      case 'presentation':
        return Icons.slideshow;
      case 'recording':
        return Icons.mic;
      case 'note':
        return Icons.note;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _viewMaterial(BuildContext context, LearningMaterialModel material) async {
    if (material.fileUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File URL not available')));
      }
      return;
    }

    try {
      print('=== Attempting to view material: ${material.title} ===');
      String? filePath;
      final storedUrl = material.fileUrl!;

      if (storedUrl.contains('learning-materials/')) {
        filePath = storedUrl.split('learning-materials/').last;
      }

      Uri uri;

      if (filePath != null) {
        try {
          final supabase = Supabase.instance.client;
          final signedUrl = await supabase.storage.from('learning-materials').createSignedUrl(filePath, 3600);
          uri = Uri.parse(signedUrl);
        } catch (e) {
          uri = Uri.parse(storedUrl);
        }
      } else {
        uri = Uri.parse(storedUrl);
      }

      final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);

      if (!launched && context.mounted) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  Future<void> _downloadMaterial(BuildContext context, LearningMaterialModel material) async {
    if (material.fileUrl == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File URL not available')));
      }
      return;
    }

    try {
      String? filePath;
      final storedUrl = material.fileUrl!;

      if (storedUrl.contains('learning-materials/')) {
        filePath = storedUrl.split('learning-materials/').last;
      }

      Uri uri;

      if (filePath != null) {
        try {
          final supabase = Supabase.instance.client;
          final signedUrl = await supabase.storage.from('learning-materials').createSignedUrl(filePath, 3600);
          uri = Uri.parse(signedUrl);
        } catch (e) {
          uri = Uri.parse(storedUrl);
        }
      } else {
        uri = Uri.parse(storedUrl);
      }

      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading ${material.title}...')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading file: $e')));
      }
    }
  }
}
