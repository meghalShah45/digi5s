import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api/api_client.dart';
import '../features/organisations/organisation_service.dart';
import '../theme/colors.dart';

/// Super admin: paid signups waiting for approval.
class PendingSubscriptionsScreen extends ConsumerStatefulWidget {
  const PendingSubscriptionsScreen({super.key});

  @override
  ConsumerState<PendingSubscriptionsScreen> createState() => _PendingSubscriptionsScreenState();
}

class _PendingSubscriptionsScreenState extends ConsumerState<PendingSubscriptionsScreen> {
  String? _busyOrg;

  Future<void> _refresh() async {
    ref.invalidate(pendingSubscriptionsProvider);
    await ref.read(pendingSubscriptionsProvider.future).catchError((_) => <PendingSubscription>[]);
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }

  Future<void> _approve(PendingSubscription p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve ${p.orgName}?'),
        content: const Text('The organisation and its admin are activated, a new password is generated and emailed to the admin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyOrg = p.orgId);
    try {
      final r = await ref.read(organisationServiceProvider).approvePaidSubscription(p.orgId);
      _snack('Approved. ${r['emailSent'] == true ? 'Credentials emailed.' : 'Email not confirmed; check with the admin.'}');
      ref.invalidate(organisationsProvider);
      await _refresh();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busyOrg = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pendingSubscriptionsProvider);
    final df = DateFormat('d MMM yyyy');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending approvals'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text(e is ApiException ? e.message : 'Could not load pending approvals')),
            Center(child: TextButton(onPressed: _refresh, child: const Text('Retry'))),
          ]),
          data: (items) {
            if (items.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 120),
                Icon(Icons.task_alt, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Center(child: Text('Nothing waiting for approval')),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final p = items[i];
                final busy = _busyOrg == p.orgId;
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.orgName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${p.adminName} · ${p.adminEmail}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        if (p.adminPhone.isNotEmpty) Text(p.adminPhone, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _chip(p.subscriptionName.isEmpty ? 'Plan' : p.subscriptionName, AppColors.primary),
                            if (p.membersLimit != null) _chip('${p.membersLimit} members', Colors.teal),
                            if (p.pricePerYear != null) _chip('₹${p.pricePerYear}/yr', Colors.green),
                            if (p.createdAt != null) _chip(df.format(p.createdAt!.toLocal()), Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                            onPressed: busy ? null : () => _approve(p),
                            icon: busy
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check),
                            label: const Text('Approve and send credentials'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}
