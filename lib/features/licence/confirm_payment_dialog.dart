import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../theme/colors.dart';
import 'licence_service.dart';

/// Super admin: double-verified confirmation of an offline payment.
///
/// With a [claim] the super admin re-types the amount and reference, which the
/// backend compares with what the client submitted. Without a claim (walk-in)
/// the amount must equal the organisation's quoted price. Either way the
/// "I have verified this payment in the bank account" box must be ticked.
///
/// Returns the backend's confirmation data, or null when cancelled.
Future<Map<String, dynamic>?> showConfirmPaymentDialog(
  BuildContext context, {
  required String orgId,
  required String orgName,
  OfflinePayment? claim,
  String? type, // LICENCE | CLOUD_RENEWAL (walk-in)
  num? expectedAmount, // walk-in: what the organisation owes
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ConfirmPaymentDialog(orgId: orgId, orgName: orgName, claim: claim, type: type, expectedAmount: expectedAmount),
  );
}

class _ConfirmPaymentDialog extends ConsumerStatefulWidget {
  const _ConfirmPaymentDialog({required this.orgId, required this.orgName, this.claim, this.type, this.expectedAmount});
  final String orgId;
  final String orgName;
  final OfflinePayment? claim;
  final String? type;
  final num? expectedAmount;

  @override
  ConsumerState<_ConfirmPaymentDialog> createState() => _ConfirmPaymentDialogState();
}

class _ConfirmPaymentDialogState extends ConsumerState<_ConfirmPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  // Walk-in: pre-fill the quoted amount. Verified online payment: pre-fill both
  // amount and Razorpay payment id (they are server-known), so confirming is one tap.
  late final _amount = TextEditingController(
      text: widget.claim != null && widget.claim!.isOnline && widget.claim!.gatewayVerified
          ? (widget.claim!.claimedAmount ?? widget.claim!.amount).toStringAsFixed(0)
          : (widget.claim == null && widget.expectedAmount != null ? widget.expectedAmount!.toStringAsFixed(0) : ''));
  late final _reference = TextEditingController(
      text: widget.claim != null && widget.claim!.isOnline && widget.claim!.gatewayVerified ? (widget.claim!.reference ?? '') : '');
  final _note = TextEditingController();
  String _method = 'BANK';
  DateTime _paidOn = DateTime.now();
  bool _verified = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _typeLabel {
    final t = widget.claim?.type ?? widget.type;
    return t == 'CLOUD_RENEWAL' ? 'Cloud renewal (1 year, ₹1,000)' : 'Lifetime licence';
  }

  Future<void> _confirm() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_verified) {
      setState(() => _error = 'Tick the box to confirm you have verified the payment in the bank account.');
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await ref.read(licenceServiceProvider).confirmPayment(
            orgId: widget.orgId,
            offlinePaymentId: widget.claim?.id,
            type: widget.claim == null ? widget.type : null,
            amount: num.parse(_amount.text.trim()),
            reference: _reference.text,
            method: widget.claim == null ? _method : null,
            paidOn: widget.claim == null ? _paidOn : null,
            note: widget.claim == null ? _note.text : null,
            confirm: true,
          );
      if (mounted) Navigator.pop(context, data);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not confirm the payment. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claim = widget.claim;
    final df = DateFormat('d MMM yyyy');
    final inr = NumberFormat.decimalPattern('en_IN');
    InputDecoration dec(String l, {String? hint}) => InputDecoration(
        labelText: l, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true);

    return AlertDialog(
      title: Text('Confirm payment - ${widget.orgName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_typeLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (claim != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: claim.isOnline ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(claim.isOnline ? 'Paid online via Razorpay${claim.gatewayVerified ? ' - signature verified' : ''}' : 'Client submitted',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      Text('₹${inr.format(claim.claimedAmount ?? claim.amount)} · ${claim.methodLabel}'),
                      Text('${claim.isOnline ? 'Payment id' : 'Ref'} ${claim.reference ?? '-'}${claim.paidOn == null ? '' : ' · paid ${df.format(claim.paidOn!.toLocal())}'}'),
                      if (claim.razorpayOrderId != null) Text('Order ${claim.razorpayOrderId}', style: const TextStyle(fontSize: 11)),
                      if (!claim.isOnline && claim.note != null && claim.note!.isNotEmpty) Text('Note: ${claim.note}', style: const TextStyle(fontSize: 12)),
                      if (claim.amountMismatch)
                        Text('⚠ Amount due is ₹${inr.format(claim.amount)}', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(claim.isOnline
                    ? 'Razorpay already verified this payment. Check it in your Razorpay dashboard or bank settlement, then confirm.'
                    : 'Re-enter the amount and reference exactly as they appear in the bank statement. They must match the client\'s entry.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ] else
                Text('Record a payment received outside the app. The amount must equal what this organisation owes'
                    '${widget.expectedAmount == null ? '' : ' (₹${inr.format(widget.expectedAmount!)})'}.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                decoration: dec('Amount received (₹)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (num.tryParse((v ?? '').trim()) ?? 0) <= 0 ? 'Enter the amount' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _reference,
                decoration: dec('Reference / UTR / cheque no.'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the reference' : null,
              ),
              if (claim == null) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _method,
                  decoration: dec('Method'),
                  items: [for (final m in paymentMethods) DropdownMenuItem(value: m, child: Text(paymentMethodLabels[m] ?? m))],
                  onChanged: (v) => setState(() => _method = v ?? 'BANK'),
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
                  child: InputDecorator(decoration: dec('Received on'), child: Text(df.format(_paidOn))),
                ),
                const SizedBox(height: 10),
                TextFormField(controller: _note, decoration: dec('Note (optional)')),
              ],
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _verified,
                onChanged: (v) => setState(() => _verified = v ?? false),
                title: Text(claim != null && claim.isOnline
                    ? 'I have verified this payment in Razorpay / the bank settlement'
                    : 'I have verified this payment in the bank account',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _busy ? null : _confirm,
          icon: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.verified_outlined, size: 18),
          label: const Text('Confirm & activate'),
        ),
      ],
    );
  }
}

/// Super admin: set or clear the special lifetime-licence price for one organisation.
Future<num?> showSpecialPriceDialog(BuildContext context, {required String orgName, num? current}) {
  final ctrl = TextEditingController(text: current == null ? '' : current.toStringAsFixed(0));
  return showDialog<num?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Special licence price - $orgName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('List price is ₹10,000. Enter the amount agreed with this client; leave empty to use the list price.',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Lifetime licence price (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final s = ctrl.text.trim();
            Navigator.pop(ctx, s.isEmpty ? -1 : num.tryParse(s));
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).then((v) => v); // -1 means "reset to list price"
}
