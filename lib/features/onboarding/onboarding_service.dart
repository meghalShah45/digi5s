import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../licence/licence_service.dart';

/// Lifetime-licence quote from `POST /paid-subscription/pricing`, the result of
/// `POST /paid-subscription/register`, or the lookup by email. Payment is online
/// (Razorpay); Seicho Consulting confirms it before the account is opened.
class LicenceOffer {
  final String? orgId;
  final String planName;
  final num licencePrice;
  final num cloudPerYear;
  final int cloudYearsIncluded;
  final num totalAmount;
  final String? adminEmail;
  final bool onlinePaymentEnabled;
  final String? orgName;
  final bool hasSpecialPrice;
  final String? pendingPaymentStatus; // CLAIMED when a payment already awaits confirmation
  final bool pendingPaymentIsOnline;

  const LicenceOffer({
    this.orgId,
    required this.planName,
    required this.licencePrice,
    required this.cloudPerYear,
    required this.cloudYearsIncluded,
    required this.totalAmount,
    this.adminEmail,
    this.onlinePaymentEnabled = false,
    this.orgName,
    this.hasSpecialPrice = false,
    this.pendingPaymentStatus,
    this.pendingPaymentIsOnline = false,
  });

  bool get awaitingConfirmation => pendingPaymentStatus == 'CLAIMED';

  factory LicenceOffer.fromJson(Map<String, dynamic> j) {
    num n(dynamic v, num d) => num.tryParse(v?.toString() ?? '') ?? d;
    final online = j['onlinePayment'] is Map ? Map<String, dynamic>.from(j['onlinePayment'] as Map) : const <String, dynamic>{};
    final pending = j['pendingPayment'] is Map ? Map<String, dynamic>.from(j['pendingPayment'] as Map) : null;
    return LicenceOffer(
      onlinePaymentEnabled: online['enabled'] == true,
      orgName: j['orgName']?.toString(),
      hasSpecialPrice: j['hasSpecialPrice'] == true,
      pendingPaymentStatus: pending?['status']?.toString(),
      pendingPaymentIsOnline: pending?['gateway'] == 'RAZORPAY',
      orgId: j['orgId']?.toString(),
      planName: (j['planName'] ?? 'diGi5S Lifetime Licence').toString(),
      licencePrice: n(j['licencePrice'], 10000),
      cloudPerYear: n(j['cloudPerYear'], 1000),
      cloudYearsIncluded: int.tryParse(j['cloudYearsIncluded']?.toString() ?? '') ?? 1,
      totalAmount: n(j['totalAmount'], 10000),
      adminEmail: j['adminEmail']?.toString(),
    );
  }
}

class RegistrationDetails {
  final String orgName;
  final String unitName;
  final String adminName;
  final String adminPhone;
  final String adminEmail;
  final int? employeeCount; // informational only (no manpower-based pricing)

  const RegistrationDetails({
    required this.orgName,
    required this.unitName,
    required this.adminName,
    required this.adminPhone,
    required this.adminEmail,
    this.employeeCount,
  });

  Map<String, dynamic> toPaidJson() => {
        'orgName': orgName.trim(),
        'unitName': unitName.trim(),
        'adminName': adminName.trim(),
        'adminPhone': adminPhone.trim(),
        'adminEmail': adminEmail.trim().toLowerCase(),
        if (employeeCount != null) 'employeeCount': employeeCount,
      };

  Map<String, dynamic> toFreeTrialJson() => {
        'orgName': orgName.trim(),
        'unitName': unitName.trim(),
        'adminName': adminName.trim(),
        'adminPhone': adminPhone.trim(),
        'adminEmail': adminEmail.trim().toLowerCase(),
        if (employeeCount != null) 'numEmployees': employeeCount,
      };
}

class OnboardingService {
  OnboardingService(this._api);
  final ApiClient _api;

  /// Emails a 6-digit code (valid 30 minutes).
  Future<String> startFreeTrial(RegistrationDetails d) async {
    final res = await _api.post('/free-trial/start', body: d.toFreeTrialJson());
    return res.message;
  }

  /// Creates the organisation and its admin; credentials are emailed.
  Future<String> verifyFreeTrial({required String adminEmail, required String code}) async {
    final res = await _api.post('/free-trial/verify', body: {
      'adminEmail': adminEmail.trim().toLowerCase(),
      'verificationCode': code.trim(),
    });
    return res.message;
  }

  /// Price preview; also checks the email/phone are not already registered.
  Future<LicenceOffer> pricing(RegistrationDetails d) async {
    final res = await _api.post('/paid-subscription/pricing', body: d.toPaidJson());
    return LicenceOffer.fromJson(res.map);
  }

  /// Registers the organisation (unapproved). The client then pays online; login
  /// details are emailed after Seicho Consulting confirms the payment.
  Future<LicenceOffer> register(RegistrationDetails d) async {
    final res = await _api.post('/paid-subscription/register', body: d.toPaidJson());
    return LicenceOffer.fromJson(res.map);
  }

  /// "Already registered?": current quote (incl. any special price) for a
  /// direct signup that has not paid yet, found by its admin email.
  Future<LicenceOffer> lookupRegistration(String adminEmail) async {
    final res = await _api.post('/paid-subscription/payment/lookup', body: {'adminEmail': adminEmail.trim().toLowerCase()});
    return LicenceOffer.fromJson(res.map);
  }

  /// Razorpay order for a freshly registered organisation (not logged in yet).
  Future<OnlineOrder> initiateSignupPayment({required String orgId, required String adminEmail}) async {
    final res = await _api.post('/paid-subscription/payment/initiate', body: {'orgId': orgId, 'adminEmail': adminEmail.trim().toLowerCase()});
    return OnlineOrder.fromJson(res.map);
  }

  /// Verifies the checkout result; the super admin then confirms and the
  /// credentials are emailed.
  Future<OfflinePayment> completeSignupPayment({
    required String orgId,
    required String adminEmail,
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await _api.put('/paid-subscription/payment/complete', body: {
      'orgId': orgId,
      'adminEmail': adminEmail.trim().toLowerCase(),
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });
    return OfflinePayment.fromJson(res.map);
  }
}

final onboardingServiceProvider = Provider((ref) => OnboardingService(ref.read(apiClientProvider)));
