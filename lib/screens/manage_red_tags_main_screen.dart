import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

class ManageRedTagsMainScreen extends StatelessWidget {
  const ManageRedTagsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final tags = [
      {'item': 'Broken Chair', 'qty': '2', 'action': 'Repair', 'status': 'pending'},
      {'item': 'Old Computer', 'qty': '1', 'action': 'Dispose', 'status': 'approved'},
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Red Tags'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final t = tags[i];
          final isPending = t['status'] == 'pending';
          final statusColor = isPending ? AppColors.warning.withOpacity(0.2) : AppColors.success.withOpacity(0.2);
          final statusText = isPending ? 'Decision Pending' : 'Approved';
          return Container(
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.label_important, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(t['item']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Qty: ${t['qty']}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Action: ${t['action']!}', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending ? AppColors.warning : AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: isPending ? AppColors.textPrimary : AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/create-red-tag'),
        child: const Icon(Icons.add, color: AppColors.secondaryLight),
      ),
    );
  }
} 