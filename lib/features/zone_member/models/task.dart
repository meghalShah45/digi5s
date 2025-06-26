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

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      taskName: json['taskName'],
      description: json['description'],
      taskPhotos: (json['taskPhotos'] as List)
          .map((photo) => TaskPhoto.fromJson(photo))
          .toList(),
      zoneMemberId: json['zoneMemberId'],
      orgId: json['orgId'],
      zoneId: json['zoneId'],
      targetDate: json['targetDate'],
      status: json['status'],
      activity: (json['activity'] as List)
          .map((act) => Activity.fromJson(act))
          .toList(),
      approved: json['approved'],
      createdAt: json['createdAt'],
      modifiedAt: json['modifiedAt'],
      createdBy: json['createdBy'],
      modifiedBy: json['modifiedBy'],
    );
  }
}

class TaskPhoto {
  final String path;

  TaskPhoto({required this.path});

  factory TaskPhoto.fromJson(Map<String, dynamic> json) {
    return TaskPhoto(path: json['path']);
  }
}

class Activity {
  final String status;
  final String actionOn;
  final String description;
  final String actionBy;
  final String? path;

  Activity({
    required this.status,
    required this.actionOn,
    required this.description,
    required this.actionBy,
    this.path,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      status: json['status'],
      actionOn: json['actionOn'],
      description: json['description'],
      actionBy: json['actionBy'],
      path: json['path'],
    );
  }
} 