import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/session.dart';
import '../../theme/colors.dart';
import '../flash_news/flash_news.dart';
import 'dashboard_repository.dart';

/// "Hey, <name>" header with role line.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key, this.trailing});
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final first = (user?.fullName ?? '').trim().split(' ').first;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first.isEmpty ? 'Welcome' : 'Hey, $first',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D), height: 1.2),
              ),
              if (user != null)
                Text(_roleLabel(user.role), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }

  static String _roleLabel(String role) {
    switch (role) {
      case Roles.superAdmin:
        return 'Super Admin';
      case Roles.orgAdmin:
        return 'Organisation Admin';
      case Roles.zoneLeader:
        return 'Zone Leader';
      case Roles.zoneMember:
        return 'Zone Member';
      case Roles.viewer:
        return 'Viewer';
      default:
        return role;
    }
  }
}

/// Subscription warning strip. Hidden when everything is fine.
class SubscriptionBanner extends ConsumerWidget {
  const SubscriptionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    if (status == null) return const SizedBox.shrink();

    String? text;
    Color color = Colors.orange.shade800;
    IconData icon = Icons.warning_amber_rounded;
    if (!status.exists) {
      text = 'No active subscription found for your organisation.';
    } else if (status.isExpired) {
      text = 'Your subscription expired on ${_fmt(status.endDate)}. Please renew to continue.';
      color = Colors.red.shade700;
      icon = Icons.error_outline;
    } else if (status.looksPaused) {
      text = 'Your organisation is currently paused. Contact Seicho Consulting for help.';
      color = Colors.blueGrey.shade700;
      icon = Icons.pause_circle_outline;
    } else if (status.isExpiringSoon) {
      final d = status.daysLeft ?? 0;
      text = status.isFree
          ? 'Your free trial ends in $d day${d == 1 ? '' : 's'} (${_fmt(status.endDate)}).'
          : 'Your subscription ends in $d day${d == 1 ? '' : 's'} (${_fmt(status.endDate)}).';
    }
    if (text == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  static String _fmt(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy').format(d.toLocal());
}

/// Scrolling strip of active flash news. Hidden when there is none.
class FlashNewsTicker extends ConsumerWidget {
  const FlashNewsTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(activeFlashNewsProvider).valueOrNull ?? const [];
    if (news.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () => context.push('/flash-news'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.flash_on, color: Color(0xFFC62828), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final n in news.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(n.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF7F0000), fontWeight: FontWeight.w500)),
                    ),
                  if (news.length > 3)
                    Text('+${news.length - 3} more', style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFC62828)),
          ],
        ),
      ),
    );
  }
}

/// Compact red-tag / task counters.
class DashboardStats extends ConsumerWidget {
  const DashboardStats({super.key, this.showRedTags = true});
  final bool showRedTags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardCountsProvider);
    final c = async.valueOrNull;
    final loading = async.isLoading && c == null;

    Widget tile(String label, int? value, Color color, {VoidCallback? onTap}) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  loading
                      ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                      : Text('${value ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          tile('Tasks\npending', c?.tasksPending, AppColors.primary, onTap: () => context.push('/manage-5s-tasks')),
          const SizedBox(width: 8),
          tile('Awaiting\napproval', c?.tasksPendingApproval, Colors.orange.shade800, onTap: () => context.push('/manage-5s-tasks')),
          const SizedBox(width: 8),
          tile('Tasks\ncompleted', c?.tasksCompleted, Colors.green.shade700, onTap: () => context.push('/manage-5s-tasks')),
          if (showRedTags) ...[
            const SizedBox(width: 8),
            tile('Red tags\nopen', c?.redTagsPending, const Color(0xFFC2185B), onTap: () => context.push('/manage-red-tags')),
          ],
        ],
      ),
    );
  }
}

/// Pull-to-refresh helper that invalidates the dashboard providers.
Future<void> refreshDashboard(WidgetRef ref) async {
  ref.invalidate(dashboardCountsProvider);
  ref.invalidate(subscriptionStatusProvider);
  ref.invalidate(orgFlashNewsProvider);
  await Future.wait([
    ref.read(dashboardCountsProvider.future),
    ref.read(subscriptionStatusProvider.future),
    ref.read(orgFlashNewsProvider.future),
  ]).catchError((_) => <Object>[]);
}
