class TrainingMaterial {
  final String id;
  final String orgId;
  final String materialType;
  final String? path;
  final bool approved;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String createdBy;
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
    required this.modifiedAt,
    required this.createdBy,
    this.modifiedBy,
    required this.name,
    required this.zoneId,
  });

  factory TrainingMaterial.fromJson(Map<String, dynamic> json) {
    return TrainingMaterial(
      id: json['id'] as String,
      orgId: json['orgId'] as String,
      materialType: json['materialType'] as String,
      path: json['path'] as String?,
      approved: json['approved'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      createdBy: json['createdBy'] as String,
      modifiedBy: json['modifiedBy'] as String?,
      name: json['name'] as String,
      zoneId: json['zoneId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgId': orgId,
      'materialType': materialType,
      'path': path,
      'approved': approved,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
      'name': name,
      'zoneId': zoneId,
    };
  }
} 