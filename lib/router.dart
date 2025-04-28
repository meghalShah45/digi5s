import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seicho_app/screens/home_screen.dart';
import 'package:seicho_app/screens/manage_news_screen.dart';
import 'package:seicho_app/screens/manage_zone_screen.dart';
import 'package:seicho_app/screens/add_zone_screen.dart';
import 'package:seicho_app/screens/manage_members_screen.dart';
import 'package:seicho_app/screens/manage_red_tags_screen.dart';
import 'package:seicho_app/screens/red_tag_details_screen.dart';
import 'package:seicho_app/screens/manage_manual_screen.dart';
import 'package:seicho_app/screens/manage_audit_screen.dart';
import 'package:seicho_app/screens/steering_committee_screen.dart';
import 'package:seicho_app/screens/manage_training_material_screen.dart';
import 'screens/flash_news_screen.dart';
import 'screens/manage_best_practices_screen.dart';
import 'screens/module_selection_screen.dart';
import 'screens/super_admin_dashboard.dart';
import 'screens/org_admin_dashboard.dart';
import 'screens/zone_leader_dashboard.dart';
import 'screens/zone_member_dashboard.dart';
import 'screens/viewer_dashboard.dart';
import 'screens/manage_5s_tasks_screen.dart';
import 'screens/create_5s_task_screen.dart';
import 'screens/approve_5s_task_screen.dart';
import 'screens/my_5s_tasks_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ModuleSelectionScreen(),
    ),
    GoRoute(
      path: '/super-admin-dashboard',
      builder: (context, state) => const SuperAdminDashboard(),
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
        return const AddZoneScreen();
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
        return ManageMembersScreen(zoneName: zoneName);
      },
    ),
    GoRoute(
      path: '/manage-red-tags',
      builder: (BuildContext context, GoRouterState state) {
        return const ManageRedTagsScreen();
      },
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
      path: '/flash-news',
      builder: (context, state) => const FlashNewsScreen(),
    ),
    GoRoute(
      path: '/manage-best-practices',
      builder: (context, state) => const ManageBestPracticesScreen(),
    ),
    GoRoute(
      path: '/manage-5s-tasks',
      builder: (context, state) => const Manage5STasksScreen(),
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
  ],
); 