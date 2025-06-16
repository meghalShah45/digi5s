import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import 'home_screen.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: AppColors.primary, size: 28),
            tooltip: 'Manage Super Admin Info',
            onPressed: () => context.push('/super-admin/manage-superadmin-info'),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildMainGrid(context),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // _buildSpeedDial(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Widget _buildMainGrid(BuildContext context) {
  return GridView.count(
    crossAxisCount: 2,
    mainAxisSpacing: 15,
    crossAxisSpacing: 15,
    childAspectRatio: 1.05,
    children: [
      buildGridItem(
        context,
        'Manage Zone &\nmembers',
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
        Icons.groups_outlined,
        onTap: () => context.push('/manage-zone'),
      ),
      buildGridItem(
        context,
        'Manage Active Organizations',
        const Color(0xFFFCE4EC),
        const Color(0xFFC2185B),
        Icons.manage_accounts_outlined,
        onTap: () => context.push('/super-admin/active-organizations'),
      ),
      buildGridItem(
        context,
        'Manage\nAudit',
        const Color(0xFFF3E5F5),
        const Color(0xFF7B1FA2),
        Icons.assignment_outlined,
        onTap: () => context.push('/manage-audit'),
      ),
    ],
  );
}


class _ActiveOrgsPreview extends StatelessWidget {
  const _ActiveOrgsPreview();

  @override
  Widget build(BuildContext context) {
    final orgs = [
      {
        'name': 'Organization A',
        'plan': 'Free Trial',
        'daysLeft': 10,
        'phone': '1234567890',
        'email': 'a@org.com',
      },
      {
        'name': 'Organization B',
        'plan': 'Subscription',
        'daysLeft': null,
        'phone': '0987654321',
        'email': 'b@org.com',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Organizations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...orgs.map((org) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(org['name'].toString()!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: org['plan'] == 'Free Trial' ? AppColors.warning : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        org['plan'].toString()!,
                        style: TextStyle(
                          color: org['plan'] == 'Free Trial' ? Colors.black : AppColors.secondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 6),
                    Text(org['phone'].toString()!, style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 18),
                    Icon(Icons.email, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 6),
                    Text(org['email'].toString()!, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
                if (org['plan'] == 'Free Trial' && org['daysLeft'] != null) ...[
                  const SizedBox(height: 6),
                  Text('Days Left: ${org['daysLeft']}', style: const TextStyle(color: AppColors.warning)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.pause, color: AppColors.warning),
                        label: const Text('Pause', style: TextStyle(color: AppColors.warning)),
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.warning),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.stop, color: AppColors.secondaryLight),
                        label: const Text('Stop', style: TextStyle(color: AppColors.secondaryLight)),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}