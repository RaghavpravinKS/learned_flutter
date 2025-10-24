class LearningMaterialModel {
  final String? id;
  final String teacherId;
  final String classroomId;
  final String title;
  final String? description;
  final String materialType; // 'note', 'video', 'document', 'presentation', 'recording'
  final String? fileUrl;
  final int? fileSize;
  final String? mimeType;
  final bool isPublic;
  final List<String>? tags;
  final DateTime uploadDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? classroomName;
  final String? teacherName;

  LearningMaterialModel({
    this.id,
    required this.teacherId,
    required this.classroomId,
    required this.title,
    this.description,
    required this.materialType,
    this.fileUrl,
    this.fileSize,
    this.mimeType,
    this.isPublic = false,
    this.tags,
    required this.uploadDate,
    this.createdAt,
    this.updatedAt,
    this.classroomName,
    this.teacherName,
  });

  // Helper getters
  String get typeDisplay {
    switch (materialType) {
      case 'note':
        return 'Note';
      case 'video':
        return 'Video';
      case 'document':
        return 'Document';
      case 'presentation':
        return 'Presentation';
      case 'recording':
        return 'Recording';
      default:
        return materialType;
    }
  }

  String get fileSizeDisplay {
    if (fileSize == null) return 'Unknown';

    if (fileSize! < 1024) {
      return '$fileSize B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  bool get isPDF => mimeType?.contains('pdf') ?? false;
  bool get isVideo => mimeType?.startsWith('video/') ?? false;
  bool get isImage => mimeType?.startsWith('image/') ?? false;

  // Factory method to create from Supabase map
  factory LearningMaterialModel.fromMap(Map<String, dynamic> map) {
    return LearningMaterialModel(
      id: map['id'] as String?,
      teacherId: map['teacher_id'] as String,
      classroomId: map['classroom_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      materialType: map['material_type'] as String,
      fileUrl: map['file_url'] as String?,
      fileSize: map['file_size'] as int?,
      mimeType: map['mime_type'] as String?,
      isPublic: map['is_public'] as bool? ?? false,
      tags: map['tags'] != null ? List<String>.from(map['tags'] as List) : null,
      uploadDate: DateTime.parse(map['upload_date'] as String),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
      classroomName: map['classroom_name'] as String?,
      teacherName: map['teacher_name'] as String?,
    );
  }

  // Convert to map for Supabase
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'teacher_id': teacherId,
      'classroom_id': classroomId,
      'title': title,
      'description': description,
      'material_type': materialType,
      'file_url': fileUrl,
      'file_size': fileSize,
      'mime_type': mimeType,
      'is_public': isPublic,
      'tags': tags,
      'upload_date': uploadDate.toIso8601String(),
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Create a copy with updated fields
  LearningMaterialModel copyWith({
    String? id,
    String? teacherId,
    String? classroomId,
    String? title,
    String? description,
    String? materialType,
    String? fileUrl,
    int? fileSize,
    String? mimeType,
    bool? isPublic,
    List<String>? tags,
    DateTime? uploadDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearningMaterialModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      classroomId: classroomId ?? this.classroomId,
      title: title ?? this.title,
      description: description ?? this.description,
      materialType: materialType ?? this.materialType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      uploadDate: uploadDate ?? this.uploadDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
