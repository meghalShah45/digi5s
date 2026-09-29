import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../theme/colors.dart';
import 'licence_service.dart';

/// Super admin: double-verified confirmation of a Razorpay payment.
///
/// The payment is already signature-verified by the server. The dialog is
/// pre-filled with the amount and the Razorpay payment id (the backend checks
/// both against the recorded payment), and the "I have verified this payment
/// in Razorpay" box must be ticked before anything is activated.
///
/// Returns the backend's confirmation data, or null when cancelled.
Future<Map<String, dynamic>?> showConfirmPaymentDialog(
  BuildContext context, {
  required String orgId,
  required String orgName,
  required OfflinePayment claim,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ConfirmPaymentDialog(orgId: orgId, orgName: orgName, claim: claim),
  );
}

class _ConfirmPaymentDialog extends ConsumerStatefulWidget {
  const _ConfirmPaymentDialog({required this.orgId, required this.orgName, required this.claim});
  final String orgId;
  final String orgName;
  final OfflinePayment claim;

  @override
  ConsumerState<_ConfirmPaymentDialog> createState() => _ConfirmPaymentDialogState();
}

class _ConfirmPaymentDialogState extends ConsumerState<_ConfirmPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: (widget.claim.claimedAmount ?? widget.claim.amount).toStringAsFixed(0));
  late final _reference = TextEditingController(text: widget.claim.reference ?? '');
  bool _verified = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_verified) {
      setState(() => _error = 'Tick the box to confirm you have checked this payment in Razorpay.');
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await ref.read(licenceServiceProvider).confirmPayment(
            orgId: widget.orgId,
            offlinePaymentId: widget.claim.id,
            amount: num.parse(_amount.text.trim()),
            reference: _reference.text,
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
    InputDecoration dec(String l) =>
        InputDecoration(labelText: l, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true);

    return AlertDialog(
      title: Text('Confirm payment - ${widget.orgName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(claim.typeLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paid online via Razorpay${claim.gatewayVerified ? ' - signature verified' : ''}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Text('₹${inr.format(claim.claimedAmount ?? claim.amount)} · ${claim.methodLabel}'),
                    Text('Payment id ${claim.reference ?? '-'}${claim.paidOn == null ? '' : ' · paid ${df.format(claim.paidOn!.toLocal())}'}'),
                    if (claim.razorpayOrderId != null) Text('Order ${claim.razorpayOrderId}', style: const TextStyle(fontSize: 11)),
                    if (claim.amountMismatch)
                      Text('⚠ Amount due is ₹${inr.format(claim.amount)}',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text('Check this payment in your Razorpay dashboard, then confirm. The amount and payment id must match the recorded payment.',
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
                decoration: dec('Razorpay payment id'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the payment id' : null,
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _verified,
                onChanged: (v) => setState(() => _verified = v ?? false),
                title: const Text('I have verified this payment in Razorpay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
