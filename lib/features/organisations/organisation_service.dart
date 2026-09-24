import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session.dart';

class Organisation {
  final String id;
  final String name;
  final String? addressLine1;
  final String? addressLine2;
  final String? contactNo;
  final String? email;
  final String? gstNo;
  final String? pancardNo;
  final bool approved;
  final bool isPaused;
  final String? pauseReason; // TRIAL_ENDED | CLOUD_EXPIRED | MANUAL
  final DateTime? pausedAt;
  final DateTime? pauseExpiresAt;
  final DateTime? licencePurchasedAt;
  final num? licenceAmount;
  final num? licencePrice; // special price set by the super admin; null = list price
  final DateTime? createdAt;

  const Organisation({
    required this.id,
    required this.name,
    this.addressLine1,
    this.addressLine2,
    this.contactNo,
    this.email,
    this.gstNo,
    this.pancardNo,
    required this.approved,
    required this.isPaused,
    this.pauseReason,
    this.pausedAt,
    this.pauseExpiresAt,
    this.licencePurchasedAt,
    this.licenceAmount,
    this.licencePrice,
    this.createdAt,
  });

  String get address => [addressLine1, addressLine2].where((s) => s != null && s.trim().isNotEmpty).join(', ');
  bool get isLicensed => licencePurchasedAt != null;
  bool get isTrialEnded => pauseReason == 'TRIAL_ENDED';
  bool get isCloudExpired => pauseReason == 'CLOUD_EXPIRED';

  String get pauseLabel {
    switch (pauseReason) {
      case 'TRIAL_ENDED':
        return 'Trial ended - awaiting licence payment';
      case 'CLOUD_EXPIRED':
        return 'Cloud charge due - awaiting payment';
      case 'MANUAL':
        return 'Paused by super admin';
      default:
        return 'Paused';
    }
  }

  factory Organisation.fromJson(Map<String, dynamic> j) => Organisation(
        id: j['id'].toString(),
        name: (j['name'] ?? '').toString(),
        addressLine1: j['addressLine1']?.toString(),
        addressLine2: j['addressLine2']?.toString(),
        contactNo: j['contactNo']?.toString(),
        email: j['email']?.toString(),
        gstNo: j['gstNo']?.toString(),
        pancardNo: j['pancardNo']?.toString(),
        approved: j['approved'] != false,
        isPaused: j['isPaused'] == true,
        pauseReason: j['pauseReason']?.toString(),
        pausedAt: DateTime.tryParse(j['pausedAt']?.toString() ?? ''),
        pauseExpiresAt: DateTime.tryParse(j['pauseExpiresAt']?.toString() ?? ''),
        licencePurchasedAt: DateTime.tryParse(j['licencePurchasedAt']?.toString() ?? ''),
        licenceAmount: num.tryParse(j['licenceAmount']?.toString() ?? ''),
        licencePrice: num.tryParse(j['licencePrice']?.toString() ?? ''),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );
}

/// One row of `GET /organisation-subscriptions` (all orgs, with computed fields).
class OrgSubscriptionRow {
  final String orgId;
  final String? subscriptionName;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isFree;
  final int? daysLeft;
  final num? pricePerYear;

  const OrgSubscriptionRow({
    required this.orgId,
    this.subscriptionName,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.isFree,
    this.daysLeft,
    this.pricePerYear,
  });

  String get planLabel => isFree ? 'Free trial' : (subscriptionName ?? 'Lifetime licence');
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());

  factory OrgSubscriptionRow.fromJson(Map<String, dynamic> j) => OrgSubscriptionRow(
        orgId: (j['orgId'] ?? '').toString(),
        subscriptionName: j['SubscriptionName']?.toString(),
        startDate: DateTime.tryParse(j['startDate']?.toString() ?? ''),
        endDate: DateTime.tryParse(j['endDate']?.toString() ?? ''),
        isActive: j['isSubscriptionActive'] == true,
        isFree: j['isFree'] == true || (num.tryParse(j['pricePerYear']?.toString() ?? '') ?? 0) == 0,
        daysLeft: int.tryParse(j['daysLeft']?.toString() ?? ''),
        pricePerYear: num.tryParse(j['pricePerYear']?.toString() ?? ''),
      );
}

class OrganisationService {
  OrganisationService(this._api);
  final ApiClient _api;

