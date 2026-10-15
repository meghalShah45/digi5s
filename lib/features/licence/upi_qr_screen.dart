import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../theme/colors.dart';

/// Single-use UPI QR code created by the server through Razorpay.
class UpiQr {
  final String paymentId;
  final num amount;
  final String? qrImageUrl;
  final DateTime? expiresAt;
  final String status; // PENDING | CLAIMED | CONFIRMED | REJECTED
  final bool expired;

  const UpiQr({
    required this.paymentId,
    required this.amount,
    this.qrImageUrl,
    this.expiresAt,
    this.status = 'PENDING',
    this.expired = false,
  });

  bool get isPaid => status == 'CLAIMED' || status == 'CONFIRMED';

  factory UpiQr.fromJson(Map<String, dynamic> j) => UpiQr(
        paymentId: (j['paymentId'] ?? '').toString(),
        amount: num.tryParse(j['amount']?.toString() ?? '') ?? 0,
        qrImageUrl: j['qrImageUrl']?.toString(),
        expiresAt: DateTime.tryParse(j['expiresAt']?.toString() ?? '')?.toLocal(),
        status: (j['status'] ?? 'PENDING').toString(),
        expired: j['expired'] == true,
      );
}

/// Shows the QR and waits for the payment. Pops `true` once Razorpay reports it paid.
class UpiQrScreen extends StatefulWidget {
  const UpiQrScreen({super.key, required this.create, required this.checkStatus});

  final Future<UpiQr> Function() create;
  final Future<UpiQr> Function(String paymentId) checkStatus;

  static Future<bool> open(
    BuildContext context, {
    required Future<UpiQr> Function() create,
    required Future<UpiQr> Function(String paymentId) checkStatus,
  }) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UpiQrScreen(create: create, checkStatus: checkStatus)),
    );
    return paid == true;
  }

  @override
  State<UpiQrScreen> createState() => _UpiQrScreenState();
}

class _UpiQrScreenState extends State<UpiQrScreen> {
  UpiQr? _qr;
  String? _error;
  bool _loading = true;
  bool _checking = false;
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _poll?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final qr = await widget.create();
      if (!mounted) return;
      setState(() => _qr = qr);
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not create the QR code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _check() async {
    final qr = _qr;
    if (qr == null || _checking) return;
    _checking = true;
    try {
      final s = await widget.checkStatus(qr.paymentId);
      if (!mounted) return;
      if (s.isPaid) {
        _poll?.cancel();
        Navigator.of(context).pop(true);
        return;
      }
      if (s.expired) {
        _poll?.cancel();
        setState(() => _qr = s);
      }
    } catch (_) {
      // Network hiccup: keep polling.
    } finally {
      _checking = false;
    }
  }

  Duration? get _left {
    final e = _qr?.expiresAt;
    if (e == null) return null;
    final d = e.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  @override
  Widget build(BuildContext context) {
    final qr = _qr;
    final left = _left;
    final expired = qr != null && (qr.expired || left == Duration.zero);
    final inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pay by UPI QR code'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_loading)
            const Padding(padding: EdgeInsets.only(top: 120), child: Center(child: CircularProgressIndicator()))
          else if (_error != null) ...[
            const SizedBox(height: 60),
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Center(child: FilledButton(onPressed: _load, child: const Text('Try again'))),
          ] else if (qr != null) ...[
            Text('Scan to pay ${inr.format(qr.amount)}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Open any UPI app (Google Pay, PhonePe, Paytm, BHIM or your bank app) on another phone and scan this code.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            Center(
              child: Opacity(
                opacity: expired ? 0.2 : 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: qr.qrImageUrl == null
                      ? const SizedBox(width: 260, height: 260, child: Center(child: Text('QR image unavailable')))
                      : Image.network(
                          qr.qrImageUrl!,
                          width: 300,
                          fit: BoxFit.contain,
                          loadingBuilder: (c, w, p) => p == null
                              ? w
                              : const SizedBox(width: 260, height: 260, child: Center(child: CircularProgressIndicator())),
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 260, height: 260, child: Center(child: Text('Could not load the QR image'))),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (expired) ...[
              const Text('This QR code has expired.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Center(child: FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Show a new QR code'))),
            ] else ...[
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text('Waiting for payment'
                    '${left == null ? '' : ' · ${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')} left'}'),
              ]),
              const SizedBox(height: 8),
              Text('This screen updates by itself once the payment is received. Pay only once.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ],
        ],
      ),
    );
  }
}
