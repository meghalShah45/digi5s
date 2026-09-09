import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../features/organisations/organisation_service.dart';
import '../theme/colors.dart';

/// Super admin: create an organisation. The backend also creates its admin
/// user and returns the generated password once.
class AddOrganizationScreen extends ConsumerStatefulWidget {
  const AddOrganizationScreen({super.key});

  @override
  ConsumerState<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends ConsumerState<AddOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _gst = TextEditingController();
  final _pan = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _addr1, _addr2, _gst, _pan]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final result = await ref.read(organisationServiceProvider).create(
            name: _name.text,
            email: _email.text,
            contactNo: _phone.text,
            addressLine1: _addr1.text,
            addressLine2: _addr2.text,
            gstNo: _gst.text,
            pancardNo: _pan.text,
          );
      ref.invalidate(organisationsProvider);
      if (!mounted) return;
      final creds = result['adminCredentials'];
      final email = creds is Map ? creds['email']?.toString() : null;
      final password = creds is Map ? creds['password']?.toString() : null;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Organisation created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('An admin account was created and the credentials were emailed. They are shown here once:'),
              const SizedBox(height: 12),
              if (email != null) SelectableText('Email: $email'),
              if (password != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: SelectableText('Password: $password', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () => Clipboard.setData(ClipboardData(text: password)),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        ),
      );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not create the organisation.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red.shade700));
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration dec(String label, {IconData? icon}) => InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New organisation'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: dec('Organisation name', icon: Icons.business),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the organisation name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              decoration: dec('Admin email', icon: Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty || !s.contains('@') || !s.contains('.')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              decoration: dec('Contact number', icon: Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _addr1, decoration: dec('Address line 1', icon: Icons.location_on_outlined)),
            const SizedBox(height: 14),
            TextFormField(controller: _addr2, decoration: dec('Address line 2')),
            const SizedBox(height: 14),
            TextFormField(controller: _gst, decoration: dec('GST number'), textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 14),
            TextFormField(controller: _pan, decoration: dec('PAN'), textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create organisation'),
              ),
            ),
            const SizedBox(height: 8),
            Text('The admin user is created automatically with a generated password.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
