/// Build-time configuration.
///
/// Override the API host for local development with:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.seichoconsulting.com',
  );

  static const String appName = 'diGi5S';

  /// Public S3 bucket that holds every uploaded file.
  static const String uploadsBaseUrl =
      'https://digi5s-app-uploads.s3.ap-south-1.amazonaws.com';

  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 3);
}
