import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/session.dart';

/// Payment record (offline claim or verified online payment) and the super
/// admin's confirmation.
class OfflinePayment {
  final String id;
  final String orgId;
  final String type; // LICENCE | CLOUD_RENEWAL
  final String gateway; // OFFLINE | RAZORPAY
  final bool gatewayVerified;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final num amount; // amount due (server-side quote)
  final num? claimedAmount;
  final String? reference;
  final String? method;
  final DateTime? paidOn;
  final String? note;
  final String status; // CLAIMED | CONFIRMED | REJECTED
  final DateTime? claimedAt;
  final DateTime? confirmedAt;
  final num? confirmedAmount;
  final String? confirmedReference;
  final String? confirmedByEmail;
  final String? rejectReason;
  final String? orgName;
  final String? orgEmail;
  final String? orgPhone;
  final bool amountMismatch;

  const OfflinePayment({
    required this.id,
    required this.orgId,
    required this.type,
    this.gateway = 'OFFLINE',
    this.gatewayVerified = false,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.amount,
    this.claimedAmount,
    this.reference,
    this.method,
    this.paidOn,
    this.note,
    required this.status,
    this.claimedAt,
    this.confirmedAt,
    this.confirmedAmount,
    this.confirmedReference,
    this.confirmedByEmail,
    this.rejectReason,
    this.orgName,
    this.orgEmail,
    this.orgPhone,
    this.amountMismatch = false,
  });

  bool get isLicence => type == 'LICENCE';
  bool get isClaimed => status == 'CLAIMED';
  bool get isOnline => gateway == 'RAZORPAY';
  String get typeLabel => isLicence ? 'Lifetime licence' : 'Cloud renewal (1 year)';
  String get methodLabel => isOnline ? 'Online (Razorpay)' : (paymentMethodLabels[method] ?? method ?? '');

  factory OfflinePayment.fromJson(Map<String, dynamic> j) => OfflinePayment(
        id: (j['id'] ?? '').toString(),
        orgId: (j['orgId'] ?? '').toString(),
        type: (j['type'] ?? 'LICENCE').toString(),
        gateway: (j['gateway'] ?? 'OFFLINE').toString(),
        gatewayVerified: j['gatewayVerified'] == true,
        razorpayOrderId: j['razorpayOrderId']?.toString(),
        razorpayPaymentId: j['razorpayPaymentId']?.toString(),
        amount: num.tryParse(j['amount']?.toString() ?? '') ?? 0,
        claimedAmount: num.tryParse(j['claimedAmount']?.toString() ?? ''),
        reference: j['reference']?.toString(),
        method: j['method']?.toString(),
        paidOn: DateTime.tryParse(j['paidOn']?.toString() ?? ''),
        note: j['note']?.toString(),
        status: (j['status'] ?? '').toString(),
        claimedAt: DateTime.tryParse(j['claimedAt']?.toString() ?? ''),
        confirmedAt: DateTime.tryParse(j['confirmedAt']?.toString() ?? ''),
        confirmedAmount: num.tryParse(j['confirmedAmount']?.toString() ?? ''),
        confirmedReference: j['confirmedReference']?.toString(),
        confirmedByEmail: j['confirmedByEmail']?.toString(),
        rejectReason: j['rejectReason']?.toString(),
        orgName: j['orgName']?.toString(),
        orgEmail: j['orgEmail']?.toString(),
        orgPhone: j['orgPhone']?.toString(),
        amountMismatch: j['amountMismatch'] == true,
      );
}

/// `GET /licence/quote`: what the organisation owes and how to pay.
class LicenceQuote {
  final String orgId;
  final String orgName;
  final String planCode; // FREE | LIFETIME
  final bool isLicensed;
  final DateTime? licencePurchasedAt;
  final num? licenceAmount;
  final num licencePrice; // effective price (special or list)
  final num listPrice;
  final num cloudPerYear;
  final bool isPaused;
  final String? pauseReason; // TRIAL_ENDED | CLOUD_EXPIRED | MANUAL
  final bool approved;
  final DateTime? cloudValidUntil;
  final bool isSubscriptionActive;
  final String? dueType; // LICENCE | CLOUD_RENEWAL | null
  final num amountDue;
  final String paymentInstructions;
  final OfflinePayment? pendingClaim;
  final List<OfflinePayment> payments;
  final bool onlinePaymentEnabled;
  final String? razorpayKeyId;
  final bool onlineTestMode;

