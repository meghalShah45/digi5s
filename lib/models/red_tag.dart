class RedTag {
  final String id;
  final String title;
  final String description;
  final DateTime dateCreated;
  final String status; // 'pending', 'approved', 'rejected'
  final String? remarks;
  final String? decision;
  final String zoneId; // The zone this red tag belongs to
  final String createdById; // ID of the user who created the red tag
  final String? completedById; // ID of the user who completed the red tag
  final DateTime? completedAt; // When the red tag was completed

  RedTag({
    required this.id,
    required this.title,
    required this.description,
    required this.dateCreated,
    required this.status,
    required this.zoneId,
    required this.createdById,
    this.remarks,
    this.decision,
    this.completedById,
    this.completedAt,
  });

  RedTag copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateCreated,
    String? status,
    String? remarks,
    String? decision,
    String? zoneId,
    String? createdById,
    String? completedById,
    DateTime? completedAt,
  }) {
    return RedTag(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateCreated: dateCreated ?? this.dateCreated,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      decision: decision ?? this.decision,
      zoneId: zoneId ?? this.zoneId,
      createdById: createdById ?? this.createdById,
      completedById: completedById ?? this.completedById,
      completedAt: completedAt ?? this.completedAt,
    );
  }
} 