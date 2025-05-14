class RedTag {
  final String id;
  final String orgId;
  final String zoneId;
  final String description;
  final String path;
  final String status;
  final List<Activity> activity;
  final String? remarks;
  final bool approved;
  final DateTime createdAt;
  final String createdBy;
  final String email;
  final String zoneName;

  RedTag({
    required this.id,
    required this.orgId,
    required this.zoneId,
    required this.description,
    required this.path,
    required this.status,
    required this.activity,
    this.remarks,
    required this.approved,
    required this.createdAt,
    required this.createdBy,
    required this.email,
    required this.zoneName,
  });

  factory RedTag.fromJson(Map<String, dynamic> json) {
    return RedTag(
      id: json['id'],
      orgId: json['orgId'],
      zoneId: json['zoneId'],
      description: json['description'],
      path: json['path'],
      status: json['status'],
      activity: (json['activity'] as List)
          .map((activity) => Activity.fromJson(activity))
          .toList(),
      remarks: json['remarks'],
      approved: json['approved'],
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      email: json['email'],
      zoneName: json['zoneName'],
    );
  }
}

class Activity {
  final String status;
  final DateTime actionOn;
  final String description;
  final String actionBy;

  Activity({
    required this.status,
    required this.actionOn,
    required this.description,
    required this.actionBy,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      status: json['status'],
      actionOn: DateTime.parse(json['actionOn']),
      description: json['description'],
      actionBy: json['actionBy'],
    );
  }
} 