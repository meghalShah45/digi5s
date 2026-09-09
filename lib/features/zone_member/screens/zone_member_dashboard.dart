import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../features/dashboard/dashboard_widgets.dart';
import '../../../screens/home_screen.dart' show buildGridItem;
import '../../../services/zone_service.dart';
import '../../../theme/colors.dart';

/// Name of the current user's zone (null when unassigned or on error).
final myZoneNameProvider = FutureProvider.autoDispose<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final zoneId = user?.zoneId;
  if (zoneId == null || zoneId.isEmpty) return null;
  try {
    return (await ZoneService().getZoneById(zoneId))?.zoneName;
  } catch (_) {
    return null;
  }
});

class ZoneMemberDashboard extends ConsumerWidget {
  const ZoneMemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoneName = ref.watch(myZoneNameProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Zone Member Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: true,
        actions: const [LogoutButton(color: AppColors.primary)],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myZoneNameProvider);
            await refreshDashboard(ref);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              DashboardHeader(
                trailing: zoneName == null
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(zoneName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              const SubscriptionBanner(),
              const FlashNewsTicker(),
              const DashboardStats(showRedTags: false),
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
        buildGridItem(context, 'My Tasks', const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.task_alt,
            onTap: () => context.push('/zone-member/my-tasks')),
        buildGridItem(context, 'Red Tags', const Color(0xFFFCE4EC), const Color(0xFFC2185B), Icons.label_outlined,
            onTap: () => context.push('/manage-red-tags')),
        buildGridItem(context, 'What Is News', const Color(0xFFE8F5E9), const Color(0xFF2E7D32), Icons.newspaper_outlined,
            onTap: () => context.push('/what-is-news')),
        buildGridItem(context, 'Training Material', const Color(0xFFE8EAF6), const Color(0xFF283593), Icons.school_outlined,
            onTap: () => context.push('/5s-training-material')),
        buildGridItem(context, 'Best Practices', const Color(0xFFE0F2F1), const Color(0xFF00695C), Icons.star_outline,
            onTap: () => context.push('/manage-best-practices')),
        buildGridItem(context, 'Flash News', const Color(0xFFFFEBEE), const Color(0xFFC62828), Icons.flash_on_outlined,
            onTap: () => context.push('/flash-news')),
      ],
    );
  }
}
