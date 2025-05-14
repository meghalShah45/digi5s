class ZoneResponse {
  final int statusCode;
  final String? message;
  final List<ZoneData>? data;

  ZoneResponse({
    required this.statusCode,
    this.message,
    this.data,
  });

  factory ZoneResponse.fromJson(Map<String, dynamic> json) {
    return ZoneResponse(
      statusCode: json['statusCode'] as int,
      message: json['message'] as String?,
      data: json['data'] != null
          ? List<ZoneData>.from(
              (json['data'] as List).map((x) => ZoneData.fromJson(x)))
          : null,
    );
  }
}

class ZoneData {
  final String id;
  final String name;
  final String? description;
  final String orgId;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ZoneData({
    required this.id,
    required this.name,
    this.description,
    required this.orgId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ZoneData.fromJson(Map<String, dynamic> json) {
    return ZoneData(
      id: json['id'] as String,
      name: json['zoneName'] as String,
      description: json['description'] as String?,
      orgId: json['orgId'] as String,/*
      leaderId: json['leaderId'] as String?,
      leaderName: json['leaderName'] as String?,
      memberCount: json['memberCount'] as int,
      active: json['active'] as bool,*/
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
} 