import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/api/api_client.dart';
import '../../features/dashboard/dashboard_repository.dart';
import '../../features/licence/licence_service.dart';
import '../../theme/colors.dart';

/// Organisation admin: what is due (lifetime licence or yearly cloud charge),
/// pay online through Razorpay or offline with the "I have paid" form. Either
/// way the organisation stays read-only until Seicho Consulting confirms the
/// payment (an online payment is already signature-verified, so that is one tap).
class PayOfflineScreen extends ConsumerStatefulWidget {
  const PayOfflineScreen({super.key});

  @override
  ConsumerState<PayOfflineScreen> createState() => _PayOfflineScreenState();
}

class _PayOfflineScreenState extends ConsumerState<PayOfflineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  String _method = 'BANK';
  DateTime _paidOn = DateTime.now();
  bool _busy = false;
  Razorpay? _razorpay;
  OnlineOrder? _order;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
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
      _snack('Could not start the online payment. Please try again or pay offline.', error: true);
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

  Future<void> _submit(LicenceQuote q) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final amount = num.parse(_amount.text.trim());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit payment details?'),
        content: Text('Amount ₹${_inr(amount)} · ${paymentMethodLabels[_method]}\nReference: ${_reference.text.trim()}\n\n'
            'Seicho Consulting will verify this against the bank account before activating your organisation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(licenceServiceProvider).submitClaim(
            amount: amount,
            reference: _reference.text,
            method: _method,
            paidOn: _paidOn,
            note: _note.text,
          );
      _snack('Payment details submitted. You will be notified once the payment is confirmed.');
      await _refresh();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Could not submit the payment details. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw(OfflinePayment claim) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw payment details?'),
        content: const Text('You can submit them again afterwards.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700), onPressed: () => Navigator.pop(ctx, true), child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(licenceServiceProvider).withdrawClaim(claim.id);
      _snack('Payment details withdrawn');
      await _refresh();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            if (_amount.text.isEmpty && q.amountDue > 0) _amount.text = q.amountDue.toStringAsFixed(0);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(q: q),
                const SizedBox(height: 12),
                if (q.pendingClaim != null)
                  _PendingClaimCard(claim: q.pendingClaim!, busy: _busy, onWithdraw: () => _withdraw(q.pendingClaim!))
                else if (q.somethingDue) ...[
                  if (q.onlinePaymentEnabled) ...[
                    _OnlinePayCard(q: q, busy: _busy, onPay: _payOnline),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or pay offline', style: TextStyle(color: Colors.grey.shade600))),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 12),
                  ],
                  _InstructionsCard(q: q),
                  const SizedBox(height: 12),
                  _claimForm(q),
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

  Widget _claimForm(LicenceQuote q) {
    InputDecoration dec(String l, {String? hint}) => InputDecoration(
        labelText: l, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true);
    final df = DateFormat('d MMM yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('I have paid - submit the details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Seicho Consulting checks these against the bank account and then activates your organisation.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amount,
                decoration: dec('Amount paid (₹)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = num.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Enter the amount paid';
                  if ((n - q.amountDue).abs() > 0.01) return 'Amount due is ₹${_inr(q.amountDue)}';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: dec('Payment method'),
                items: [for (final m in paymentMethods) DropdownMenuItem(value: m, child: Text(paymentMethodLabels[m] ?? m))],
                onChanged: (v) => setState(() => _method = v ?? 'BANK'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reference,
                decoration: dec('Reference / UTR / cheque no.', hint: 'As shown in your bank app'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v ?? '').trim().length < 3 ? 'Enter the payment reference' : null,
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _paidOn,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _paidOn = d);
                },
                child: InputDecorator(
                  decoration: dec('Paid on'),
                  child: Text(df.format(_paidOn)),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(controller: _note, decoration: dec('Note (optional)'), maxLines: 2),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(50)),
                onPressed: _busy ? null : () => _submit(q),
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined),
                label: const Text('Submit payment details'),
              ),
            ],
          ),
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

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.q});
  final LicenceQuote q;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.account_balance_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Pay ₹${_inr(q.amountDue)} offline', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 10),
            SelectableText(q.paymentInstructions, style: const TextStyle(height: 1.5)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: q.paymentInstructions));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment details copied')));
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingClaimCard extends StatelessWidget {
  const _PendingClaimCard({required this.claim, required this.busy, required this.onWithdraw});
  final OfflinePayment claim;
  final bool busy;
  final VoidCallback onWithdraw;

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
            if (!claim.isOnline)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: busy ? null : onWithdraw, child: const Text('Withdraw and resubmit')),
              ),
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
