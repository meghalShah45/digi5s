import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session.dart';
import '../screens/active_organizations_screen.dart';
import '../screens/add_organization_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/login_screen.dart';
import '../screens/organisation_detail_screen.dart';
import '../screens/pending_subscriptions_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/super_admin_dashboard.dart';

const _home = '/super-admin-dashboard';
const _publicRoutes = {'/login', '/forgot-password'};

/// Notifies GoRouter whenever the session changes so redirects re-run.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen<AsyncValue<UserSession?>>(sessionProvider, (_, __) => notifyListeners());
  }
}

/// Keeps the phone-shaped screens readable in a wide browser window.
class _Page extends StatelessWidget {
  const _Page({required this.child, this.maxWidth = 960});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFECECF1),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}

/// Routes of the super admin web console: login plus the super admin screens.
/// Organisation screens (zones, audits, uploads) exist only in the mobile app.
final adminRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _SessionListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final location = state.matchedLocation;

      // Still reading browser storage: stay on the splash screen.
      if (session.isLoading) return location == '/' ? null : '/';

      final user = session.valueOrNull;
      final isPublic = _publicRoutes.contains(location);
      if (user == null || !user.isSuperAdmin) return isPublic ? null : '/login';
      if (isPublic || location == '/') return _home;
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const _Page(maxWidth: 520, child: ForgotPasswordScreen())),
      // The shared logout button sends users to the mobile welcome screen.
      GoRoute(path: '/get-started', redirect: (_, __) => '/login'),

      GoRoute(path: _home, builder: (_, __) => const _Page(child: SuperAdminDashboard())),
      GoRoute(path: '/super-admin/add-organization', builder: (_, __) => const _Page(maxWidth: 640, child: AddOrganizationScreen())),
      GoRoute(path: '/super-admin/active-organizations', builder: (_, __) => const _Page(child: ActiveOrganizationsScreen())),
      GoRoute(
        path: '/super-admin/org/:orgId',
        builder: (_, state) => _Page(child: OrganisationDetailScreen(orgId: state.pathParameters['orgId'] ?? '')),
      ),
      GoRoute(path: '/super-admin/pending-subscriptions', builder: (_, __) => const _Page(child: PendingSubscriptionsScreen())),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No screen for ${state.uri}'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go('/'), child: const Text('Go home')),
          ],
        ),
      ),
    ),
  );
});
