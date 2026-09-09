import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session.dart';

/// Red-tag and task counts for an organisation, optionally narrowed to a zone.
class DashboardCounts {
  final int redTagsPending;
  final int redTagsApproved;
  final int redTagsRejected;
  final int redTagsTotal;
  final int tasksPending;
  final int tasksInProgress;
  final int tasksPendingApproval;
  final int tasksCompleted;
  final int tasksRejected;
  final int tasksTotal;

  const DashboardCounts({
    this.redTagsPending = 0,
    this.redTagsApproved = 0,
    this.redTagsRejected = 0,
    this.redTagsTotal = 0,
    this.tasksPending = 0,
    this.tasksInProgress = 0,
    this.tasksPendingApproval = 0,
    this.tasksCompleted = 0,
    this.tasksRejected = 0,
    this.tasksTotal = 0,
  });

  static DashboardCounts fromLists(List<Map<String, dynamic>> redTags, List<Map<String, dynamic>> tasks) {
    int count(List<Map<String, dynamic>> l, Set<String> statuses) =>
        l.where((e) => statuses.contains((e['status'] ?? '').toString().toUpperCase())).length;
    return DashboardCounts(
      redTagsPending: count(redTags, {'PENDING', 'VERIFY'}),
      redTagsApproved: count(redTags, {'APPROVED', 'COMPLETED'}),
      redTagsRejected: count(redTags, {'REJECTED'}),
      redTagsTotal: redTags.length,
      tasksPending: count(tasks, {'PENDING'}),
      tasksInProgress: count(tasks, {'WORK-IN-PROGRESS', 'VERIFY'}),
      tasksPendingApproval: count(tasks, {'PENDING_APPROVAL'}),
      tasksCompleted: count(tasks, {'COMPLETED'}),
      tasksRejected: count(tasks, {'REJECTED'}),
      tasksTotal: tasks.length,
    );
  }
}

/// Subscription state from `GET /organisation-subscriptions/org/{orgId}`.
class SubscriptionStatus {
  final bool exists;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? adminUserLimit;
  final int? membersLimit;
  final num? pricePerYear;

  const SubscriptionStatus({
    required this.exists,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.adminUserLimit,
    this.membersLimit,
    this.pricePerYear,
  });

  static const none = SubscriptionStatus(exists: false, isActive: false);

  int? get daysLeft => endDate == null ? null : endDate!.difference(DateTime.now()).inDays;
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get isFree => (pricePerYear ?? 0) == 0;

  /// Active subscription ending within 30 days.
  bool get isExpiringSoon => isActive && !isExpired && (daysLeft ?? 999) <= 30;

  /// Not active but not past its end date: the organisation is paused.
  bool get looksPaused => exists && !isActive && !isExpired;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> j) => SubscriptionStatus(
        exists: true,
        isActive: j['isSubscriptionActive'] == true,
        startDate: DateTime.tryParse(j['startDate']?.toString() ?? ''),
        endDate: DateTime.tryParse(j['endDate']?.toString() ?? ''),
        adminUserLimit: _int(j['adminUserLimit']),
        membersLimit: _int(j['membersLimit']),
        pricePerYear: num.tryParse(j['pricePerYear']?.toString() ?? ''),
      );

  static int? _int(dynamic v) => v == null ? null : int.tryParse(v.toString());
}

class DashboardRepository {
  DashboardRepository(this._api);
  final ApiClient _api;

  Future<DashboardCounts> counts({required String orgId, String? zoneId}) async {
    final results = await Future.wait([
      _api.get('/redtags/org/$orgId'),
      _api.get('/tasks/org/$orgId'),
    ]);
    var redTags = results[0].list;
    var tasks = results[1].list;
    if (zoneId != null && zoneId.isNotEmpty) {
      redTags = redTags.where((e) => e['zoneId']?.toString() == zoneId).toList();
      tasks = tasks.where((e) => e['zoneId']?.toString() == zoneId).toList();
    }
    return DashboardCounts.fromLists(redTags, tasks);
  }

  /// Tasks assigned to one user (zone member view).
  Future<DashboardCounts> countsForUser({required String orgId, required String userId}) async {
    final res = await _api.post('/tasks/detailsByUserId', body: {'orgId': orgId, 'userId': userId});
    return DashboardCounts.fromLists(const [], res.list);
  }

  Future<SubscriptionStatus> subscription(String orgId) async {
    final res = await _api.get('/organisation-subscriptions/org/$orgId');
    final rows = res.list;
    if (rows.isEmpty) return SubscriptionStatus.none;
    // Prefer the active row, else the one ending last.
    rows.sort((a, b) {
      final aa = a['isSubscriptionActive'] == true ? 1 : 0;
      final bb = b['isSubscriptionActive'] == true ? 1 : 0;
      if (aa != bb) return bb - aa;
      return (b['endDate'] ?? '').toString().compareTo((a['endDate'] ?? '').toString());
    });
    return SubscriptionStatus.fromJson(rows.first);
  }
}

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(ref.read(apiClientProvider)));

/// Counts for the current user's org, narrowed to their zone for zone roles.
final dashboardCountsProvider = FutureProvider.autoDispose<DashboardCounts>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.orgId == null || user.orgId!.isEmpty) return const DashboardCounts();
  final repo = ref.read(dashboardRepositoryProvider);
  if (user.isZoneMember) return repo.countsForUser(orgId: user.orgId!, userId: user.id);
  return repo.counts(orgId: user.orgId!, zoneId: user.isZoneLeader ? user.zoneId : null);
});

final subscriptionStatusProvider = FutureProvider.autoDispose<SubscriptionStatus>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.orgId == null || user.orgId!.isEmpty) return SubscriptionStatus.none;
  return ref.read(dashboardRepositoryProvider).subscription(user.orgId!);
});
