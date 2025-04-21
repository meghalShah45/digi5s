class SteeringCommitteeMember {
  final String id;
  final String name;
  final String role;
  final DateTime joinedDate;
  final String? photoUrl;

  SteeringCommitteeMember({
    required this.id,
    required this.name,
    required this.role,
    required this.joinedDate,
    this.photoUrl,
  });

  SteeringCommitteeMember copyWith({
    String? id,
    String? name,
    String? role,
    DateTime? joinedDate,
    String? photoUrl,
  }) {
    return SteeringCommitteeMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      joinedDate: joinedDate ?? this.joinedDate,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'joinedDate': joinedDate.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  factory SteeringCommitteeMember.fromJson(Map<String, dynamic> json) {
    return SteeringCommitteeMember(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      photoUrl: json['photoUrl'] as String?,
    );
  }
} 