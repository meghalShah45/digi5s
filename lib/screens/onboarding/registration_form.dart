import 'package:flutter/material.dart';

import '../../features/onboarding/onboarding_service.dart';
import '../../theme/colors.dart';

/// The six-field organisation registration form used by both the free-trial
/// and subscribe flows.
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    super.key,
    required this.heading,
    required this.icon,
    required this.submitLabel,
    required this.onSubmit,
    this.busy = false,
  });

  final String heading;
  final IconData icon;
  final String submitLabel;
  final bool busy;
  final Future<void> Function(RegistrationDetails details) onSubmit;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _org = TextEditingController();
  final _unit = TextEditingController();
  final _admin = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _employees = TextEditingController();

  @override
  void dispose() {
    for (final c in [_org, _unit, _admin, _phone, _email, _employees]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.onSubmit(RegistrationDetails(
      orgName: _org.text,
      unitName: _unit.text,
      adminName: _admin.text,
      adminPhone: _phone.text,
      adminEmail: _email.text,
      employeeCount: int.parse(_employees.text.trim()),
    ));
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade500)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade500)),
      );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EEF8),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: AppColors.primary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(widget.heading, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _org,
              decoration: _dec('Name of the Organization'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the organization name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _unit, decoration: _dec('Unit Name or No.')),
            const SizedBox(height: 16),
            TextFormField(
              controller: _admin,
              decoration: _dec('Organization Admin Name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the admin name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration: _dec('Organization Admin Ph No.'),
              keyboardType: TextInputType.phone,
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length < 10 ? 'Enter a valid phone number' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: _dec('Organization Admin E-mail'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final s = v?.trim() ?? '';
                return (s.isEmpty || !s.contains('@') || !s.contains('.')) ? 'Enter a valid email' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _employees,
              decoration: _dec('No. of Employees to be subscribed'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n < 1) ? 'Enter the number of employees' : null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: widget.busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: widget.busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.submitLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
