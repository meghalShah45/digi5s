import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/colors.dart';

class ZoneMemberDashboard extends StatelessWidget {
  const ZoneMemberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Zone Member Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0.5,
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
          'My Tasks',
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.task_alt,
          onTap: () => context.push('/my-tasks'),
        ),
        buildGridItem(
          context,
          'My Trainings',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.school_outlined,
          onTap: () => context.push('/my-trainings'),
        ),
        buildGridItem(
          context,
          'News & Updates',
          const Color(0xFFE8EAF6),
          const Color(0xFF283593),
          Icons.newspaper_outlined,
          onTap: () => context.push('/news-updates'),
        ),
        buildGridItem(
          context,
          'Training Material',
          const Color(0xFFE0F2F1),
          const Color(0xFF00695C),
          Icons.menu_book_outlined,
          onTap: () => context.push('/training-material'),
        ),
        buildGridItem(
          context,
          'Best Practices',
          const Color(0xFFFFF3E0),
          const Color(0xFFEF6C00),
          Icons.star_outline,
          onTap: () => context.push('/best-practices'),
        ),
        buildGridItem(
          context,
          'My Progress',
          const Color(0xFFF3E5F5),
          const Color(0xFF7B1FA2),
          Icons.trending_up_outlined,
          onTap: () => context.push('/my-progress'),
        ),
        buildGridItem(
          context,
          'Flash News',
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          Icons.flash_on_outlined,
          onTap: () => context.push('/flash-news'),
        ),
        buildGridItem(
          context,
          'Help & Support',
          const Color(0xFFFCE4EC),
          const Color(0xFFC2185B),
          Icons.help_outline,
          onTap: () => context.push('/help-support'),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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