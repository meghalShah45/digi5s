import 'dart:convert';

class RedTag {
  final String id;
  final String orgId;
  final String zoneId;
  final String description;
  final String? path;
  final String status;
  final List<Activity> activity;
  final String? remarks;
  final bool approved;
  final DateTime createdAt;
  final String createdBy;
  final String email;
  final String zoneName;
  final String? redTagBy;

  RedTag({
    required this.id,
    required this.orgId,
    required this.zoneId,
    required this.description,
    this.path,
    required this.status,
    required this.activity,
    this.remarks,
    required this.approved,
    required this.createdAt,
    required this.createdBy,
    required this.email,
    required this.zoneName,
    this.redTagBy,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED' || status.toUpperCase() == 'COMPLETED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  factory RedTag.fromJson(Map<String, dynamic> json) {
    return RedTag(
      id: json['id'].toString(),
      orgId: (json['orgId'] ?? '').toString(),
      zoneId: (json['zoneId'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      path: json['path'] as String?,
      status: (json['status'] ?? 'PENDING').toString(),
      activity: Activity.listFrom(json['activity']),
      remarks: json['remarks'] as String?,
      approved: json['approved'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      createdBy: (json['createdBy'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      zoneName: (json['zoneName'] ?? '').toString(),
      redTagBy: json['redTagBy']?.toString(),
    );
  }

  RedTag copyWith({String? status, bool? approved, List<Activity>? activity}) => RedTag(
        id: id,
        orgId: orgId,
        zoneId: zoneId,
        description: description,
        path: path,
        status: status ?? this.status,
        activity: activity ?? this.activity,
        remarks: remarks,
        approved: approved ?? this.approved,
        createdAt: createdAt,
        createdBy: createdBy,
        email: email,
        zoneName: zoneName,
        redTagBy: redTagBy,
      );
}

class Activity {
  final String status;
  final DateTime actionOn;
  final String description;
  final String actionBy;
  final String? remarks;

  Activity({
    required this.status,
    required this.actionOn,
    required this.description,
    required this.actionBy,
    this.remarks,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      status: (json['status'] ?? '').toString(),
      actionOn: DateTime.tryParse(json['actionOn']?.toString() ?? '') ?? DateTime.now(),
      description: (json['description'] ?? json['remarks'] ?? '').toString(),
      actionBy: (json['actionBy'] ?? '').toString(),
      remarks: json['remarks']?.toString(),
    );
  }

  /// The backend stores `activity` as JSON; some rows come back as a string.
  static List<Activity> listFrom(dynamic raw) {
    dynamic v = raw;
    if (v is String) {
      try {
        v = jsonDecode(v);
      } catch (_) {
        return const [];
      }
    }
    if (v is List) {
      return v.whereType<Map>().map((e) => Activity.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return const [];
  }
}
