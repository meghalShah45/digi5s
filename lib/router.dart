import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/audit/screens/audit_statistics_screen.dart';
import 'features/manuals/screens/manage_manual_screen.dart';
import 'features/zone_member/screens/zone_member_dashboard.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/active_organizations_screen.dart';
import 'screens/add_organization_screen.dart';
import 'screens/org_admin_dashboard.dart';
import 'screens/zone_leader_dashboard.dart';
import 'screens/zone_member_dashboard.dart';
import 'screens/viewer_dashboard.dart';
import 'screens/super_admin_dashboard.dart';
import 'screens/manage_members_screen.dart';
import 'screens/manage_org_info_screen.dart';
import 'screens/manage_steering_committee_screen.dart';
import 'screens/manage_red_tags_screen.dart';
import 'screens/red_tag_details_screen.dart';
import 'screens/manage_5s_tasks_screen.dart';
import 'screens/create_5s_task_screen.dart';
import 'screens/approve_5s_task_screen.dart';
import 'screens/my_5s_tasks_screen.dart';
import 'screens/ss_training_material_screen.dart';
import 'screens/module_selection_screen.dart';
import 'screens/manage_best_practices_screen.dart';
import 'screens/manage_audit/manage_audit_screen.dart';
import 'features/audit/screens/audit_sheets_list_screen.dart';
import 'features/audit/screens/perform_audit_screen.dart';
import 'screens/flash_news_screen.dart';
import 'screens/zones/manage_zone_screen.dart';
import 'screens/zones/add_zone_screen.dart';
import 'screens/steering_committee_screen.dart';
import 'features/news/screens/manage_news_screen.dart';
import 'features/training_material/screens/manage_training_material_screen.dart';
import 'features/red_tags/screens/manage_red_tags_main_screen.dart';
import 'features/red_tags/screens/create_red_tag_screen.dart';
import 'features/red_tags/screens/view_red_tag_list_screen.dart';
import 'features/red_tags/screens/red_tag_list_screen.dart';
import 'features/audit/models/audit_sheet.dart';
import 'features/zone_member/screens/my_tasks_screen.dart';
import 'models/organization.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const ModuleSelectionScreen(),
    ),
    GoRoute(
      path: '/super-admin-dashboard',
      builder: (context, state) => const SuperAdminDashboard(),
    ),
    GoRoute(
      path: '/super-admin/add-organization',
      builder: (context, state) => const AddOrganizationScreen(),
    ),
    GoRoute(
      path: '/super-admin/active-organizations',
      builder: (context, state) => const ActiveOrganizationsScreen(),
    ),
    GoRoute(
      path: '/super-admin/manage-org-info',
      builder: (context, state) {
        final org = state.extra as Organization;
        return ManageOrgInfoScreen(org: org);
      },
    ),
    GoRoute(
      path: '/org-admin-dashboard',
      builder: (context, state) => const OrgAdminDashboard(),
    ),
    GoRoute(
      path: '/zone-leader-dashboard',
      builder: (context, state) => const ZoneLeaderDashboard(),
    ),
    GoRoute(
      path: '/zone-member-dashboard',
      builder: (context, state) => const ZoneMemberDashboard(),
    ),
    GoRoute(
      path: '/viewer-dashboard',
      builder: (context, state) => const ViewerDashboard(),
    ),
    GoRoute(
      path: '/manage-zone',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageZoneScreen();
      },
    ),
    GoRoute(
      path: '/add-zone',
      builder: (BuildContext context, GoRouterState state) {
        final orgId = state.extra as String?;
        if (orgId == null) {
          return const Scaffold(
            body: Center(
              child: Text('Organization ID is required'),
            ),
          );
        }
        return AddZoneScreen(orgId: orgId);
      },
    ),
    GoRoute(
      path: '/manage-steering-committee',
      builder: (BuildContext context, GoRouterState state) {
        return const SteeringCommitteeScreen();
      },
    ),
    GoRoute(
      path: '/manage-members/:zoneName',
      builder: (BuildContext context, GoRouterState state) {
        final zoneName = state.pathParameters['zoneName'] ?? '';
        final zoneId = state.extra as Map<String, dynamic>?;
        return ManageMembersScreen(
          zoneName: zoneName,
          zoneId: zoneId?['zoneId'] ?? '',
          orgId: zoneId?['orgId'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/manage-red-tags',
      builder: (context, state) => const ManageRedTagsMainScreen(),
    ),
    GoRoute(
      path: '/create-red-tag',
      builder: (context, state) => const CreateRedTagScreenWrapper(),
    ),
    GoRoute(
      path: '/view-red-tag-list',
      builder: (context, state) => const ViewRedTagListScreen(),
    ),
    GoRoute(
      path: '/red-tag-details/:tagId',
      builder: (BuildContext context, GoRouterState state) {
        final tagId = state.pathParameters['tagId'] ?? '';
        return RedTagDetailsScreen(tagId: tagId);
      },
    ),
    GoRoute(
      path: '/manage-manual',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageManualScreen();
      },
    ),
    GoRoute(
      path: '/manage-audit',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageAuditScreen();
      },
    ),
    GoRoute(
      path: '/manage-news',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageNewsScreen();
      },
    ),
    GoRoute(
      path: '/manage-training-material',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageTrainingMaterialScreen();
      },
    ),
    GoRoute(
      path: '/5s-training-material',
      builder: (context, state) => const SSTrainingMaterialScreen(),
    ),
    GoRoute(
      path: '/flash-news',
      builder: (context, state) => const FlashNewsScreen(),
    ),
    GoRoute(
      path: '/manage-best-practices',
      builder: (context, state) => const ManageBestPracticesScreen(),
    ),
    GoRoute(
      path: '/manage-5s-tasks',
      builder: (context, state) =>  Manage5STasksScreen(),
    ),
    GoRoute(
      path: '/create-5s-task',
      builder: (context, state) => const Create5STaskScreen(),
    ),
    GoRoute(
      path: '/approve-5s-task',
      builder: (context, state) => const Approve5STaskScreen(),
    ),
    GoRoute(
      path: '/my-5s-tasks',
      builder: (context, state) => const My5STasksScreen(),
    ),
    GoRoute(
      path: '/zone-member/my-tasks',
      builder: (context, state) => const MyTasksScreen(),
    ),
    GoRoute(
      path: '/perform-audit',
      builder: (context, state) => const AuditSheetsListScreen(),
    ),
    GoRoute(
      path: '/perform-audit/:id',
      builder: (context, state) {
        final sheet = state.extra as AuditSheet;
        return PerformAuditScreen(sheet: sheet);
      },
    ),
    GoRoute(
      path: '/audit-statistics/:zoneId',
      builder: (context, state) {
        final zoneId = state.pathParameters['zoneId'] ?? '';
        final year = int.parse(state.pathParameters['year'] ?? DateTime.now().year.toString());
        return AuditStatisticsScreen(zoneId: zoneId);
      },
    ),
    // GoRoute(
    //   path: '/red-tags/:orgId',
    //   builder: (context, state) {
    //     final orgId = state.pathParameters['orgId'] ?? '';
    //     return RedTagListScreen(orgId: orgId);
    //   },
    // ),
  ],
); 