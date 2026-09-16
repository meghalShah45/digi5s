import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';

/// Plan quote returned by `POST /paid-subscription/pricing`.
class PricingQuote {
  final String subscriptionId;
  final String planName;
  final String? description;
  final int? membersLimit;
  final int? adminUserLimit;
  final num annualPrice;
  final num onboardingFee;
  final num total;
  final int employeeCount;

  const PricingQuote({
    required this.subscriptionId,
    required this.planName,
    this.description,
    this.membersLimit,
    this.adminUserLimit,
    required this.annualPrice,
    required this.onboardingFee,
    required this.total,
    required this.employeeCount,
  });

  factory PricingQuote.fromJson(Map<String, dynamic> j) {
    final sub = (j['subscription'] is Map) ? Map<String, dynamic>.from(j['subscription'] as Map) : <String, dynamic>{};
    final br = (j['breakdown'] is Map) ? Map<String, dynamic>.from(j['breakdown'] as Map) : <String, dynamic>{};
    num n(dynamic v) => num.tryParse(v?.toString() ?? '') ?? 0;
    return PricingQuote(
      subscriptionId: (sub['id'] ?? '').toString(),
      planName: (sub['name'] ?? sub['SubscriptionName'] ?? 'Subscription').toString(),
      description: sub['description']?.toString(),
      membersLimit: int.tryParse(sub['membersLimit']?.toString() ?? ''),
      adminUserLimit: int.tryParse(sub['adminUserLimit']?.toString() ?? ''),
      annualPrice: n(br['annualPrice'] ?? sub['pricePerYear']),
      onboardingFee: n(br['onboardingFee'] ?? sub['onboardingPrice']),
      total: n(j['totalAmount'] ?? br['total']),
      employeeCount: int.tryParse(j['employeeCount']?.toString() ?? '') ?? 0,
    );
  }
}

/// Razorpay order created by `POST /paid-subscription/payment/initiate`.
class PaymentOrder {
  final String bookingId;
  final String razorpayOrderId;
  final String razorpayKeyId;
  final num totalAmount;

  const PaymentOrder({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.razorpayKeyId,
    required this.totalAmount,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> j) => PaymentOrder(
        bookingId: (j['bookingId'] ?? '').toString(),
        razorpayOrderId: (j['razorpayOrderId'] ?? '').toString(),
        razorpayKeyId: (j['razorpayKeyId'] ?? '').toString(),
        totalAmount: num.tryParse(j['totalAmount']?.toString() ?? '') ?? 0,
      );
}

class RegistrationDetails {
  final String orgName;
  final String unitName;
  final String adminName;
  final String adminPhone;
  final String adminEmail;
  final int employeeCount;

  const RegistrationDetails({
    required this.orgName,
    required this.unitName,
    required this.adminName,
    required this.adminPhone,
    required this.adminEmail,
    required this.employeeCount,
  });

  Map<String, dynamic> toPaidJson() => {
        'orgName': orgName.trim(),
        'unitName': unitName.trim(),
        'adminName': adminName.trim(),
        'adminPhone': adminPhone.trim(),
        'adminEmail': adminEmail.trim().toLowerCase(),
        'employeeCount': employeeCount,
      };

  Map<String, dynamic> toFreeTrialJson() => {
        'orgName': orgName.trim(),
        'unitName': unitName.trim(),
        'adminName': adminName.trim(),
        'adminPhone': adminPhone.trim(),
        'adminEmail': adminEmail.trim().toLowerCase(),
        'numEmployees': employeeCount,
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

  Future<PricingQuote> pricing(RegistrationDetails d) async {
    final res = await _api.post('/paid-subscription/pricing', body: d.toPaidJson());
    return PricingQuote.fromJson(res.map);
  }

  Future<PaymentOrder> initiatePayment(RegistrationDetails d, String subscriptionId) async {
    final res = await _api.post('/paid-subscription/payment/initiate', body: {
      ...d.toPaidJson(),
      'subscriptionId': subscriptionId,
    });
    return PaymentOrder.fromJson(res.map);
  }

  Future<Map<String, dynamic>> completePayment({
    required String bookingId,
    required String paymentId,
    required String orderId,
    required String signature,
    required num amount,
    num tax = 0,
  }) async {
    final res = await _api.put('/paid-subscription/payment/complete', body: {
      'bookingId': bookingId,
      'razorpayPaymentId': paymentId,
      'razorpayOrderId': orderId,
      'razorpaySignature': signature,
      'amount': amount,
      'tax': tax,
    });
    return res.map;
  }
}

final onboardingServiceProvider = Provider((ref) => OnboardingService(ref.read(apiClientProvider)));
