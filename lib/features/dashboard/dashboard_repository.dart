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
///
/// Since the single-price model (Sept 2026) the row also carries the licence
/// state: `planCode` (FREE trial / LIFETIME licence), `isPaused` + `pauseReason`
/// (TRIAL_ENDED / CLOUD_EXPIRED / MANUAL), what is due and any pending offline
/// payment claim.
class SubscriptionStatus {
  final bool exists;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? adminUserLimit;
  final int? membersLimit;
  final num? pricePerYear;
  final String planCode;
  final bool isLicensed;
  final bool isPaused;
  final String? pauseReason;
  final String? dueType;
  final num? amountDue;
  final num? licencePrice;
  final num? cloudPerYear;
  final bool hasPendingClaim;

  const SubscriptionStatus({
    required this.exists,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.adminUserLimit,
    this.membersLimit,
    this.pricePerYear,
    this.planCode = 'FREE',
    this.isLicensed = false,
    this.isPaused = false,
    this.pauseReason,
    this.dueType,
    this.amountDue,
    this.licencePrice,
    this.cloudPerYear,
    this.hasPendingClaim = false,
  });

  static const none = SubscriptionStatus(exists: false, isActive: false);

  bool get isTrialEnded => pauseReason == 'TRIAL_ENDED' || (!isLicensed && isExpired);
  bool get isCloudExpired => pauseReason == 'CLOUD_EXPIRED' || (isLicensed && isExpired);
  bool get isManuallyPaused => isPaused && pauseReason == 'MANUAL';

  int? get daysLeft => endDate == null ? null : endDate!.difference(DateTime.now()).inDays;
  /// The end date is inclusive (matches the backend's `endDate >= CURRENT_DATE`).
  bool get isExpired {
    if (endDate == null) return false;
    final now = DateTime.now();
    return endDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Mirrors the backend subscription guard: writes are refused unless there is an
  /// active subscription that hasn't passed its end date.
  bool get isReadOnly => isPaused || !(exists && isActive && !isExpired);
  bool get isFree => !isLicensed && (pricePerYear ?? 0) == 0;

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
        planCode: (j['planCode'] ?? (j['licencePurchasedAt'] != null ? 'LIFETIME' : 'FREE')).toString(),
        isLicensed: j['isLicensed'] == true || j['licencePurchasedAt'] != null,
        isPaused: j['isPaused'] == true,
        pauseReason: j['pauseReason']?.toString(),
        dueType: j['dueType']?.toString(),
        amountDue: num.tryParse(j['amountDue']?.toString() ?? ''),
        licencePrice: num.tryParse(j['licencePrice']?.toString() ?? ''),
        cloudPerYear: num.tryParse(j['cloudPerYear']?.toString() ?? ''),
        hasPendingClaim: j['pendingClaim'] is Map,
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

/// True when the signed-in user's organisation is read-only (expired, paused or
/// no subscription). Super admins are never read-only. False while loading, so
/// controls don't flicker; the backend enforces it regardless.
final orgReadOnlyProvider = Provider.autoDispose<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isSuperAdmin) return false;
  final status = ref.watch(subscriptionStatusProvider).valueOrNull;
  return status?.isReadOnly ?? false;
});
