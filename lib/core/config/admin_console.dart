import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True only in the super admin web console (`lib/main_admin_web.dart`).
///
/// The console has no organisation screens, so it accepts super admin logins
/// only and hides everything that leads into an organisation.
final adminConsoleProvider = Provider<bool>((ref) => false);
