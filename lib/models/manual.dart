class Manual {
  final String id;
  final String name;
  final String filePath;
  final DateTime uploadDate;
  final int fileSize; // in bytes
  final bool isActive;
  final String zoneId;
  final String uploadedById;
  final String? description;
  final String fileType;
  final int version;
  final DateTime? lastUpdated;

  Manual({
    required this.id,
    required this.name,
    required this.filePath,
    required this.uploadDate,
    required this.fileSize,
    required this.zoneId,
    required this.uploadedById,
    required this.fileType,
    this.isActive = true,
    this.description,
    this.version = 1,
    this.lastUpdated,
  });

  Manual copyWith({
    String? id,
    String? name,
    String? filePath,
    DateTime? uploadDate,
    int? fileSize,
    bool? isActive,
    String? zoneId,
    String? uploadedById,
    String? description,
    String? fileType,
    int? version,
    DateTime? lastUpdated,
  }) {
    return Manual(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      uploadDate: uploadDate ?? this.uploadDate,
      fileSize: fileSize ?? this.fileSize,
      isActive: isActive ?? this.isActive,
      zoneId: zoneId ?? this.zoneId,
      uploadedById: uploadedById ?? this.uploadedById,
      description: description ?? this.description,
      fileType: fileType ?? this.fileType,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
} 