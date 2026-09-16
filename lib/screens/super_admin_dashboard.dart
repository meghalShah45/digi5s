import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/session.dart';
import '../core/widgets/logout_button.dart';
import '../features/dashboard/dashboard_widgets.dart';
import '../features/organisations/organisation_service.dart';
import '../theme/colors.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentUserProvider);
    final acting = session?.isActingInOrg ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => LogoutButton.confirmAndLogout(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(organisationsProvider);
            ref.invalidate(pendingSubscriptionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const ActingOrgBanner(),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.9,
                children: [
                  _Tile(
                    title: 'Manage Active\nOrganizations',
                    bg: const Color(0xFFFCE4EC),
                    fg: const Color(0xFFC2185B),
                    icon: Icons.manage_accounts_outlined,
                    onTap: () => context.push('/super-admin/active-organizations'),
                  ),
                  _Tile(
                    title: 'Manage\nAudit',
                    bg: const Color(0xFFF3E5F5),
                    fg: const Color(0xFF7B1FA2),
                    icon: Icons.assignment_outlined,
                    onTap: () {
                      if (acting) {
                        context.push('/manage-audit');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Pick an organisation first, then choose "Work in this organisation".'),
                        ));
                        context.push('/super-admin/active-organizations');
                      }
                    },
                  ),
                  _Tile(
                    title: 'Paid\nSubscriptions\nManagement',
                    bg: const Color(0xFFE3F2FD),
                    fg: const Color(0xFF1565C0),
                    icon: Icons.credit_card_outlined,
                    onTap: () => context.push('/super-admin/pending-subscriptions'),
                  ),
                  if (acting)
                    _Tile(
                      title: 'Open\n${session!.actingOrgName ?? 'organisation'}',
                      bg: const Color(0xFFE8F5E9),
                      fg: const Color(0xFF2E7D32),
                      icon: Icons.login,
                      onTap: () => context.go('/org-admin-dashboard'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.bg, required this.fg, required this.icon, required this.onTap});
  final String title;
  final Color bg;
  final Color fg;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.fromLTRB(20, 22, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, size: 24, color: fg),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D), height: 1.25)),
          ],
        ),
      ),
    );
  }
}
