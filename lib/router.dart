import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/session.dart';
import 'features/audit/models/audit_sheet.dart';
import 'features/audit/screens/audit_sheets_list_screen.dart';
import 'features/audit/screens/audit_statistics_screen.dart';
import 'features/audit/screens/perform_audit_screen.dart';
import 'features/manuals/screens/manage_manual_screen.dart';
import 'features/news/screens/manage_news_screen.dart';
import 'features/red_tags/screens/create_red_tag_screen.dart';
import 'features/red_tags/screens/manage_red_tags_main_screen.dart';
import 'features/training_material/screens/manage_training_material_screen.dart';
import 'features/zone_member/screens/my_tasks_screen.dart';
import 'features/zone_member/screens/zone_member_dashboard.dart';
import 'screens/active_organizations_screen.dart';
import 'screens/add_organization_screen.dart';
import 'screens/approve_5s_task_screen.dart';
import 'screens/create_5s_task_screen.dart';
import 'screens/flash_news_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manage_5s_tasks_screen.dart';
import 'screens/manage_audit/manage_audit_screen.dart';
import 'screens/manage_best_practices_screen.dart';
import 'screens/manage_members_screen.dart';
import 'screens/organisation_detail_screen.dart';
import 'screens/pending_subscriptions_screen.dart';
import 'screens/org_admin_dashboard.dart';
import 'screens/red_tag_details_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/ss_training_material_screen.dart';
import 'screens/steering_committee_screen.dart';
import 'screens/super_admin_dashboard.dart';
import 'screens/viewer_dashboard.dart';
import 'screens/zone_leader_dashboard.dart';
import 'screens/zones/add_zone_screen.dart';
import 'screens/zones/manage_zone_screen.dart';

/// Routes reachable without a session.
const _publicRoutes = {'/login', '/forgot-password'};

/// Notifies GoRouter whenever the session changes so redirects re-run.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen<AsyncValue<UserSession?>>(sessionProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _SessionListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final location = state.matchedLocation;

      // Still reading secure storage: stay on the splash screen.
      if (session.isLoading) return location == '/' ? null : '/';

      final user = session.valueOrNull;
      final isPublic = _publicRoutes.contains(location);

      if (user == null) return isPublic ? null : '/login';
      if (isPublic || location == '/') return user.homeRoute;
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // Role homes
      GoRoute(path: '/super-admin-dashboard', builder: (_, __) => const SuperAdminDashboard()),
      GoRoute(path: '/org-admin-dashboard', builder: (_, __) => const OrgAdminDashboard()),
      GoRoute(path: '/zone-leader-dashboard', builder: (_, __) => const ZoneLeaderDashboard()),
      GoRoute(path: '/zone-member-dashboard', builder: (_, __) => const ZoneMemberDashboard()),
      GoRoute(path: '/viewer-dashboard', builder: (_, __) => const ViewerDashboard()),

      // Super admin
      GoRoute(path: '/super-admin/add-organization', builder: (_, __) => const AddOrganizationScreen()),
      GoRoute(path: '/super-admin/active-organizations', builder: (_, __) => const ActiveOrganizationsScreen()),
      GoRoute(
        path: '/super-admin/org/:orgId',
        builder: (_, state) => OrganisationDetailScreen(orgId: state.pathParameters['orgId'] ?? ''),
      ),
      GoRoute(path: '/super-admin/pending-subscriptions', builder: (_, __) => const PendingSubscriptionsScreen()),

      // Zones & members
      GoRoute(path: '/manage-zone', builder: (_, __) => const ManageZoneScreen()),
      GoRoute(
        path: '/add-zone',
        builder: (_, state) {
          final orgId = state.extra as String?;
          if (orgId == null) {
            return const Scaffold(body: Center(child: Text('Organization ID is required')));
          }
          return AddZoneScreen(orgId: orgId);
        },
      ),
      GoRoute(path: '/manage-steering-committee', builder: (_, __) => const SteeringCommitteeScreen()),
      GoRoute(
        path: '/manage-members/:zoneName',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ManageMembersScreen(
            zoneName: state.pathParameters['zoneName'] ?? '',
            zoneId: extra?['zoneId'] ?? '',
            orgId: extra?['orgId'] ?? '',
          );
        },
      ),

      // Red tags
      GoRoute(path: '/manage-red-tags', builder: (_, __) => const ManageRedTagsMainScreen()),
      GoRoute(path: '/create-red-tag', builder: (_, __) => const CreateRedTagScreenWrapper()),
      GoRoute(
        path: '/red-tag-details/:tagId',
        builder: (_, state) => RedTagDetailsScreen(tagId: state.pathParameters['tagId'] ?? ''),
      ),

      // Content
      GoRoute(path: '/manage-manual', builder: (_, __) => const ManageManualScreen()),
      GoRoute(path: '/manage-news', builder: (_, __) => const ManageNewsScreen()),
      GoRoute(path: '/what-is-news', builder: (_, __) => const ManageNewsScreen(isReadOnly: true)),
      GoRoute(path: '/manage-training-material', builder: (_, __) => const ManageTrainingMaterialScreen()),
      GoRoute(path: '/5s-training-material', builder: (_, __) => const SSTrainingMaterialScreen()),
      GoRoute(path: '/flash-news', builder: (_, __) => const FlashNewsScreen()),
      GoRoute(path: '/manage-best-practices', builder: (_, __) => const ManageBestPracticesScreen()),
      GoRoute(path: '/best-practices', redirect: (_, __) => '/manage-best-practices'),

      // Tasks
      GoRoute(path: '/manage-5s-tasks', builder: (_, __) => Manage5STasksScreen()),
      GoRoute(path: '/create-5s-task', builder: (_, __) => const Create5STaskScreen()),
      GoRoute(path: '/approve-5s-task', builder: (_, __) => const Approve5STaskScreen()),
      GoRoute(path: '/my-5s-tasks', redirect: (_, __) => '/zone-member/my-tasks'),
      GoRoute(path: '/zone-member/my-tasks', builder: (_, __) => const MyTasksScreen()),

      // Audit
      GoRoute(path: '/manage-audit', builder: (_, __) => const ManageAuditScreen()),
      GoRoute(path: '/perform-audit', builder: (_, __) => const AuditSheetsListScreen()),
      GoRoute(
        path: '/perform-audit/:id',
        builder: (_, state) => PerformAuditScreen(sheet: state.extra as AuditSheet),
      ),
      GoRoute(
        path: '/audit-statistics/:zoneId',
        builder: (_, state) => AuditStatisticsScreen(zoneId: state.pathParameters['zoneId'] ?? ''),
        routes: [
          // Older screens push `/audit-statistics/<zoneId>/<year>`.
          GoRoute(
            path: ':year',
            builder: (_, state) => AuditStatisticsScreen(zoneId: state.pathParameters['zoneId'] ?? ''),
          ),
        ],
      ),
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
