class AuditSheet {
  final String id;
  final String name;
  final String orgId;
  final String month;
  final DateTime createdAt;
  final List<AuditQuestion> questions;
  final bool isActive;
  final int maxScore;
  final int totalQuestions;

  AuditSheet({
    required this.id,
    required this.name,
    required this.orgId,
    required this.createdAt,
    required this.questions,
    this.isActive = true,
    required this.month,
    this.maxScore = 0,
    required this.totalQuestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'orgId': orgId,
      'month': month,
      'createdAt': createdAt.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'isActive': isActive,
      'maxScore': maxScore,
      'totalQuestions': totalQuestions,
    };
  }

  factory AuditSheet.fromJson(Map<String, dynamic> json) {
    return AuditSheet(
      id: json['id'] as String,
      name: json['name'] as String,
      orgId: json['orgId'] as String,
      month: json['month'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      questions: (json['questions'] as List)
          .map((q) => AuditQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      maxScore: json['maxScore'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
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
    int? maxScore,
    int? totalQuestions,
  }) {
    return AuditSheet(
      id: id ?? this.id,
      name: name ?? this.name,
      orgId: orgId ?? this.orgId,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
      isActive: isActive ?? this.isActive,
      maxScore: maxScore ?? this.maxScore,
      totalQuestions: totalQuestions ?? this.totalQuestions,
    );
  }
}

class AuditQuestion {
  final String question;
  final String questionId;
  String? score;

  AuditQuestion({
    required this.question,
    required this.questionId,
    this.score = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'questionId': questionId,
      'score': score,
    };
  }

  factory AuditQuestion.fromJson(Map<String, dynamic> json) {
    return AuditQuestion(
      question: json['question'] as String,
      questionId: json['questionId'] as String,
      score: (json['score']) ?? '',
    );
  }
} 