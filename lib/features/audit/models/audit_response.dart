class AuditPhoto {
  final String file;
  final String description;

  AuditPhoto({
    required this.file,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'description': description,
    };
  }
}

class AuditResponse {
  final String questionId;
  final double score;
  final String remarks;
  final List<AuditPhoto> photos;

  AuditResponse({
    required this.questionId,
    required this.score,
    required this.remarks,
    required this.photos,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'score': score,
      'remarks': remarks,
      'photos': photos.map((photo) => photo.toJson()).toList(),
    };
  }
} 