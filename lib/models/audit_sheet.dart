class AuditSheet {
  final String id;
  final String name;
  final String zoneId;
  final String orgId;
  final String month;
  final DateTime createdAt;
  final List<AuditQuestion> questions;
  final bool isActive;

  AuditSheet({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.orgId,
    required this.createdAt,
    required this.questions,
    this.isActive = true, required this.month,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zoneId': zoneId,
      'orgId': orgId,
      'month': month,
      'createdAt': createdAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'isActive': isActive,
    };
  }

  factory AuditSheet.fromJson(Map<String, dynamic> json) {
    return AuditSheet(
      id: json['id'] as String,
      name: json['name'] as String,
      zoneId: json['zoneId'] as String,
      orgId: json['orgId'] as String,
      month: json['month'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      questions: (json['questions'] as List)
          .map((q) => AuditQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  AuditSheet copyWith({
    String? id,
    String? name,
    String? zoneId,
    String? orgId,
    String? month,
    DateTime? createdAt,
    List<AuditQuestion>? questions,
    bool? isActive,
  }) {
    return AuditSheet(
      id: id ?? this.id,
      name: name ?? this.name,
      zoneId: zoneId ?? this.zoneId,
      orgId: orgId ?? this.orgId,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
      isActive: isActive ?? this.isActive,
    );
  }
}

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'section': section,
      'grade': grade,
      if (answer != null) 'answer': answer,
    };
  }

  factory AuditQuestion.fromJson(Map<String, dynamic> json) {
    return AuditQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      section: json['section'] as int,
      grade: (json['grade'] as num).toDouble(),
      answer: json['answer'] as String?,
    );
  }
} 