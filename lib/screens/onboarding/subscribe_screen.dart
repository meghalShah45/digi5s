import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/api/api_client.dart';
import '../../features/onboarding/onboarding_service.dart';
import '../../theme/colors.dart';
import 'registration_form.dart';

/// Paid subscription: register -> pricing -> Razorpay -> awaiting approval.
class SubscribeScreen extends ConsumerStatefulWidget {
  const SubscribeScreen({super.key});

  @override
  ConsumerState<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends ConsumerState<SubscribeScreen> {
  bool _busy = false;
  RegistrationDetails? _details;
  PricingQuote? _quote;
  PaymentOrder? _order;
  Razorpay? _razorpay;

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }

  Future<void> _showPricing(RegistrationDetails d) async {
    setState(() => _busy = true);
    try {
      final quote = await ref.read(onboardingServiceProvider).pricing(d);
      setState(() {
        _details = d;
        _quote = quote;
      });
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Could not fetch pricing. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final d = _details;
    final q = _quote;
    if (d == null || q == null) return;
    setState(() => _busy = true);
    try {
      final order = await ref.read(onboardingServiceProvider).initiatePayment(d, q.subscriptionId);
      _order = order;
      _razorpay ??= Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
      _razorpay!.open({
        'key': order.razorpayKeyId,
        'amount': (order.totalAmount * 100).round(),
        'currency': 'INR',
        'order_id': order.razorpayOrderId,
        'name': 'diGi5S',
        'description': '${q.planName} subscription',
        'prefill': {'contact': d.adminPhone.trim(), 'email': d.adminEmail.trim()},
        'theme': {'color': '#012060'},
      });
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (e) {
      _snack('Could not start the payment. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    final order = _order;
    if (order == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(onboardingServiceProvider).completePayment(
            bookingId: order.bookingId,
            paymentId: r.paymentId ?? '',
            orderId: r.orderId ?? order.razorpayOrderId,
            signature: r.signature ?? '',
            amount: order.totalAmount,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.verified, color: Color(0xFF4CAF50), size: 48),
          title: const Text('Payment received'),
          content: const Text('Your organisation has been registered. Seicho Consulting will approve it shortly and email your login details.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
      if (mounted) context.go('/get-started');
    } on ApiException catch (e) {
      _snack('Payment captured but registration failed: ${e.message}. Contact support with booking ${order.bookingId}.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse r) {
    _snack(r.message?.isNotEmpty == true ? r.message! : 'Payment was not completed.', error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Subscribe'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            if (_quote == null)
              RegistrationForm(
                heading: 'Subscription Registration',
                icon: Icons.subscriptions,
                submitLabel: 'Show Pricing',
                busy: _busy,
                onSubmit: _showPricing,
              )
            else
              _PricingCard(
                quote: _quote!,
                busy: _busy,
                onPay: _pay,
                onBack: () => setState(() => _quote = null),
              ),
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.quote, required this.busy, required this.onPay, required this.onBack});
  final PricingQuote quote;
  final bool busy;
  final VoidCallback onPay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 17 : 15)),
              Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 20 : 15, color: bold ? AppColors.primary : const Color(0xFF1F1F1F))),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF8),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primary, size: 32),
              SizedBox(width: 14),
              Expanded(child: Text('Your Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          Text(quote.planName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.primary)),
          if (quote.description != null && quote.description!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(quote.description!, style: TextStyle(color: Colors.grey.shade700))),
          const Divider(height: 28),
          row('Employees requested', '${quote.employeeCount}'),
          if (quote.membersLimit != null) row('Members included', '${quote.membersLimit}'),
          if (quote.adminUserLimit != null) row('Admin users', '${quote.adminUserLimit}'),
          row('Annual price', inr.format(quote.annualPrice)),
          row('One-time onboarding', inr.format(quote.onboardingFee)),
          const Divider(height: 28),
          row('Total payable', inr.format(quote.total), bold: true),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: busy ? null : onPay,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_outline),
              label: const Text('Proceed to Payment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          TextButton(onPressed: busy ? null : onBack, child: const Text('Edit details')),
        ],
      ),
    );
  }
}
