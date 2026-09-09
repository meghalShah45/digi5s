class TrainingMaterial {
  final String id;
  final String orgId;
  final String materialType;
  final String? path;
  final bool approved;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final String? createdBy;
  final String? modifiedBy;
  final String name;
  final String zoneId;

  TrainingMaterial({
    required this.id,
    required this.orgId,
    required this.materialType,
    this.path,
    required this.approved,
    required this.createdAt,
    this.modifiedAt,
    this.createdBy,
    this.modifiedBy,
    required this.name,
    required this.zoneId,
  });

  factory TrainingMaterial.fromJson(Map<String, dynamic> json) {
    return TrainingMaterial(
      id: json['id'].toString(),
      orgId: (json['orgId'] ?? '').toString(),
      materialType: (json['materialType'] ?? '').toString(),
      path: json['path'] as String?,
      approved: json['approved'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(json['modifiedAt']?.toString() ?? ''),
      createdBy: json['createdBy']?.toString(),
      modifiedBy: json['modifiedBy']?.toString(),
      name: (json['name'] ?? '').toString(),
      zoneId: (json['zoneId'] ?? '').toString(),
    );
  }

  /// PDF / VIDEO / IMAGE / OTHER based on the stored path.
  String get kind {
    final p = (path ?? '').toLowerCase();
    if (p.endsWith('.pdf') || p.contains('.pdf')) return 'PDF';
    if (p.endsWith('.mp4') || p.contains('.mp4')) return 'VIDEO';
    if (RegExp(r'\.(png|jpe?g|gif|webp)').hasMatch(p)) return 'IMAGE';
    return materialType.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orgId': orgId,
        'materialType': materialType,
        'path': path,
        'approved': approved,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt?.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
        'name': name,
        'zoneId': zoneId,
      };
}
