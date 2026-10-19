import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/onboarding/onboarding_service.dart';
import '../../theme/colors.dart';

/// The six-field organisation registration form used by both the free-trial
/// and subscribe flows. The rules match the server's (registrationConflicts.js /
/// the Joi schemas), so a form that passes here is not rejected as invalid there.
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    super.key,
    required this.heading,
    required this.icon,
    required this.submitLabel,
    required this.onSubmit,
    this.busy = false,
    this.initial,
    this.errorField,
    this.errorMessage,
  });

  final String heading;
  final IconData icon;
  final String submitLabel;
  final bool busy;
  final Future<void> Function(RegistrationDetails details) onSubmit;

  /// Details entered earlier (shown again after "Edit details").
  final RegistrationDetails? initial;

  /// A server-side problem with one field ('email' or 'phone'), shown under it.
  final String? errorField;
  final String? errorMessage;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validatePhone(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Enter the admin phone number';
  final digits = s.replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'^\+?[\d\s-]+$').hasMatch(s) || digits.length < 10 || digits.length > 13) {
    return 'Enter a valid phone number (10 digits)';
  }
  return null;
}

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Enter the admin email';
  return _emailPattern.hasMatch(s) ? null : 'Enter a valid email address';
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  late final _org = TextEditingController(text: widget.initial?.orgName);
  late final _unit = TextEditingController(text: widget.initial?.unitName);
  late final _admin = TextEditingController(text: widget.initial?.adminName);
  late final _phone = TextEditingController(text: widget.initial?.adminPhone);
  late final _email = TextEditingController(text: widget.initial?.adminEmail);
  late final _employees = TextEditingController(text: widget.initial?.employeeCount?.toString());

  // The server error stays under its field until that field is edited.
  String? _serverField;
  String? _serverMessage;

  @override
  void initState() {
    super.initState();
    _serverField = widget.errorField;
    _serverMessage = widget.errorMessage;
  }

  @override
  void didUpdateWidget(RegistrationForm old) {
    super.didUpdateWidget(old);
    if (widget.errorField != old.errorField || widget.errorMessage != old.errorMessage) {
      _serverField = widget.errorField;
      _serverMessage = widget.errorMessage;
    }
  }

  @override
  void dispose() {
    for (final c in [_org, _unit, _admin, _phone, _email, _employees]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _serverErrorFor(String field) => _serverField == field ? _serverMessage : null;

  void _clearServerError(String field) {
    if (_serverField == field) setState(() => _serverField = null);
  }

  Future<void> _submit() async {
    setState(() => _serverField = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.onSubmit(RegistrationDetails(
      orgName: _org.text.trim(),
      unitName: _unit.text.trim(),
      adminName: _admin.text.trim(),
      adminPhone: _phone.text.trim(),
      adminEmail: _email.text.trim().toLowerCase(),
      employeeCount: int.tryParse(_employees.text.trim()),
    ));
  }

  // A floating label stays visible above the text once the field is filled,
  // so long labels like "Admin phone number" are never lost to truncation.
  InputDecoration _dec(String label, {String? hint, String? errorText, IconData? icon}) => InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        errorMaxLines: 5,
        prefixIcon: icon == null ? null : Icon(icon, color: Colors.grey.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade500)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade500)),
      );

  Widget _section(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F1F1F))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3)),
          ],
        ),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: AutofillGroup(
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
              _section('Org.', 'Your company or plant'),
              TextFormField(
                controller: _org,
                decoration: _dec('Org. name', icon: Icons.business_outlined),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                buildCounter: _noCounter,
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the org. name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unit,
                decoration: _dec('Unit name or no. (optional)', icon: Icons.factory_outlined),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                buildCounter: _noCounter,
              ),
              const SizedBox(height: 24),
              _section('Org. admin', 'The person who will sign in and manage diGi5S. Login details are emailed to them.'),
              TextFormField(
                controller: _admin,
                decoration: _dec('Admin full name', icon: Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                maxLength: 100,
                buildCounter: _noCounter,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.length < 2) return "Enter the admin's full name";
                  return RegExp(r'[A-Za-zऀ-ॿ]').hasMatch(s) ? null : 'Enter a valid name';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                decoration: _dec('Admin phone number', hint: '10-digit mobile number', icon: Icons.phone_outlined, errorText: _serverErrorFor('phone')),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d+\s-]')), LengthLimitingTextInputFormatter(17)],
                onChanged: (_) => _clearServerError('phone'),
                validator: validatePhone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                decoration: _dec('Admin email', hint: 'name@company.com', icon: Icons.email_outlined, errorText: _serverErrorFor('email')),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => _clearServerError('email'),
                validator: validateEmail,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _employees,
                decoration: _dec('Employees (optional)', icon: Icons.groups_outlined),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                onFieldSubmitted: (_) => widget.busy ? null : _submit(),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null; // one price for any team size
                  final n = int.tryParse(s);
                  return (n == null || n < 1) ? 'Enter a valid number' : null;
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
      ),
    );
  }
}

Widget? _noCounter(BuildContext context, {required int currentLength, required bool isFocused, required int? maxLength}) => null;
