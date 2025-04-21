class Zone {
  final String id;
  final String name;
  final String description;
  final List<String> memberIds;
  final bool isActive;
  final String leaderId;

  Zone({
    required this.id,
    required this.name,
    required this.description,
    required this.memberIds,
    required this.leaderId,
    this.isActive = true,
  });

  Zone copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? memberIds,
    bool? isActive,
    String? leaderId,
  }) {
    return Zone(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberIds: memberIds ?? this.memberIds,
      isActive: isActive ?? this.isActive,
      leaderId: leaderId ?? this.leaderId,
    );
  }
} 