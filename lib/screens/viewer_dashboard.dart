import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_widgets.dart';
import 'base_dashboard_screen.dart';
import 'home_screen.dart' show buildGridItem;

/// Read-only role: can browse organisation content but change nothing.
class ViewerDashboard extends ConsumerWidget {
  const ViewerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseDashboardScreen(
      title: 'Viewer Dashboard',
      body: RefreshIndicator(
        onRefresh: () => refreshDashboard(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const DashboardHeader(),
            const SizedBox(height: 16),
            const SubscriptionBanner(),
            const FlashNewsTicker(),
            const DashboardStats(),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.05,
              children: [
                buildGridItem(context, 'Red Tags', const Color(0xFFFCE4EC), const Color(0xFFC2185B), Icons.label_outlined,
                    onTap: () => context.push('/manage-red-tags')),
                buildGridItem(context, '5S Tasks', const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.task_alt,
                    onTap: () => context.push('/approve-5s-task')),
                buildGridItem(context, 'News', const Color(0xFFE8F5E9), const Color(0xFF2E7D32), Icons.newspaper_outlined,
                    onTap: () => context.push('/what-is-news')),
                buildGridItem(context, 'Manuals', const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.menu_book_outlined,
                    onTap: () => context.push('/manage-manual')),
                buildGridItem(context, 'Training Material', const Color(0xFFE8EAF6), const Color(0xFF283593), Icons.school_outlined,
                    onTap: () => context.push('/5s-training-material')),
                buildGridItem(context, 'Best Practices', const Color(0xFFE0F2F1), const Color(0xFF00695C), Icons.star_outline,
                    onTap: () => context.push('/manage-best-practices')),
                buildGridItem(context, 'Zones & Members', const Color(0xFFFFF3E0), const Color(0xFFEF6C00), Icons.account_tree_outlined,
                    onTap: () => context.push('/manage-zone')),
                buildGridItem(context, 'Flash News', const Color(0xFFFFEBEE), const Color(0xFFC62828), Icons.flash_on_outlined,
                    onTap: () => context.push('/flash-news')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
