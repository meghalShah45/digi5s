import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/logout_button.dart';
import '../features/dashboard/dashboard_widgets.dart';
import '../theme/colors.dart';
import 'home_screen.dart' show buildGridItem;

class ZoneLeaderDashboard extends ConsumerWidget {
  const ZoneLeaderDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Zone Leader Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: true,
        actions: const [LogoutButton(color: AppColors.primary)],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => refreshDashboard(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const DashboardHeader(),
              const SizedBox(height: 16),
              const SubscriptionBanner(),
              const FlashNewsTicker(),
              const DashboardStats(),
              _buildMainGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.05,
      children: [
        buildGridItem(context, 'Manage 5S Tasks', const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.task_alt,
            onTap: () => context.push('/manage-5s-tasks')),
        buildGridItem(context, 'Manage Red Tags', const Color(0xFFFCE4EC), const Color(0xFFC2185B), Icons.label_outlined,
            onTap: () => context.push('/manage-red-tags')),
        buildGridItem(context, 'Perform Audit', const Color(0xFFF3E5F5), const Color(0xFF7B1FA2), Icons.assignment_outlined,
            onTap: () => context.push('/perform-audit')),
        buildGridItem(context, 'What is News', const Color(0xFFE8F5E9), const Color(0xFF2E7D32), Icons.newspaper_outlined,
            onTap: () => context.push('/what-is-news')),
        buildGridItem(context, '5S Training Material', const Color(0xFFE8EAF6), const Color(0xFF283593), Icons.school_outlined,
            onTap: () => context.push('/5s-training-material')),
        buildGridItem(context, 'Best Practices', const Color(0xFFE0F2F1), const Color(0xFF00695C), Icons.star_outline,
            onTap: () => context.push('/manage-best-practices')),
        buildGridItem(context, '5S Org. Structure', const Color(0xFFFFF3E0), const Color(0xFFEF6C00), Icons.account_tree_outlined,
            onTap: () => context.push('/manage-zone')),
        buildGridItem(context, 'Flash News', const Color(0xFFFFEBEE), const Color(0xFFC62828), Icons.flash_on_outlined,
            onTap: () => context.push('/flash-news')),
      ],
    );
  }
}
