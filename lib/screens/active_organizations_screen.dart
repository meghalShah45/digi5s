import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../models/organization.dart';

class ActiveOrganizationsScreen extends StatelessWidget {
  const ActiveOrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy list of active organizations with plan info
    final orgs = [
      {
        'org': Organization(id: 'org1', name: 'Organization A', phone: '1234567890', email: 'a@org.com', address: '123 Main St'),
        'plan': 'Free Trial',
        'daysLeft': 10,
        'gst': '22AAAAA0000A1Z5',
        'pan': 'AAAAA0000A',
      },
      {
        'org': Organization(id: 'org2', name: 'Organization B', phone: '0987654321', email: 'b@org.com', address: '456 Side Ave'),
        'plan': 'Subscription',
        'daysLeft': null,
        'gst': '33BBBBB1111B2Z6',
        'pan': 'BBBBB1111B',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Organizations'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_business, color: AppColors.secondaryLight),
        label: const Text('Add Organization', style: TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold)),
        onPressed: () => context.push('/super-admin/add-organization'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  hintText: 'Search organizations...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: orgs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final entry = orgs[index];
                  final org = entry['org'] as Organization;
                  final plan = entry['plan'] as String;
                  final daysLeft = entry['daysLeft'] as int?;
                  final gst = entry['gst'] as String;
                  final pan = entry['pan'] as String;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
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
                                child: Text(org.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: plan == 'Free Trial' ? AppColors.warning : AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  plan,
                                  style: TextStyle(
                                    color: plan == 'Free Trial' ? Colors.black : AppColors.secondaryLight,
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
                              Text(org.phone, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(width: 18),
                              Icon(Icons.email, color: AppColors.textSecondary, size: 18),
                              const SizedBox(width: 6),
                              Text(org.email, style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Row(
                          //   children: [
                          //     Icon(Icons.receipt_long, color: AppColors.textSecondary, size: 18),
                          //     const SizedBox(width: 6),
                          //     Text('GST: $gst', style: const TextStyle(color: AppColors.textSecondary)),
                          //     const SizedBox(width: 18),
                          //     Icon(Icons.credit_card, color: AppColors.textSecondary, size: 18),
                          //     const SizedBox(width: 6),
                          //     Text('PAN: $pan', style: const TextStyle(color: AppColors.textSecondary)),
                          //   ],
                          // ),
                          if (plan == 'Free Trial' && daysLeft != null) ...[
                            const SizedBox(height: 6),
                            Text('Days Left: $daysLeft', style: const TextStyle(color: AppColors.warning)),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 