import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaterialViewerScreen extends ConsumerStatefulWidget {
  final String materialId;
  final Map<String, dynamic>? materialData;

  const MaterialViewerScreen({
    super.key,
    required this.materialId,
    this.materialData,
  });

  @override
  ConsumerState<MaterialViewerScreen> createState() => _MaterialViewerScreenState();
}

class _MaterialViewerScreenState extends ConsumerState<MaterialViewerScreen> {
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isDownloaded = false;
  
  @override
  void initState() {
    super.initState();
    // Simulate loading the material
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDownloaded = widget.materialData?['isDownloaded'] == true;
        });
      }
    });
  }
  
  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite 
              ? 'Added to favorites' 
              : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  void _toggleDownload() {
    setState(() {
      _isDownloaded = !_isDownloaded;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isDownloaded 
              ? 'Downloading...' 
              : 'Removed from downloads',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Simulate download completion
    if (_isDownloaded) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download completed'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      });
    }
  }
  
  void _shareMaterial() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing material...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final material = widget.materialData ?? {};
    final type = material['type'] ?? 'unknown';
    
    return Column(
      children: [
        // Header with actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
                onPressed: _toggleFavorite,
                tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
              IconButton(
                icon: Icon(_isDownloaded ? Icons.download_done : Icons.download),
                onPressed: _toggleDownload,
                tooltip: _isDownloaded ? 'Downloaded' : 'Download',
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareMaterial,
                tooltip: 'Share',
              ),
            ],
          ),
        ),
        
        // Material content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material title and info
                Text(
                  material['title'] ?? 'Untitled Material',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Course and date info
                Row(
                  children: [
                    Icon(
                      Icons.class_outlined,
                      size: 16,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      material['course'] ?? 'No Course',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      material['uploadDate'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Material preview/content
                if (type == 'pdf') _buildPdfViewer(material),
                if (type == 'video') _buildVideoPlayer(material),
                if (type == 'presentation') _buildPresentationViewer(material),
                if (type == 'unknown') _buildUnknownContent(material),
                
                const SizedBox(height: 24),
                
                // Material description
                if (material['description'] != null) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    material['description'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Related materials section
                _buildRelatedMaterials(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPdfViewer(Map<String, dynamic> material) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'PDF Document',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (material['size'] != null) ...[
            const SizedBox(height: 8),
            Text(
              material['size'],
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Open PDF in external viewer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening PDF in external viewer...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoPlayer(Map<String, dynamic> material) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video thumbnail/placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  size: 64,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to play video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                if (material['duration'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Duration: ${material['duration']}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Play button overlay
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Implement video playback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playing video...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPresentationViewer(Map<String, dynamic> material) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.slideshow,
            size: 64,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Presentation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Open presentation in external viewer
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening presentation...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.slideshow),
            label: const Text('View Presentation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUnknownContent(Map<String, dynamic> material) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Unsupported file type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This file type cannot be previewed in the app',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRelatedMaterials() {
    // Mock related materials
    final relatedMaterials = [
      {
        'id': '101',
        'title': 'Advanced Flutter Concepts',
        'type': 'pdf',
      },
      {
        'id': '102',
        'title': 'State Management Deep Dive',
        'type': 'video',
      },
      {
        'id': '103',
        'title': 'UI Design Patterns',
        'type': 'presentation',
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Materials',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: relatedMaterials.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final material = relatedMaterials[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMaterialColor(_getSafeMaterialType(material)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMaterialIcon(_getSafeMaterialType(material)),
                  color: _getMaterialColor(_getSafeMaterialType(material)),
                  size: 20,
                ),
              ),
              title: Text(_getSafeMaterialTitle(material)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to related material
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening ${material['title']}...'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
  
  IconData _getMaterialIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'video':
        return Icons.video_library_outlined;
      case 'presentation':
        return Icons.slideshow_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
  
  Color _getMaterialColor(String type) {
    switch (type) {
      case 'pdf':
        return Colors.red;
      case 'video':
        return Colors.purple;
      case 'presentation':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
  
  // Helper method to safely get material type with null check
  String _getSafeMaterialType(dynamic material, [String fallback = 'unknown']) {
    final type = material is Map ? material['type'] : null;
    return type?.toString() ?? fallback;
  }
  
  // Helper method to safely get material title with null check
  String _getSafeMaterialTitle(dynamic material, [String fallback = 'Untitled']) {
    final title = material is Map ? material['title'] : null;
    return title?.toString() ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
    );
  }
}
