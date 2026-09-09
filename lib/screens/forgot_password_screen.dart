import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../core/auth/auth_repository.dart';
import '../theme/colors.dart';

/// Two-step reset: request an emailed OTP, then submit OTP + new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordResetOtp(_email.text);
      setState(() => _otpSent = true);
      _snack('A 6-digit code has been sent to ${_email.text.trim()}. It expires in 10 minutes.');
    } on ApiException catch (e) {
      _snack(e.statusCode == 404 ? 'No account found for this email.' : e.message, error: true);
    } catch (_) {
      _snack('Something went wrong. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resetPasswordWithOtp(
            email: _email.text,
            otp: _otp.text,
            newPassword: _password.text,
          );
      _snack('Password updated. Please log in with your new password.');
      if (mounted) context.go('/login');
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Something went wrong. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _otpSent
                      ? 'Enter the code from your email and choose a new password.'
                      : 'Enter the email address of your account. We will email you a one-time code.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  enabled: !_otpSent && !_busy,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: border),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) return 'Please enter your email';
                    if (!s.contains('@') || !s.contains('.')) return 'Please enter a valid email';
                    return null;
                  },
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(labelText: '6-digit code', prefixIcon: const Icon(Icons.pin_outlined), border: border, counterText: ''),
                    validator: (v) => (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: border,
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: InputDecoration(labelText: 'Confirm new password', prefixIcon: const Icon(Icons.lock_outline), border: border),
                    validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _busy ? null : (_otpSent ? _reset : _sendOtp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_otpSent ? 'Set new password' : 'Send code'),
                  ),
                ),
                if (_otpSent)
                  TextButton(
                    onPressed: _busy ? null : _sendOtp,
                    child: const Text('Resend code'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
