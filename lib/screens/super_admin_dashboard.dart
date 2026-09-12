import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session.dart';
import '../core/widgets/logout_button.dart';
import '../features/dashboard/dashboard_widgets.dart';
import '../features/organisations/organisation_service.dart';
import '../theme/colors.dart';
import 'home_screen.dart' show buildGridItem;

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(superAdminCountsProvider);
    ref.invalidate(pendingSubscriptionsProvider);
    ref.invalidate(organisationsProvider);
    await Future.wait([
      ref.read(superAdminCountsProvider.future),
      ref.read(pendingSubscriptionsProvider.future),
      ref.read(organisationsProvider.future),
    ]).catchError((_) => <Object>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(superAdminCountsProvider).valueOrNull;
    final pending = ref.watch(pendingSubscriptionsProvider).valueOrNull?.length;
    final orgs = ref.watch(organisationsProvider).valueOrNull;
    final session = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Super Admin'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: true,
        actions: const [LogoutButton(color: AppColors.primary)],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const DashboardHeader(),
              const SizedBox(height: 16),
              const ActingOrgBanner(),
              Row(
                children: [
                  _stat('Orgs', orgs?.length, AppColors.primary, () => context.push('/super-admin/active-organizations')),
                  const SizedBox(width: 8),
                  _stat('Free\ntrials', counts?['free'], Colors.teal, () => context.push('/super-admin/active-organizations')),
                  const SizedBox(width: 8),
                  _stat('Paid', counts?['paid'], Colors.green.shade700, () => context.push('/super-admin/active-organizations')),
                  const SizedBox(width: 8),
                  _stat('Pending', pending, Colors.orange.shade800, () => context.push('/super-admin/pending-subscriptions')),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.05,
                children: [
                  buildGridItem(context, 'Organisations', const Color(0xFFFCE4EC), const Color(0xFFC2185B),
                      Icons.business_outlined, onTap: () => context.push('/super-admin/active-organizations')),
                  buildGridItem(context, 'Pending\napprovals', const Color(0xFFFFF3E0), const Color(0xFFEF6C00),
                      Icons.approval_outlined, onTap: () => context.push('/super-admin/pending-subscriptions')),
                  buildGridItem(context, 'New\norganisation', const Color(0xFFE8F5E9), const Color(0xFF2E7D32),
                      Icons.add_business_outlined, onTap: () => context.push('/super-admin/add-organization')),
                  if (session?.isActingInOrg ?? false)
                    buildGridItem(context, 'Open\n${session!.actingOrgName ?? 'organisation'}', const Color(0xFFE3F2FD),
                        const Color(0xFF1565C0), Icons.login, onTap: () => context.go('/org-admin-dashboard')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int? value, Color color, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                value == null
                    ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                    : Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
      );
}