  Future<List<Organisation>> list() async {
    final res = await _api.get('/organisations');
    final items = res.list.map(Organisation.fromJson).toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<Organisation?> get(String id) async {
    final res = await _api.get('/organisations/$id');
    final m = res.map;
    return m.isEmpty ? null : Organisation.fromJson(m);
  }

  /// `POST /organisations` (super admin) — creates the org, its admin user and a
  /// 15-day free trial. Returns `{ organisation, adminCredentials: { email, password }, adminUserId }`.
  /// [licencePrice] sets a special lifetime-licence price for this client.
  Future<Map<String, dynamic>> create({
    required String name,
    required String email,
    String? contactNo,
    String? addressLine1,
    String? addressLine2,
    String? gstNo,
    String? pancardNo,
    num? licencePrice,
  }) async {
    final res = await _api.post('/organisations', body: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      if (contactNo != null && contactNo.trim().isNotEmpty) 'contactNo': contactNo.trim(),
      if (addressLine1 != null && addressLine1.trim().isNotEmpty) 'addressLine1': addressLine1.trim(),
      if (addressLine2 != null && addressLine2.trim().isNotEmpty) 'addressLine2': addressLine2.trim(),
      if (gstNo != null && gstNo.trim().isNotEmpty) 'gstNo': gstNo.trim().toUpperCase(),
      if (pancardNo != null && pancardNo.trim().isNotEmpty) 'pancardNo': pancardNo.trim().toUpperCase(),
      if (licencePrice != null) 'licencePrice': licencePrice,
    });
    return res.map;
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    await _api.put('/organisations/$id', body: fields);
  }

  Future<void> setApproved(String id, bool approved) async {
    await _api.put('/organisations/status/$id', body: {'approved': approved});
  }

  Future<void> pause(String id, {DateTime? expiresAt}) async {
    await _api.put('/organisations/$id/pause', body: {
      if (expiresAt != null) 'expiresAt': expiresAt.toUtc().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> unpause(String id, {bool extendSubscription = true}) async {
    final res = await _api.put('/organisations/$id/unpause', body: {'extendSubscription': extendSubscription});
    return res.map;
  }

  Future<void> delete(String id) => _api.delete('/organisations/$id');

  /// Subscription rows for every organisation, keyed by orgId (active row wins).
  Future<Map<String, OrgSubscriptionRow>> subscriptionsByOrg() async {
    final res = await _api.get('/organisation-subscriptions');
    final out = <String, OrgSubscriptionRow>{};
    for (final row in res.list.map(OrgSubscriptionRow.fromJson)) {
      final existing = out[row.orgId];
      if (existing == null || (!existing.isActive && row.isActive) ||
          (existing.isActive == row.isActive && (row.endDate ?? DateTime(0)).isAfter(existing.endDate ?? DateTime(0)))) {
        out[row.orgId] = row;
      }
    }
    return out;
  }

  Future<Map<String, int>> superAdminCounts() async {
    final res = await _api.post('/dashboard/super-admin');
    final m = res.map;
    return {
      'free': int.tryParse(m['freeSubscriptionCount']?.toString() ?? '') ?? 0,
      'paid': int.tryParse(m['paidSubscriptionCount']?.toString() ?? '') ?? 0,
    };
  }
}

final organisationServiceProvider = Provider((ref) => OrganisationService(ref.read(apiClientProvider)));

final organisationsProvider = FutureProvider.autoDispose<List<Organisation>>((ref) {
  return ref.read(organisationServiceProvider).list();
});

final orgSubscriptionsProvider = FutureProvider.autoDispose<Map<String, OrgSubscriptionRow>>((ref) {
  return ref.read(organisationServiceProvider).subscriptionsByOrg();
});

final organisationProvider = FutureProvider.autoDispose.family<Organisation?, String>((ref, id) async {
  final list = ref.watch(organisationsProvider).valueOrNull;
  final hit = list?.where((o) => o.id == id).firstOrNull;
  if (hit != null) return hit;
  return ref.read(organisationServiceProvider).get(id);
});

final superAdminCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.read(organisationServiceProvider).superAdminCounts();
});

/// Convenience for screens: the current session's org id, if any.
String? currentOrgId(WidgetRef ref) => ref.watch(currentUserProvider)?.orgId;
