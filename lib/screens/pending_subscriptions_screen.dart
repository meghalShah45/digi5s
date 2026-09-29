import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api/api_client.dart';
import '../features/licence/confirm_payment_dialog.dart';
import '../features/licence/licence_service.dart';
import '../features/organisations/organisation_service.dart';
import '../theme/colors.dart';

/// Super admin: Razorpay payments.
///   To verify  - signature-verified Razorpay payments (confirm / reject)
///   Awaiting   - organisations registered directly that have not paid yet (read-only)
///   History    - confirmed / rejected payments
class PendingSubscriptionsScreen extends ConsumerStatefulWidget {
  const PendingSubscriptionsScreen({super.key});

  @override
  ConsumerState<PendingSubscriptionsScreen> createState() => _PendingSubscriptionsScreenState();
}

class _PendingSubscriptionsScreenState extends ConsumerState<PendingSubscriptionsScreen> {
  String? _busyId;

  Future<void> _refresh() async {
    ref.invalidate(claimedPaymentsProvider);
    ref.invalidate(awaitingPaymentProvider);
    ref.invalidate(paymentHistoryProvider);
    ref.invalidate(organisationsProvider);
    ref.invalidate(orgSubscriptionsProvider);
    await Future.wait<Object>([
      ref.read(claimedPaymentsProvider.future),
      ref.read(awaitingPaymentProvider.future),
      ref.read(paymentHistoryProvider.future),
    ]).catchError((_) => <Object>[]);
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }

  Future<void> _confirmClaim(OfflinePayment p) async {
    final data = await showConfirmPaymentDialog(context, orgId: p.orgId, orgName: p.orgName ?? 'Organisation', claim: p);
    if (data == null) return;
    _snack(data['credentialsEmailed'] == true
        ? 'Payment confirmed. Organisation activated and login details emailed.'
        : 'Payment confirmed. Organisation activated.');
    await _refresh();
  }

  Future<void> _reject(OfflinePayment p) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject payment details - ${p.orgName ?? ''}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Reason (sent to the client)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.length < 3) return;
    setState(() => _busyId = p.id);
    try {
      await ref.read(licenceServiceProvider).rejectPayment(p.id, reason: reason);
      _snack('Payment details rejected. The client has been notified.');
      await _refresh();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Payments & Licences'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            tabs: [Tab(text: 'To verify'), Tab(text: 'Awaiting'), Tab(text: 'History')],
          ),
        ),
        body: TabBarView(
          children: [
            _ClaimsTab(onConfirm: _confirmClaim, onReject: _reject, busyId: _busyId, onRefresh: _refresh),
            _AwaitingTab(onRefresh: _refresh),
            _HistoryTab(onRefresh: _refresh),
          ],
        ),
      ),
    );
  }
}

String _inr(num n) => NumberFormat.decimalPattern('en_IN').format(n);

Widget _empty(IconData icon, String text) => ListView(children: [
      const SizedBox(height: 120),
      Icon(icon, size: 56, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      Center(child: Text(text)),
    ]);

Widget _errorList(Object e, VoidCallback retry, String fallback) => ListView(children: [
      const SizedBox(height: 120),
      Center(child: Text(e is ApiException ? e.message : fallback)),
      Center(child: TextButton(onPressed: retry, child: const Text('Retry'))),
    ]);

Widget _chip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );

class _ClaimsTab extends ConsumerWidget {
  const _ClaimsTab({required this.onConfirm, required this.onReject, required this.busyId, required this.onRefresh});
  final Future<void> Function(OfflinePayment) onConfirm;
  final Future<void> Function(OfflinePayment) onReject;
  final String? busyId;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(claimedPaymentsProvider);
    final df = DateFormat('d MMM yyyy');
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorList(e, onRefresh, 'Could not load payment claims'),
        data: (items) {
          if (items.isEmpty) return _empty(Icons.task_alt, 'No payment details waiting for verification');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = items[i];
              final busy = busyId == p.id;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.orgName ?? 'Organisation', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${p.orgEmail ?? ''}${p.orgPhone == null ? '' : ' · ${p.orgPhone}'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        _chip(p.typeLabel, AppColors.primary),
                        if (p.isOnline) _chip(p.gatewayVerified ? 'Razorpay · verified' : 'Razorpay', Colors.green.shade800),
                        _chip('${p.isOnline ? 'Paid' : 'Claimed'} ₹${_inr(p.claimedAmount ?? p.amount)}', p.amountMismatch ? Colors.red : Colors.green),
                        if (p.amountMismatch) _chip('Due ₹${_inr(p.amount)}', Colors.red),
                        if (p.paidOn != null) _chip('Paid ${df.format(p.paidOn!.toLocal())}', Colors.grey),
                      ]),
                      const SizedBox(height: 6),
                      SelectableText('${p.isOnline ? 'Razorpay payment id' : 'Reference'}: ${p.reference ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (p.note != null && p.note!.isNotEmpty) Text('Note: ${p.note}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      if (p.claimedAt != null) Text('Submitted ${df.format(p.claimedAt!.toLocal())}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                            onPressed: busy ? null : () => onConfirm(p),
                            icon: const Icon(Icons.verified_outlined, size: 18),
                            label: const Text('Verify & confirm'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                          onPressed: busy ? null : () => onReject(p),
                          child: busy
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Reject'),
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AwaitingTab extends ConsumerWidget {
  const _AwaitingTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(awaitingPaymentProvider);
    final df = DateFormat('d MMM yyyy');
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorList(e, onRefresh, 'Could not load registrations'),
        data: (items) {
          if (items.isEmpty) return _empty(Icons.inbox_outlined, 'No registrations waiting for payment');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = items[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.orgName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${o.adminName ?? ''} · ${o.adminEmail ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      if ((o.adminPhone ?? '').isNotEmpty) Text(o.adminPhone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        _chip('Lifetime licence ₹${_inr(o.licencePrice)}', AppColors.primary),
                        if (o.createdAt != null) _chip('Registered ${df.format(o.createdAt!.toLocal())}', Colors.grey),
                      ]),
                      const SizedBox(height: 6),
                      Text('Registered in the app without a trial and not paid yet. Once they pay ₹${_inr(o.licencePrice)} online, '
                          'the payment appears under "To verify" for you to confirm.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentHistoryProvider);
    final df = DateFormat('d MMM yyyy');
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorList(e, onRefresh, 'Could not load payment history'),
        data: (items) {
          if (items.isEmpty) return _empty(Icons.history, 'No confirmed or rejected payments yet');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = items[i];
              final ok = p.status == 'CONFIRMED';
              return ListTile(
                leading: Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.red),
                title: Text('${p.orgName ?? 'Organisation'} · ₹${_inr(p.confirmedAmount ?? p.claimedAmount ?? p.amount)}'),
                subtitle: Text([
                  p.typeLabel,
                  if (p.isOnline) 'Razorpay',
                  'Ref ${p.confirmedReference ?? p.reference ?? '-'}',
                  if (p.confirmedAt != null) '${ok ? 'Confirmed' : 'Rejected'} ${df.format(p.confirmedAt!.toLocal())}',
                  if (p.confirmedByEmail != null) 'by ${p.confirmedByEmail}',
                  if (!ok && p.rejectReason != null) p.rejectReason!,
                ].join(' · ')),
              );
            },
          );
        },
      ),
    );
  }
}
