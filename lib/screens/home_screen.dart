import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_widgets.dart';

/// Organisation admin home.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
        buildGridItem(context, 'Manage Zone &\nmembers', const Color(0xFFE8F5E9), const Color(0xFF2E7D32),
            Icons.groups_outlined, onTap: () => context.push('/manage-zone')),
        buildGridItem(context, 'Manage Red\nTags', const Color(0xFFFCE4EC), const Color(0xFFC2185B),
            Icons.label_outlined, onTap: () => context.push('/manage-red-tags')),
        buildGridItem(context, '5S\nTasks', const Color(0xFFE0F7FA), const Color(0xFF00838F),
            Icons.task_alt_outlined, onTap: () => context.push('/manage-5s-tasks')),
        buildGridItem(context, 'Manage\nManual', const Color(0xFFE3F2FD), const Color(0xFF1565C0),
            Icons.menu_book_outlined, onTap: () => context.push('/manage-manual')),
        buildGridItem(context, 'Manage\nAudit', const Color(0xFFF3E5F5), const Color(0xFF7B1FA2),
            Icons.assignment_outlined, onTap: () => context.push('/manage-audit')),
        buildGridItem(context, 'Manage\nNews', const Color(0xFFFFF3E0), const Color(0xFFEF6C00),
            Icons.newspaper_outlined, onTap: () => context.push('/manage-news')),
        buildGridItem(context, 'Manage Training\nMaterial', const Color(0xFFE8EAF6), const Color(0xFF283593),
            Icons.school_outlined, onTap: () => context.push('/manage-training-material')),
        buildGridItem(context, 'Upload Best\nPractices', const Color(0xFFE0F2F1), const Color(0xFF00695C),
            Icons.upload_file_outlined, onTap: () => context.push('/manage-best-practices')),
        buildGridItem(context, 'Flash\nNews', const Color(0xFFFFEBEE), const Color(0xFFC62828),
            Icons.flash_on_outlined, onTap: () => context.push('/flash-news')),
      ],
    );
  }
}

Widget buildGridItem(
  BuildContext context,
  String title,
  Color bgColor,
  Color iconColor,
  IconData icon, {
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2D2D2D), height: 1.4),
          ),
        ],
      ),
    ),
  );
}

extension ColorExtension on Color {
  Color get darker => Color.fromARGB(alpha, (red * 0.7).round(), (green * 0.7).round(), (blue * 0.7).round());
}
