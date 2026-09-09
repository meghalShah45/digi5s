import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/api/api_client.dart';
import '../core/auth/session.dart';
import '../features/organisations/organisation_service.dart';
import '../theme/colors.dart';

/// Super admin view of one organisation: details, subscription, controls.
class OrganisationDetailScreen extends ConsumerStatefulWidget {
  const OrganisationDetailScreen({super.key, required this.orgId});
  final String orgId;

  @override
  ConsumerState<OrganisationDetailScreen> createState() => _OrganisationDetailScreenState();
}

class _OrganisationDetailScreenState extends ConsumerState<OrganisationDetailScreen> {
  bool _busy = false;

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(organisationsProvider);
      ref.invalidate(orgSubscriptionsProvider);
      ref.invalidate(organisationProvider(widget.orgId));
      _snack(success);
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Something went wrong.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, {bool danger = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: danger ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700) : null,
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _edit(Organisation org) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditOrgSheet(org: org),
    );
    if (result == null) return;
    await _run(() => ref.read(organisationServiceProvider).update(org.id, result), 'Organisation updated');
  }

  Future<void> _pause(Organisation org) async {
    final until = await showDatePicker(
      context: context,
      helpText: 'Pause until (optional)',
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;
    if (!await _confirm('Pause ${org.name}?', 'Members will lose access and the subscription is suspended. On unpause the end date is extended by the paused duration.', danger: true)) return;
    await _run(() => ref.read(organisationServiceProvider).pause(org.id, expiresAt: until), 'Organisation paused');
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(organisationProvider(widget.orgId));
    final sub = ref.watch(orgSubscriptionsProvider).valueOrNull?[widget.orgId];
    final session = ref.watch(currentUserProvider);
    final df = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(orgAsync.valueOrNull?.name ?? 'Organisation'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (orgAsync.valueOrNull != null)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _busy ? null : () => _edit(orgAsync.valueOrNull!)),
        ],
      ),
      body: orgAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : 'Could not load organisation')),
        data: (org) {
          if (org == null) return const Center(child: Text('Organisation not found'));
          final isActing = session?.orgId == org.id;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Work-in-org action
              Card(
                color: isActing ? Colors.green.shade50 : AppColors.primary.withOpacity(0.06),
                child: ListTile(
                  leading: Icon(isActing ? Icons.check_circle : Icons.login, color: isActing ? Colors.green : AppColors.primary),
                  title: Text(isActing ? 'You are working in this organisation' : 'Work in this organisation'),
                  subtitle: const Text('Manage zones, members, audits, content and approvals'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy
                      ? null
                      : () async {
                          await ref.read(sessionProvider.notifier).actInOrganisation(orgId: org.id, orgName: org.name);
                          if (context.mounted) context.go('/org-admin-dashboard');
                        },
                ),
              ),
              const SizedBox(height: 12),
              _section('Details', [
                _row('Email', org.email),
                _row('Phone', org.contactNo),
                _row('Address', org.address),
                _row('GST', org.gstNo),
                _row('PAN', org.pancardNo),
                _row('Created', org.createdAt == null ? null : df.format(org.createdAt!.toLocal())),
              ]),
              const SizedBox(height: 12),
              _section('Subscription', [
                if (sub == null)
                  const Text('No completed booking for this organisation.')
                else ...[
                  _row('Plan', sub.planLabel),
                  _row('Status', sub.isExpired ? 'Expired' : (sub.isActive ? 'Active' : 'Inactive')),
                  _row('Start', sub.startDate == null ? null : df.format(sub.startDate!.toLocal())),
                  _row('End', sub.endDate == null ? null : df.format(sub.endDate!.toLocal())),
                  _row('Days left', sub.daysLeft?.toString()),
                  _row('Price / year', sub.pricePerYear == null ? null : '₹${sub.pricePerYear}'),
                ],
              ]),
              const SizedBox(height: 12),
              _section('Controls', [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Approved'),
                  subtitle: const Text('Unapproved organisations cannot log in'),
                  value: org.approved,
                  onChanged: _busy
                      ? null
                      : (v) async {
                          if (!v && !await _confirm('Unapprove ${org.name}?', 'All its users will be blocked from logging in.', danger: true)) return;
                          await _run(() => ref.read(organisationServiceProvider).setApproved(org.id, v), v ? 'Organisation approved' : 'Organisation unapproved');
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(org.isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline,
                      color: org.isPaused ? Colors.green : Colors.blueGrey),
                  title: Text(org.isPaused ? 'Unpause organisation' : 'Pause organisation'),
                  subtitle: Text(org.isPaused
                      ? 'Paused ${org.pausedAt == null ? '' : df.format(org.pausedAt!.toLocal())}${org.pauseExpiresAt == null ? '' : ' · auto-unpause ${df.format(org.pauseExpiresAt!.toLocal())}'}'
                      : 'Suspends access and the subscription clock'),
                  onTap: _busy
                      ? null
                      : () async {
                          if (org.isPaused) {
                            if (!await _confirm('Unpause ${org.name}?', 'Access is restored and the subscription end date is extended by the paused duration.')) return;
                            await _run(() => ref.read(organisationServiceProvider).unpause(org.id), 'Organisation unpaused');
                          } else {
                            await _pause(org);
                          }
                        },
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  title: Text('Delete organisation', style: TextStyle(color: Colors.red.shade700)),
                  subtitle: const Text('Fails if zones, users or data still reference it'),
                  onTap: _busy
                      ? null
                      : () async {
                          if (!await _confirm('Delete ${org.name}?', 'This cannot be undone.', danger: true)) return;
                          await _run(() => ref.read(organisationServiceProvider).delete(org.id), 'Organisation deleted');
                          if (context.mounted) context.pop();
                        },
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );

  Widget _row(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _EditOrgSheet extends StatefulWidget {
  const _EditOrgSheet({required this.org});
  final Organisation org;

  @override
  State<_EditOrgSheet> createState() => _EditOrgSheetState();
}

class _EditOrgSheetState extends State<_EditOrgSheet> {
  late final _name = TextEditingController(text: widget.org.name);
  late final _email = TextEditingController(text: widget.org.email ?? '');
  late final _phone = TextEditingController(text: widget.org.contactNo ?? '');
  late final _addr1 = TextEditingController(text: widget.org.addressLine1 ?? '');
  late final _addr2 = TextEditingController(text: widget.org.addressLine2 ?? '');
  late final _gst = TextEditingController(text: widget.org.gstNo ?? '');
  late final _pan = TextEditingController(text: widget.org.pancardNo ?? '');

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _addr1, _addr2, _gst, _pan]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    InputDecoration dec(String l) => InputDecoration(labelText: l, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit organisation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: dec('Name')),
            const SizedBox(height: 10),
            TextField(controller: _email, decoration: dec('Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            TextField(controller: _phone, decoration: dec('Phone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(controller: _addr1, decoration: dec('Address line 1')),
            const SizedBox(height: 10),
            TextField(controller: _addr2, decoration: dec('Address line 2')),
            const SizedBox(height: 10),
            TextField(controller: _gst, decoration: dec('GST number'), textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 10),
            TextField(controller: _pan, decoration: dec('PAN'), textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                if (_name.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  'name': _name.text.trim(),
                  'email': _email.text.trim().toLowerCase(),
                  'contactNo': _phone.text.trim(),
                  'addressLine1': _addr1.text.trim(),
                  'addressLine2': _addr2.text.trim(),
                  'gstNo': _gst.text.trim().toUpperCase(),
                  'pancardNo': _pan.text.trim().toUpperCase(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
