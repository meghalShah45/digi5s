class ErrorResponse {
  final int statusCode;
  final String? error;
  final String? message;

  ErrorResponse({
    required this.statusCode,
    this.error,
    this.message,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      statusCode: json['statusCode'] as int,
      error: json['error'] as String?,
      message: json['message'] as String?,
    );
  }

  String get displayMessage {
    return message ?? error ?? 'An error occurred';
  }
} 