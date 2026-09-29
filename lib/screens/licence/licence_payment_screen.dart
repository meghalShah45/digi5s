import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/api/api_client.dart';
import '../../features/dashboard/dashboard_repository.dart';
import '../../features/licence/licence_service.dart';
import '../../theme/colors.dart';

/// Organisation admin: what is due (lifetime licence or yearly cloud charge)
/// and the Razorpay payment. Payment is online only; the organisation stays
/// read-only until Seicho Consulting confirms the verified payment.
class LicencePaymentScreen extends ConsumerStatefulWidget {
  const LicencePaymentScreen({super.key});

  @override
  ConsumerState<LicencePaymentScreen> createState() => _LicencePaymentScreenState();
}

class _LicencePaymentScreenState extends ConsumerState<LicencePaymentScreen> {
  bool _busy = false;
  Razorpay? _razorpay;
  OnlineOrder? _order;

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _payOnline() async {
    setState(() => _busy = true);
    try {
      final order = await ref.read(licenceServiceProvider).initiateOnlinePayment();
      _order = order;
      _razorpay ??= Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onOnlineSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onOnlineError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
      _razorpay!.open(order.checkoutOptions());
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
    if (order == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(licenceServiceProvider).completeOnlinePayment(
            paymentId: order.paymentId,
            razorpayOrderId: r.orderId ?? order.razorpayOrderId,
            razorpayPaymentId: r.paymentId ?? '',
            razorpaySignature: r.signature ?? '',
          );
      _snack('Payment received and verified. Seicho Consulting will confirm it shortly.');
      await _refresh();
    } on ApiException catch (e) {
      _snack('Payment made but could not be recorded: ${e.message}. Contact Seicho Consulting with payment id ${r.paymentId ?? ''}.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onOnlineError(PaymentFailureResponse r) {
    _snack(r.message?.isNotEmpty == true ? r.message! : 'Payment was not completed.', error: true);
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(licenceQuoteProvider);
    ref.invalidate(subscriptionStatusProvider);
    await ref.read(licenceQuoteProvider.future).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(licenceQuoteProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Licence & payment'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text(e is ApiException ? e.message : 'Could not load licence details')),
            Center(child: TextButton(onPressed: _refresh, child: const Text('Retry'))),
          ]),
          data: (q) {
            if (q == null) return const Center(child: Text('No organisation on this account'));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(q: q),
                const SizedBox(height: 12),
                if (q.pendingClaim != null)
                  _PendingClaimCard(claim: q.pendingClaim!)
                else if (q.somethingDue) ...[
                  if (q.onlinePaymentEnabled)
                    _OnlinePayCard(q: q, busy: _busy, onPay: _payOnline)
                  else
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.orange.shade800),
                        title: const Text('Online payment is temporarily unavailable'),
                        subtitle: const Text('Please try again later, or contact Seicho Consulting at digi5sapp@gmail.com.'),
                      ),
                    ),
                ] else
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: const Text('Nothing to pay right now'),
                      subtitle: Text(q.cloudValidUntil == null
                          ? 'Your licence is active.'
                          : 'Cloud service valid until ${DateFormat('d MMM yyyy').format(q.cloudValidUntil!.toLocal())}. '
                              'The yearly cloud charge of ₹${_inr(q.cloudPerYear)} becomes payable 30 days before that date.'),
                    ),
                  ),
                if (q.payments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _HistoryCard(payments: q.payments),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

String _inr(num n) => NumberFormat.decimalPattern('en_IN').format(n);

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.q});
  final LicenceQuote q;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');
    String status;
    Color color;
    if (q.pauseReason == 'TRIAL_ENDED') {
      status = 'Free trial ended - read-only';
      color = Colors.red.shade700;
    } else if (q.pauseReason == 'CLOUD_EXPIRED') {
      status = 'Cloud charge due - read-only';
      color = Colors.red.shade700;
    } else if (q.isPaused) {
      status = 'Paused by Seicho Consulting';
      color = Colors.blueGrey;
    } else if (!q.isLicensed) {
      status = 'Free trial';
      color = Colors.orange.shade800;
    } else {
      status = 'Lifetime licence active';
      color = Colors.green.shade700;
    }
    Widget row(String l, String? v) => v == null || v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(width: 130, child: Text(l, style: TextStyle(color: Colors.grey.shade600))),
              Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.orgName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            const Divider(height: 20),
            row('Plan', q.isLicensed ? 'diGi5S Lifetime Licence' : 'Free trial'),
            if (q.isLicensed) row('Licensed on', q.licencePurchasedAt == null ? null : df.format(q.licencePurchasedAt!.toLocal())),
            row(q.isLicensed ? 'Cloud valid until' : 'Trial ends', q.cloudValidUntil == null ? null : df.format(q.cloudValidUntil!.toLocal())),
            if (!q.isLicensed) row('Lifetime licence', '₹${_inr(q.licencePrice)}${q.hasSpecialPrice ? ' (special price; list ₹${_inr(q.listPrice)})' : ''}'),
            row('Cloud charge', '₹${_inr(q.cloudPerYear)} / year${q.isLicensed ? '' : ' (first year included)'}'),
            if (q.somethingDue) row('Due now', '${q.dueLabel}: ₹${_inr(q.amountDue)}'),
          ],
        ),
      ),
    );
  }
}

