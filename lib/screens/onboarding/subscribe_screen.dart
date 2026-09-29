import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/api/api_client.dart';
import '../../features/licence/licence_service.dart';
import '../../features/onboarding/onboarding_service.dart';
import '../../theme/colors.dart';
import 'registration_form.dart';

/// Lifetime licence signup without a trial:
/// register -> price -> confirm registration -> pay online (Razorpay).
/// Either way Seicho Consulting confirms the payment and emails the login details.
class SubscribeScreen extends ConsumerStatefulWidget {
  const SubscribeScreen({super.key});

  @override
  ConsumerState<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends ConsumerState<SubscribeScreen> {
  bool _busy = false;
  RegistrationDetails? _details;
  LicenceOffer? _offer;
  LicenceOffer? _registered;
  bool _paidOnline = false;
  bool _lookupMode = false;
  final _lookupEmail = TextEditingController();
  Razorpay? _razorpay;
  OnlineOrder? _order;

  @override
  void dispose() {
    _razorpay?.clear();
    _lookupEmail.dispose();
    super.dispose();
  }

  /// "Already registered? Complete your payment": find the registration by
  /// email and reuse the registered card (online payment).
  Future<void> _lookup() async {
    final email = _lookupEmail.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _snack('Enter the email you registered with', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final offer = await ref.read(onboardingServiceProvider).lookupRegistration(email);
      setState(() {
        _details = RegistrationDetails(orgName: offer.orgName ?? '', unitName: '', adminName: '', adminPhone: '', adminEmail: email);
        _registered = offer;
        _paidOnline = false;
      });
    } on ApiException catch (e) {
      _snack(e.statusCode == 429 ? 'Too many attempts. Please try again later.' : e.message, error: true);
    } catch (_) {
      _snack('Could not find the registration. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payOnline() async {
    final reg = _registered;
    final d = _details;
    if (reg == null || reg.orgId == null || d == null) return;
    setState(() => _busy = true);
    try {
      final order = await ref.read(onboardingServiceProvider).initiateSignupPayment(orgId: reg.orgId!, adminEmail: d.adminEmail);
      _order = order;
      _razorpay ??= Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onOnlineSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onOnlineError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
      _razorpay!.open(order.checkoutOptions(description: 'diGi5S lifetime licence'));
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Could not start the payment. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onOnlineSuccess(PaymentSuccessResponse r) async {
    final order = _order;
    final reg = _registered;
    final d = _details;
    if (order == null || reg == null || d == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(onboardingServiceProvider).completeSignupPayment(
            orgId: reg.orgId!,
            adminEmail: d.adminEmail,
            paymentId: order.paymentId,
            razorpayOrderId: r.orderId ?? order.razorpayOrderId,
            razorpayPaymentId: r.paymentId ?? '',
            razorpaySignature: r.signature ?? '',
          );
      setState(() => _paidOnline = true);
    } on ApiException catch (e) {
      _snack('Payment made but could not be recorded: ${e.message}. Contact Seicho Consulting with payment id ${r.paymentId ?? ''}.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onOnlineError(PaymentFailureResponse r) {
    _snack(r.message?.isNotEmpty == true ? r.message! : 'Payment was not completed.', error: true);
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
      final offer = await ref.read(onboardingServiceProvider).pricing(d);
      setState(() {
        _details = d;
        _offer = offer;
      });
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Could not fetch pricing. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    final d = _details;
    if (d == null) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(onboardingServiceProvider).register(d);
      setState(() => _registered = r);
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Could not complete the registration. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            if (_registered != null)
              _RegisteredCard(
                offer: _registered!,
                adminEmail: _details?.adminEmail ?? '',
                paidOnline: _paidOnline,
                busy: _busy,
                onPayOnline: _registered!.onlinePaymentEnabled && !_paidOnline ? _payOnline : null,
                onDone: () => context.go('/get-started'),
              )
            else if (_offer == null)
              RegistrationForm(
                heading: 'Subscription Registration',
                icon: Icons.subscriptions,
                submitLabel: 'Show Pricing',
                busy: _busy,
                onSubmit: _showPricing,
              )
            else
              _PricingCard(
                offer: _offer!,
                busy: _busy,
                onRegister: _register,
                onBack: () => setState(() => _offer = null),
              ),
            if (_registered == null) ...[
              const SizedBox(height: 20),
              if (!_lookupMode)
                Center(
                  child: TextButton.icon(
                    onPressed: _busy ? null : () => setState(() => _lookupMode = true),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Already registered? Complete your payment', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )
              else
                _LookupCard(
                  controller: _lookupEmail,
                  busy: _busy,
                  onFind: _lookup,
                  onClose: () => setState(() => _lookupMode = false),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _inr(num n) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);

class _PricingCard extends StatelessWidget {
  const _PricingCard({required this.offer, required this.busy, required this.onRegister, required this.onBack});
  final LicenceOffer offer;
  final bool busy;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 17 : 15))),
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
          Text(offer.planName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.primary)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('One price for any team size. Unlimited members.', style: TextStyle(color: Colors.grey.shade700)),
          ),
          const Divider(height: 28),
          row('One-time lifetime licence', _inr(offer.licencePrice)),
          row('Cloud service included', '${offer.cloudYearsIncluded} year'),
          row('Cloud charge thereafter', '${_inr(offer.cloudPerYear)} / year'),
          const Divider(height: 28),
          row('Amount payable now', _inr(offer.totalAmount), bold: true),
          const SizedBox(height: 12),
          Text(
            'After you register you pay online (UPI, card, net banking or wallet, secured by Razorpay). '
            'Seicho Consulting confirms your payment and emails your login details.',
            style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: busy ? null : onRegister,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.how_to_reg_outlined),
              label: const Text('Register & get payment details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          TextButton(onPressed: busy ? null : onBack, child: const Text('Edit details')),
        ],
      ),
    );
  }
}

class _RegisteredCard extends StatelessWidget {
  const _RegisteredCard({
    required this.offer,
    required this.adminEmail,
    required this.paidOnline,
    required this.busy,
    required this.onPayOnline,
    required this.onDone,
  });
  final LicenceOffer offer;
  final String adminEmail;
  final bool paidOnline;
  final bool busy;
  final VoidCallback? onPayOnline;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    if (offer.awaitingConfirmation) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFF3EEF8), borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(offer.pendingPaymentIsOnline ? Icons.verified : Icons.hourglass_top, color: const Color(0xFF4CAF50), size: 56),
            const SizedBox(height: 12),
            const Text('Payment awaiting confirmation', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              offer.pendingPaymentIsOnline
                  ? 'Your online payment for ${offer.orgName ?? 'your organisation'} was received and verified. Seicho Consulting will confirm it and email your login details to $adminEmail.'
                  : 'A payment for ${offer.orgName ?? 'your organisation'} is already recorded and awaiting confirmation by Seicho Consulting. Your login details will be emailed to $adminEmail once it is confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Done', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
    if (paidOnline) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFF3EEF8), borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.verified, color: Color(0xFF4CAF50), size: 56),
            const SizedBox(height: 12),
            const Text('Payment received', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your online payment of ${_inr(offer.totalAmount)} was verified. Seicho Consulting will confirm it shortly and email your login details to $adminEmail.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Done', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }
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
          Icon(offer.orgName != null ? Icons.receipt_long : Icons.verified, color: const Color(0xFF4CAF50), size: 56),
          const SizedBox(height: 12),
          Text(offer.orgName != null ? 'Complete your payment' : 'Registration received',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (offer.orgName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(offer.orgName!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 16),
          Text('Amount payable: ${_inr(offer.totalAmount)}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
          if (offer.hasSpecialPrice)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Special price agreed with Seicho Consulting (list price ${_inr(10000)})',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 16),
          if (onPayOnline != null) ...[
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: busy ? null : onPayOnline,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_outline),
                label: Text('Pay ${_inr(offer.totalAmount)} online now', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            Text('UPI, cards, net banking and wallets via Razorpay.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(14)),
              child: const Text('Online payment is temporarily unavailable. Please try again later, or contact Seicho Consulting at digi5sapp@gmail.com.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
            ),
          const SizedBox(height: 8),
          Text(
            'Once Seicho Consulting confirms your payment, your login details will be emailed to $adminEmail. '
            'You can also pay later: Subscribe → "Already registered? Complete your payment".',
            style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Done', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LookupCard extends StatelessWidget {
  const _LookupCard({required this.controller, required this.busy, required this.onFind, required this.onClose});
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onFind;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEF8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Expanded(child: Text('Complete your payment', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
              IconButton(onPressed: busy ? null : onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Enter the admin email you registered with. We will show the amount due (including any special price agreed with Seicho Consulting) and the payment options.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onSubmitted: (_) => busy ? null : onFind(),
            decoration: InputDecoration(
              hintText: 'Organization Admin E-mail',
              prefixIcon: const Icon(Icons.email_outlined),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade500)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade500)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: busy ? null : onFind,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: const Text('Find my registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
