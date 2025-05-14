class Zone {
  final String id;
  final String zoneName;
  final String orgId;
  final bool approved;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final String createdBy;
  final String? modifiedBy;

  Zone({
    required this.id,
    required this.zoneName,
    required this.orgId,
    required this.approved,
    required this.createdAt,
    this.modifiedAt,
    required this.createdBy,
    this.modifiedBy,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'],
      zoneName: json['zoneName'],
      orgId: json['orgId'],
      approved: json['approved'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: json['modifiedAt'] != null ? DateTime.parse(json['modifiedAt']) : null,
      createdBy: json['createdBy'],
      modifiedBy: json['modifiedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zoneName': zoneName,
      'orgId': orgId,
      'approved': approved,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  Zone copyWith({
    String? id,
    String? zoneName,
    String? orgId,
    bool? approved,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? createdBy,
    String? modifiedBy,
  }) {
    return Zone(
      id: id ?? this.id,
      zoneName: zoneName ?? this.zoneName,
      orgId: orgId ?? this.orgId,
      approved: approved ?? this.approved,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }
} 