class _OnlinePayCard extends StatelessWidget {
  const _OnlinePayCard({required this.q, required this.busy, required this.onPay});
  final LicenceQuote q;
  final bool busy;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(Icons.bolt, color: Colors.green.shade800),
              const SizedBox(width: 8),
              Expanded(child: Text('Pay ₹${_inr(q.amountDue)} online', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              if (q.onlineTestMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                  child: const Text('TEST MODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                ),
            ]),
            const SizedBox(height: 6),
            Text('UPI, cards, net banking and wallets via Razorpay. The payment is verified automatically; Seicho Consulting then confirms it and your organisation is reactivated.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700, minimumSize: const Size.fromHeight(50)),
              onPressed: busy ? null : onPay,
              icon: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_outline),
              label: Text('Pay ₹${_inr(q.amountDue)} with Razorpay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingClaimCard extends StatelessWidget {
  const _PendingClaimCard({required this.claim});
  final OfflinePayment claim;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(claim.isOnline ? Icons.verified : Icons.hourglass_top, color: claim.isOnline ? Colors.green.shade800 : Colors.blue.shade800),
              const SizedBox(width: 8),
              Expanded(child: Text(claim.isOnline ? 'Paid online - awaiting confirmation' : 'Awaiting confirmation', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 8),
            Text('${claim.typeLabel} · ₹${_inr(claim.claimedAmount ?? claim.amount)} · ${claim.methodLabel}'),
            Text('${claim.isOnline ? 'Razorpay payment id' : 'Reference'}: ${claim.reference ?? '-'}'),
            if (claim.paidOn != null) Text('Paid on: ${df.format(claim.paidOn!.toLocal())}'),
            if (claim.claimedAt != null) Text('Submitted: ${df.format(claim.claimedAt!.toLocal())}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            const SizedBox(height: 8),
            Text(claim.isOnline
                ? 'Your online payment was verified. Seicho Consulting confirms it and your organisation is reactivated automatically.'
                : 'Seicho Consulting is verifying this payment. Your organisation is reactivated automatically once it is confirmed.',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.payments});
  final List<OfflinePayment> payments;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final p in payments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  p.status == 'CONFIRMED' ? Icons.check_circle : (p.status == 'REJECTED' ? Icons.cancel : Icons.hourglass_top),
                  color: p.status == 'CONFIRMED' ? Colors.green : (p.status == 'REJECTED' ? Colors.red : Colors.blue),
                ),
                title: Text('${p.typeLabel} · ₹${_inr(p.confirmedAmount ?? p.claimedAmount ?? p.amount)}'),
                subtitle: Text([
                  'Ref ${p.confirmedReference ?? p.reference ?? '-'}',
                  if (p.confirmedAt != null) '${p.status == 'REJECTED' ? 'Rejected' : 'Confirmed'} ${df.format(p.confirmedAt!.toLocal())}',
                  if (p.rejectReason != null && p.rejectReason!.isNotEmpty) p.rejectReason!,
                ].join(' · ')),
              ),
          ],
        ),
      ),
    );
  }
}
