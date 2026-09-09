import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import '../core/widgets/logout_button.dart';

class ZoneLeaderDashboard extends StatelessWidget {
  const ZoneLeaderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Zone Leader Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: const [LogoutButton(color: AppColors.primary)],
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.push('/'),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: SafeArea(
        child: Padding(
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
      ),
    );
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
          'Manage 5S Tasks',
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.task_alt,
          onTap: () => context.push('/manage-5s-tasks'),
        ),
        buildGridItem(
          context,
          'Manage Red Tags',
          const Color(0xFFFCE4EC),
          const Color(0xFFC2185B),
          Icons.label_outlined,
          onTap: () => context.push('/manage-red-tags'),
        ),
        buildGridItem(
          context,
          'What is News',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.newspaper_outlined,
          onTap: () => context.push('/what-is-news'),
        ),
        buildGridItem(
          context,
          '5S Training Material',
          const Color(0xFFE8EAF6),
          const Color(0xFF283593),
          Icons.school_outlined,
          onTap: () => context.push('/5s-training-material'),
        ),
        buildGridItem(
          context,
          'Best Practices',
          const Color(0xFFE0F2F1),
          const Color(0xFF00695C),
          Icons.star_outline,
          onTap: () => context.push('/best-practices'),
        ),
        buildGridItem(
          context,
          '5S Org. Structure',
          const Color(0xFFFFF3E0),
          const Color(0xFFEF6C00),
          Icons.account_tree_outlined,
          onTap: () => context.push('/manage-zone'),
        ),
        buildGridItem(
          context,
          'Perform Audit',
          const Color(0xFFF3E5F5),
          const Color(0xFF7B1FA2),
          Icons.assignment_outlined,
          onTap: () => context.push('/perform-audit'),
        ),
        buildGridItem(
          context,
          'Flash News',
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          Icons.flash_on_outlined,
          onTap: () => context.push('/flash-news'),
        ),
      ],
    );
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
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2D2D),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 