  const LicenceQuote({
    required this.orgId,
    required this.orgName,
    required this.planCode,
    required this.isLicensed,
    this.licencePurchasedAt,
    this.licenceAmount,
    required this.licencePrice,
    required this.listPrice,
    required this.cloudPerYear,
    required this.isPaused,
    this.pauseReason,
    required this.approved,
    this.cloudValidUntil,
    required this.isSubscriptionActive,
    this.dueType,
    required this.amountDue,
    required this.paymentInstructions,
    this.pendingClaim,
    this.payments = const [],
    this.onlinePaymentEnabled = false,
    this.razorpayKeyId,
    this.onlineTestMode = false,
  });

  bool get hasSpecialPrice => licencePrice != listPrice;
  bool get somethingDue => dueType != null;
  String get dueLabel => dueType == 'CLOUD_RENEWAL' ? 'Yearly cloud charge' : 'One-time lifetime licence';

  factory LicenceQuote.fromJson(Map<String, dynamic> j) {
    final pending = j['pendingClaim'];
    final payments = j['payments'];
    final online = j['onlinePayment'] is Map ? Map<String, dynamic>.from(j['onlinePayment'] as Map) : const <String, dynamic>{};
    return LicenceQuote(
      onlinePaymentEnabled: online['enabled'] == true,
      razorpayKeyId: online['keyId']?.toString(),
      onlineTestMode: online['testMode'] == true,
      orgId: (j['orgId'] ?? '').toString(),
      orgName: (j['orgName'] ?? '').toString(),
      planCode: (j['planCode'] ?? 'FREE').toString(),
      isLicensed: j['isLicensed'] == true,
      licencePurchasedAt: DateTime.tryParse(j['licencePurchasedAt']?.toString() ?? ''),
      licenceAmount: num.tryParse(j['licenceAmount']?.toString() ?? ''),
      licencePrice: num.tryParse(j['licencePrice']?.toString() ?? '') ?? 10000,
      listPrice: num.tryParse(j['listPrice']?.toString() ?? '') ?? 10000,
      cloudPerYear: num.tryParse(j['cloudPerYear']?.toString() ?? '') ?? 1000,
      isPaused: j['isPaused'] == true,
      pauseReason: j['pauseReason']?.toString(),
      approved: j['approved'] != false,
      cloudValidUntil: DateTime.tryParse(j['cloudValidUntil']?.toString() ?? ''),
      isSubscriptionActive: j['isSubscriptionActive'] == true,
      dueType: j['dueType']?.toString(),
      amountDue: num.tryParse(j['amountDue']?.toString() ?? '') ?? 0,
      paymentInstructions: (j['paymentInstructions'] ?? '').toString(),
      pendingClaim: pending is Map ? OfflinePayment.fromJson(Map<String, dynamic>.from(pending)) : null,
      payments: payments is List
          ? payments.whereType<Map>().map((e) => OfflinePayment.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
    );
  }
}

/// Organisation registered directly (no trial) and waiting for its first offline payment.
class AwaitingPaymentOrg {
  final String orgId;
  final String orgName;
  final String? unitName;
  final String? adminName;
  final String? adminEmail;
  final String? adminPhone;
  final num licencePrice;
  final DateTime? createdAt;

  const AwaitingPaymentOrg({
    required this.orgId,
    required this.orgName,
    this.unitName,
    this.adminName,
    this.adminEmail,
    this.adminPhone,
    required this.licencePrice,
    this.createdAt,
  });

