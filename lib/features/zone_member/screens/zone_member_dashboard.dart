import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/colors.dart';
import '../../../providers/user_provider.dart';

class ZoneMemberDashboard extends ConsumerWidget {
  const ZoneMemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfo = ref.watch(userProvider);
    
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
              // Zone information header
              if (userInfo != null && userInfo.zoneId.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Zone',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zone ID: ${userInfo.zoneId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
          onTap: () => context.push('/zone-member/my-tasks'),
        ),
        buildGridItem(
          context,
          'Manage Red Tags',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.label_outlined,
          onTap: () => context.push('/manage-red-tags'),
        ),
        buildGridItem(
          context,
          'What Is News',
          const Color(0xFFE8EAF6),
          const Color(0xFF283593),
          Icons.newspaper_outlined,
          onTap: () => context.push('/what-is-news'),
        ),
        buildGridItem(
          context,
          'Training Material',
          const Color(0xFFE0F2F1),
          const Color(0xFF00695C),
          Icons.menu_book_outlined,
          onTap: () => context.push('/manage-training-material'),
        ),
        buildGridItem(
          context,
          'Best Practices',
          const Color(0xFFFFF3E0),
          const Color(0xFFEF6C00),
          Icons.star_outline,
          onTap: () => context.push('/manage-best-practices'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ],
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