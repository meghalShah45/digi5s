import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_web/admin_router.dart';
import 'core/api/api_client.dart';
import 'core/auth/session.dart';
import 'core/config/admin_console.dart';
import 'core/config/app_config.dart';
import 'theme/app_theme.dart';

/// Entry point of the super admin web console.
///
///   flutter build web -t lib/main_admin_web.dart
///
/// Only the super admin screens are compiled in; see `admin_web/admin_router.dart`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(overrides: [adminConsoleProvider.overrideWithValue(true)]);
  // Any 401 from any ApiClient logs the user out; the router then redirects.
  ApiClient.globalOnUnauthorized = () => container.read(sessionProvider.notifier).clear();
  runApp(UncontrolledProviderScope(container: container, child: const AdminConsoleApp()));
}

class AdminConsoleApp extends ConsumerWidget {
  const AdminConsoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '${AppConfig.appName} Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(adminRouterProvider),
    );
  }
}
