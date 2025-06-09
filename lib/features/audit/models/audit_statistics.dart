class AuditStatistics {
  final String zoneId;
  final int year;
  final List<MonthlyStatistics> monthlyStats;

  AuditStatistics({
    required this.zoneId,
    required this.year,
    required this.monthlyStats,
  });

  factory AuditStatistics.fromJson(Map<String, dynamic> json) {
    try {
      final data = json['data'] as Map<String, dynamic>;
      return AuditStatistics(
        zoneId: data['zoneId'] as String? ?? '',
        year: data['year'] as int? ?? DateTime.now().year,
        monthlyStats: (data['statistics'] as List?)
                ?.map((e) => MonthlyStatistics.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e, stackTrace) {
      print('Error parsing AuditStatistics: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class MonthlyStatistics {
  final int month;
  final String monthName;
  final int totalSubmissions;
  final double averageScore;
  final double averagePercentage;
  final int totalScore;
  final int maxPossibleScore;
  final List<Submission> submissions;

  MonthlyStatistics({
    required this.month,
    required this.monthName,
    required this.totalSubmissions,
    required this.averageScore,
    required this.averagePercentage,
    required this.totalScore,
    required this.maxPossibleScore,
    required this.submissions,
  });

  factory MonthlyStatistics.fromJson(Map<String, dynamic> json) {
    try {
      return MonthlyStatistics(
        month: json['month'] as int? ?? 0,
        monthName: json['monthName'] as String? ?? 'Unknown',
        totalSubmissions: json['totalSubmissions'] as int? ?? 0,
        averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
        averagePercentage: (json['averagePercentage'] as num?)?.toDouble() ?? 0.0,
        totalScore: json['totalScore'] as int? ?? 0,
        maxPossibleScore: json['maxPossibleScore'] as int? ?? 0,
        submissions: (json['submissions'] as List?)
                ?.map((e) => Submission.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e, stackTrace) {
      print('Error parsing MonthlyStatistics: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class Submission {
  final String submissionId;
  final DateTime submittedAt;
  final int totalScore;
  final double percentage;

  Submission({
    required this.submissionId,
    required this.submittedAt,
    required this.totalScore,
    required this.percentage,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    try {
      // Handle percentage conversion from String to double
      double parsePercentage(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) {
          // Remove any non-numeric characters except decimal point
          final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
          return double.tryParse(cleanValue) ?? 0.0;
        }
        return 0.0;
      }

      return Submission(
        submissionId: json['submissionId'] as String? ?? '',
        submittedAt: json['submittedAt'] != null
            ? DateTime.parse(json['submittedAt'] as String)
            : DateTime.now(),
        totalScore: json['totalScore'] as int? ?? 0,
        percentage: parsePercentage(json['percentage']),
      );
    } catch (e, stackTrace) {
      print('Error parsing Submission: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
} 