import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../features/onboarding/onboarding_service.dart';
import '../../theme/colors.dart';
import 'registration_form.dart';

/// Free trial: register -> emailed code -> verify -> credentials emailed.
class FreeTrialScreen extends ConsumerStatefulWidget {
  const FreeTrialScreen({super.key});

  @override
  ConsumerState<FreeTrialScreen> createState() => _FreeTrialScreenState();
}

class _FreeTrialScreenState extends ConsumerState<FreeTrialScreen> {
  bool _busy = false;
  RegistrationDetails? _submitted;
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }

  Future<void> _start(RegistrationDetails d) async {
    setState(() => _busy = true);
    try {
      final msg = await ref.read(onboardingServiceProvider).startFreeTrial(d);
      setState(() => _submitted = d);
      _snack(msg.isEmpty ? 'Verification code sent to ${d.adminEmail}' : msg);
    } on ApiException catch (e) {
      _snack(e.statusCode == 429 ? 'A code was already sent. Check your inbox or wait a few minutes.' : e.message, error: true);
    } catch (_) {
      _snack('Could not start the free trial. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final d = _submitted;
    if (d == null || _code.text.trim().length != 6) {
      _snack('Enter the 6-digit code from your email', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(onboardingServiceProvider).verifyFreeTrial(adminEmail: d.adminEmail, code: _code.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
          title: const Text('Your free trial is ready'),
          content: Text('Login details for ${d.adminEmail} have been emailed. Your 14-day trial starts now.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Go to sign in'))],
        ),
      );
      if (mounted) context.go('/login');
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Verification failed. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Free Trial'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            if (_submitted == null)
              RegistrationForm(
                heading: 'Free Trial Registration',
                icon: Icons.rocket_launch,
                submitLabel: 'Start Free Trial',
                busy: _busy,
                onSubmit: _start,
              )
            else
              _VerifyCard(
                email: _submitted!.adminEmail,
                controller: _code,
                busy: _busy,
                onVerify: _verify,
                onResend: () => _start(_submitted!),
                onEdit: () => setState(() => _submitted = null),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerifyCard extends StatelessWidget {
  const _VerifyCard({
    required this.email,
    required this.controller,
    required this.busy,
    required this.onVerify,
    required this.onResend,
    required this.onEdit,
  });

  final String email;
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 32),
              SizedBox(width: 14),
              Expanded(child: Text('Verify your email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          Text('We sent a 6-digit code to $email. It is valid for 30 minutes.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: busy ? null : onVerify,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verify and create organization', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: busy ? null : onEdit, child: const Text('Edit details')),
              TextButton(onPressed: busy ? null : onResend, child: const Text('Resend code')),
            ],
          ),
        ],
      ),
    );
  }
}
