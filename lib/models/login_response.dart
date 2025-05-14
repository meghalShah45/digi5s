class LoginResponse {
  final int statusCode;
  final bool status;
  final String? error;
  final String? message;
  final LoginData? data;

  LoginResponse({
    required this.statusCode,
    required this.status,
    this.error,
    this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      statusCode: json['statusCode'] as int,
      status: json['status'] as bool,
      error: json['error'] as String?,
      message: json['message'] as String?,
      data: json['data'] != null ? LoginData.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }
}

class LoginData {
  final String id;
  final String? roleId;
  final String? orgId;
  final String? zoneId;
  final String email;
  final String phoneNumber;
  final String? photo;
  final String fullName;
  final String role;
  final List<String> scope;
  final String? designation;
  final String authToken;
  final String? firebaseToken;
  final String signupType;
  final bool approved;
  final bool disabled;
  final String? fcmToken;
  final String createdBy;
  final int notifications;

  LoginData({
    required this.id,
    this.roleId,
    this.orgId,
    this.zoneId,
    required this.email,
    required this.phoneNumber,
    this.photo,
    required this.fullName,
    required this.role,
    required this.scope,
    this.designation,
    required this.authToken,
    this.firebaseToken,
    required this.signupType,
    required this.approved,
    required this.disabled,
    this.fcmToken,
    required this.createdBy,
    required this.notifications,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json['id'] as String,
      roleId: json['roleId'] as String?,
      orgId: json['orgId'] as String?,
      zoneId: json['zoneId'] as String?,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      photo: json['photo'] as String?,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      scope: List<String>.from(json['scope'] as List),
      designation: json['designation'] as String?,
      authToken: json['authToken'] as String,
      firebaseToken: json['firebaseToken'] as String?,
      signupType: json['signupType'] as String,
      approved: json['approved'] as bool,
      disabled: json['disabled'] as bool,
      fcmToken: json['fcmToken'] as String?,
      createdBy: json['createdBy'] as String,
      notifications: json['notifications'] as int,
    );
  }
} 