class TrainingMaterial {
  final String id;
  final String orgId;
  final String materialType;
  final String path;
  final bool approved;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String createdBy;
  final String? modifiedBy;

  TrainingMaterial({
    required this.id,
    required this.orgId,
    required this.materialType,
    required this.path,
    required this.approved,
    required this.createdAt,
    required this.modifiedAt,
    required this.createdBy,
    this.modifiedBy,
  });

  factory TrainingMaterial.fromJson(Map<String, dynamic> json) {
    return TrainingMaterial(
      id: json['id'],
      orgId: json['orgId'],
      materialType: json['materialType'],
      path: json['path'],
      approved: json['approved'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      createdBy: json['createdBy'],
      modifiedBy: json['modifiedBy'],
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
    };
  }
} 