  factory AwaitingPaymentOrg.fromJson(Map<String, dynamic> j) => AwaitingPaymentOrg(
        orgId: (j['orgId'] ?? '').toString(),
        orgName: (j['orgName'] ?? 'N/A').toString(),
        unitName: j['unitName']?.toString(),
        adminName: j['adminName']?.toString(),
        adminEmail: j['adminEmail']?.toString(),
        adminPhone: j['adminPhone']?.toString(),
        licencePrice: num.tryParse(j['licencePrice']?.toString() ?? '') ?? 10000,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? ''),
      );
}

/// Razorpay order created by the backend for the amount due.
class OnlineOrder {
  final String paymentId; // our payment row id
  final String type;
  final num amount;
  final int amountPaise;
  final String currency;
  final String razorpayOrderId;
  final String razorpayKeyId;
  final bool testMode;
  final String? orgName;
  final String? orgEmail;
  final String? orgPhone;

  const OnlineOrder({
    required this.paymentId,
    required this.type,
    required this.amount,
    required this.amountPaise,
    required this.currency,
    required this.razorpayOrderId,
    required this.razorpayKeyId,
    required this.testMode,
    this.orgName,
    this.orgEmail,
    this.orgPhone,
  });

  factory OnlineOrder.fromJson(Map<String, dynamic> j) => OnlineOrder(
        paymentId: (j['paymentId'] ?? '').toString(),
        type: (j['type'] ?? 'LICENCE').toString(),
        amount: num.tryParse(j['amount']?.toString() ?? '') ?? 0,
        amountPaise: int.tryParse(j['amountPaise']?.toString() ?? '') ?? 0,
        currency: (j['currency'] ?? 'INR').toString(),
        razorpayOrderId: (j['razorpayOrderId'] ?? '').toString(),
        razorpayKeyId: (j['razorpayKeyId'] ?? '').toString(),
        testMode: j['testMode'] == true,
        orgName: j['orgName']?.toString(),
        orgEmail: j['orgEmail']?.toString(),
        orgPhone: j['orgPhone']?.toString(),
      );

  /// Options for `Razorpay.open`.
  Map<String, dynamic> checkoutOptions({String? description}) => {
        'key': razorpayKeyId,
        'amount': amountPaise,
        'currency': currency,
        'order_id': razorpayOrderId,
        'name': 'diGi5S',
        'description': description ?? (type == 'CLOUD_RENEWAL' ? 'Cloud service - 1 year' : 'Lifetime licence'),
        'prefill': {
          if ((orgPhone ?? '').isNotEmpty) 'contact': orgPhone,
          if ((orgEmail ?? '').isNotEmpty) 'email': orgEmail,
        },
        'theme': {'color': '#012060'},
      };
}

/// Client + super-admin calls for the licence flow. An offline claim or a
/// verified online (Razorpay) payment both end up waiting for the super admin's
/// confirmation.
class LicenceService {
  LicenceService(this._api);
  final ApiClient _api;

  // ---- online payment (logged-in org admin) --------------------------------

  Future<OnlineOrder> initiateOnlinePayment({String? orgId}) async {
    final res = await _api.post('/licence/payment/initiate', body: {if (orgId != null) 'orgId': orgId});
    return OnlineOrder.fromJson(res.map);
  }

  Future<OfflinePayment> completeOnlinePayment({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    String? orgId,
  }) async {
    final res = await _api.put('/licence/payment/complete', body: {
      if (orgId != null) 'orgId': orgId,
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });
    return OfflinePayment.fromJson(res.map);
  }

  // ---- organisation admin -------------------------------------------------

  Future<LicenceQuote> quote({String? orgId}) async {
    final res = await _api.get('/licence/quote', query: orgId == null ? null : {'orgId': orgId});
    return LicenceQuote.fromJson(res.map);
  }

