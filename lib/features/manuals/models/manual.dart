

class Manual {
  String? id;
  String? orgId;
  String? zoneId;
  String? zoneName;
  String? name;
  String? path;
  bool? approved;
  String? createdAt;
  String? modifiedAt;
  String? createdBy;

  Manual(
      {this.id,
        this.orgId,
        this.zoneId,
        this.zoneName,
        this.name,
        this.path,
        this.approved,
        this.createdAt,
        this.modifiedAt,
        this.createdBy});

  Manual.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orgId = json['orgId'];
    zoneId = json['zoneId'];
    zoneName = json['zoneName'];
    name = json['name'];
    path = json['path'];
    approved = json['approved'];
    createdAt = json['createdAt'];
    modifiedAt = json['modifiedAt'];
    createdBy = json['createdBy'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['orgId'] = this.orgId;
    data['zoneId'] = this.zoneId;
    data['zoneName'] = this.zoneName;
    data['name'] = this.name;
    data['path'] = this.path;
    data['approved'] = this.approved;
    data['createdAt'] = this.createdAt;
    data['modifiedAt'] = this.modifiedAt;
    data['createdBy'] = this.createdBy;
    return data;
  }
}
