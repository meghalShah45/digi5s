class News {
  final String? id;
  final String? orgId;
  final String? title;
  final String? path;
  final String? description;
  final String? createdAt;
  final String? modifiedAt;
  final String? createdBy;
  final String? modifiedBy;

  News({
    this.id,
    this.orgId,
    this.title,
    this.path,
    this.description,
    this.createdAt,
    this.modifiedAt,
    this.createdBy,
    this.modifiedBy,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      orgId: json['orgId'],
      title: json['title'],
      path: json['path'],
      description: json['description'],
      createdAt: json['createdAt'],
      modifiedAt: json['modifiedAt'],
      createdBy: json['createdBy'],
      modifiedBy: json['modifiedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgId': orgId,
      'title': title,
      'path': path,
      'description': description,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }
} 