  Future<OfflinePayment> submitClaim({
    required num amount,
    required String reference,
    required String method,
    DateTime? paidOn,
    String? note,
    String? orgId,
  }) async {
    final res = await _api.post('/licence/payment-claim', body: {
      if (orgId != null) 'orgId': orgId,
      'amount': amount,
      'reference': reference.trim(),
      'method': method,
      if (paidOn != null) 'paidOn': _dateOnly(paidOn),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return OfflinePayment.fromJson(res.map);
  }

  Future<void> withdrawClaim(String id, {String? orgId}) =>
      _api.delete('/licence/payment-claim/$id', query: orgId == null ? null : {'orgId': orgId});

  // ---- super admin --------------------------------------------------------

  Future<List<OfflinePayment>> payments({String? status}) async {
    final res = await _api.get('/admin/payments', query: status == null ? null : {'status': status});
    final list = res.map['payments'];
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => OfflinePayment.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<AwaitingPaymentOrg>> awaitingPayment() async {
    final res = await _api.get('/admin/payments/awaiting');
    final list = res.map['organisations'];
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => AwaitingPaymentOrg.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Double-verified confirmation. With [offlinePaymentId] the typed [amount]
  /// and [reference] must match the client's claim; without it (walk-in) the
  /// amount must equal the organisation's quoted price. [confirm] must be true.
  Future<Map<String, dynamic>> confirmPayment({
    required String orgId,
    String? offlinePaymentId,
    String? type,
    required num amount,
    required String reference,
    String? method,
    DateTime? paidOn,
    String? note,
    required bool confirm,
  }) async {
    final res = await _api.post('/admin/payments/confirm', body: {
      'orgId': orgId,
      if (offlinePaymentId != null) 'offlinePaymentId': offlinePaymentId,
      if (type != null) 'type': type,
      'amount': amount,
      'reference': reference.trim(),
      if (method != null) 'method': method,
      if (paidOn != null) 'paidOn': _dateOnly(paidOn),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'confirm': confirm,
    });
    return res.map;
  }

  Future<void> rejectPayment(String id, {required String reason}) =>
      _api.post('/admin/payments/$id/reject', body: {'reason': reason.trim()});

  Future<num> setLicencePrice(String orgId, num? price) async {
    final res = await _api.put('/admin/organisations/$orgId/licence-price', body: {'licencePrice': price});
    return num.tryParse(res.map['licencePrice']?.toString() ?? '') ?? price ?? 10000;
  }

  Future<LicenceQuote> licenceStatus(String orgId) async {
    final res = await _api.get('/admin/organisations/$orgId/licence');
    return LicenceQuote.fromJson(res.map);
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final licenceServiceProvider = Provider((ref) => LicenceService(ref.read(apiClientProvider)));

/// Quote for the signed-in user's organisation (org admins). Super admins get
/// [null] here; they use [licenceStatusProvider] with an explicit org id.
final licenceQuoteProvider = FutureProvider.autoDispose<LicenceQuote?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || (user.orgId ?? '').isEmpty) return null;
  return ref.read(licenceServiceProvider).quote();
});

final licenceStatusProvider = FutureProvider.autoDispose.family<LicenceQuote, String>((ref, orgId) {
  return ref.read(licenceServiceProvider).licenceStatus(orgId);
});

final claimedPaymentsProvider = FutureProvider.autoDispose<List<OfflinePayment>>((ref) {
  return ref.read(licenceServiceProvider).payments(status: 'CLAIMED');
});

final paymentHistoryProvider = FutureProvider.autoDispose<List<OfflinePayment>>((ref) async {
  final all = await ref.read(licenceServiceProvider).payments();
  return all.where((p) => !p.isClaimed).toList();
});

final awaitingPaymentProvider = FutureProvider.autoDispose<List<AwaitingPaymentOrg>>((ref) {
  return ref.read(licenceServiceProvider).awaitingPayment();
});

const paymentMethods = ['BANK', 'UPI', 'CHEQUE', 'CASH', 'OTHER'];
const paymentMethodLabels = {
  'BANK': 'Bank transfer (NEFT / RTGS / IMPS)',
  'UPI': 'UPI',
  'CHEQUE': 'Cheque',
  'CASH': 'Cash',
  'OTHER': 'Other',
  'RAZORPAY': 'Online (Razorpay)',
};
