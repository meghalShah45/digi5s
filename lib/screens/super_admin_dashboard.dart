import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _ActiveOrgsPreview(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business, color: AppColors.secondaryLight),
        label: const Text('Add Organization', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/super-admin/add-organization'),
      ),
    );
  }
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