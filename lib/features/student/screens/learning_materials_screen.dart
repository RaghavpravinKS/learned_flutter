import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LearningMaterialsScreen extends ConsumerStatefulWidget {
  const LearningMaterialsScreen({super.key});

  @override
  ConsumerState<LearningMaterialsScreen> createState() => _LearningMaterialsScreenState();
}

class _LearningMaterialsScreenState extends ConsumerState<LearningMaterialsScreen> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  
  // Mock data - replace with actual data from provider
  final List<Map<String, dynamic>> _materials = [
    {
      'id': '1',
      'title': 'Introduction to Flutter',
      'description': 'Learn the basics of Flutter development',
      'type': 'pdf',
      'course': 'Flutter Fundamentals',
      'uploadDate': '2023-04-15',
      'size': '2.4 MB',
      'isDownloaded': true,
    },
    {
      'id': '2',
      'title': 'State Management in Flutter',
      'description': 'Learn about different state management solutions',
      'type': 'video',
      'course': 'Advanced Flutter',
      'uploadDate': '2023-04-20',
      'duration': '45:30',
      'isDownloaded': false,
    },
    {
      'id': '3',
      'title': 'UI Design Principles',
      'description': 'Best practices for designing beautiful UIs',
      'type': 'pdf',
      'course': 'UI/UX Design',
      'uploadDate': '2023-04-25',
      'size': '3.1 MB',
      'isDownloaded': false,
    },
    {
      'id': '4',
      'title': 'Flutter Animations',
      'description': 'Creating smooth animations in Flutter',
      'type': 'video',
      'course': 'Advanced Flutter',
      'uploadDate': '2023-05-01',
      'duration': '32:15',
      'isDownloaded': true,
    },
    {
      'id': '5',
      'title': 'API Integration Guide',
      'description': 'How to integrate REST APIs in Flutter',
      'type': 'pdf',
      'course': 'Networking',
      'uploadDate': '2023-05-05',
      'size': '1.8 MB',
      'isDownloaded': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    var filtered = _materials;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((material) {
        return material['title'].toString().toLowerCase().contains(query) ||
            material['description'].toString().toLowerCase().contains(query) ||
            material['course'].toString().toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply type filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((material) => material['type'] == _selectedFilter).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              // Navigate to downloaded materials
            },
            tooltip: 'Downloaded Materials',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search materials...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          
          // Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('PDFs', 'pdf'),
                const SizedBox(width: 8),
                _buildFilterChip('Videos', 'video'),
                const SizedBox(width: 8),
                _buildFilterChip('Presentations', 'presentation'),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Materials List
          Expanded(
            child: _filteredMaterials.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No materials found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final material = _filteredMaterials[index];
                      return _buildMaterialItem(context, material);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey[300]!,
        ),
      ),
    );
  }
  
  Widget _buildMaterialItem(BuildContext context, Map<String, dynamic> material) {
    final isDownloaded = material['isDownloaded'] == true;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to material viewer
          final router = GoRouter.of(context);
          router.push(
            '/student/materials/${material['id']}',
            extra: material,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Type Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getMaterialColor(material['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMaterialIcon(material['type']),
                  color: _getMaterialColor(material['type']),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Material Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      material['description'],
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.class_outlined,
                          size: 14,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          material['course'],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          material['uploadDate'],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Download/View Button
              IconButton(
                icon: Icon(
                  isDownloaded ? Icons.check_circle_outline : Icons.download_outlined,
                  color: isDownloaded 
                      ? Colors.green 
                      : Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  // Handle download/view action
                  if (isDownloaded) {
                    // Open the downloaded file
                  } else {
                    // Download the file
                    setState(() {
                      material['isDownloaded'] = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${material['title']}...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                tooltip: isDownloaded ? 'Open' : 'Download',
              ),
            ],
          ),
        ),
      ),
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
}
