class AuditQuestion {
  final String id;
  final String question;
  final int section; // 15, 25, 35, 45, 55
  final double grade; // 0, 1, 2
  final String? answer;

  AuditQuestion({
    required this.id,
    required this.question,
    required this.section,
    required this.grade,
    this.answer,
  });
}

class AuditSheet {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<AuditQuestion> questions;
  final bool isActive;

  AuditSheet({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.questions,
    this.isActive = true,
  });

  AuditSheet copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<AuditQuestion>? questions,
    bool? isActive,
  }) {
    return AuditSheet(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
      isActive: isActive ?? this.isActive,
    );
  }
} 