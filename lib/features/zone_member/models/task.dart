import 'dart:convert';

class Task {
  final String id;
  final String taskName;
  final String description;
  final List<TaskPhoto> taskPhotos;
  final String zoneMemberId;
  final String orgId;
  final String zoneId;
  final String? targetDate;
  final String status;
  final List<Activity> activity;
  final bool approved;
  final String createdAt;
  final String? modifiedAt;
  final String createdBy;
  final String? modifiedBy;

  Task({
    required this.id,
    required this.taskName,
    required this.description,
    required this.taskPhotos,
    required this.zoneMemberId,
    required this.orgId,
    required this.zoneId,
    this.targetDate,
    required this.status,
    required this.activity,
    required this.approved,
    required this.createdAt,
    this.modifiedAt,
    required this.createdBy,
    this.modifiedBy,
  });

  DateTime? get targetDateTime => targetDate == null ? null : DateTime.tryParse(targetDate!);
  DateTime? get createdDateTime => DateTime.tryParse(createdAt);
  bool get isOverdue {
    final t = targetDateTime;
    return t != null && !isCompleted && t.isBefore(DateTime.now());
  }

  bool get isPending => status == 'PENDING';
  bool get isInProgress => status == 'WORK-IN-PROGRESS' || status == 'VERIFY';
  bool get isPendingApproval => status == 'PENDING_APPROVAL';
  bool get isCompleted => status == 'COMPLETED';
  bool get isRejected => status == 'REJECTED';

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      taskName: (json['taskName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      taskPhotos: TaskPhoto.listFrom(json['taskPhotos']),
      zoneMemberId: (json['zoneMemberId'] ?? '').toString(),
      orgId: (json['orgId'] ?? '').toString(),
      zoneId: (json['zoneId'] ?? '').toString(),
      targetDate: json['targetDate']?.toString(),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      activity: Activity.listFrom(json['activity']),
      approved: json['approved'] != false,
      createdAt: (json['createdAt'] ?? '').toString(),
      modifiedAt: json['modifiedAt']?.toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      modifiedBy: json['modifiedBy']?.toString(),
    );
  }
}

class TaskPhoto {
  final String path;
  TaskPhoto({required this.path});

  factory TaskPhoto.fromJson(Map<String, dynamic> json) => TaskPhoto(path: (json['path'] ?? '').toString());

  static List<TaskPhoto> listFrom(dynamic raw) {
    final v = _decode(raw);
    if (v is List) {
      return v
          .map((e) => e is Map ? TaskPhoto.fromJson(Map<String, dynamic>.from(e)) : TaskPhoto(path: e.toString()))
          .where((p) => p.path.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

class Activity {
  final String status;
  final String actionOn;
  final String description;
  final String actionBy;
  final String? path;
  final String? remarks;

  Activity({
    required this.status,
    required this.actionOn,
    required this.description,
    required this.actionBy,
    this.path,
    this.remarks,
  });

  DateTime? get actionDateTime => DateTime.tryParse(actionOn);

  /// Photo URLs attached to this activity. `path` may be a single URL or a
  /// JSON-encoded list of `{path}` objects (task approval requests).
  List<String> get photoUrls {
    final p = path;
    if (p == null || p.isEmpty) return const [];
    if (p.startsWith('[')) {
      return TaskPhoto.listFrom(p).map((e) => e.path).toList();
    }
    return [p];
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      status: (json['status'] ?? '').toString(),
      actionOn: (json['actionOn'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      actionBy: (json['actionBy'] ?? '').toString(),
      path: json['path']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }

  static List<Activity> listFrom(dynamic raw) {
    final v = _decode(raw);
    if (v is List) {
      return v.whereType<Map>().map((e) => Activity.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return const [];
  }
}

dynamic _decode(dynamic raw) {
  if (raw is String) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
  return raw;
}
