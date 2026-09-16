import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/api/api_client.dart';
import '../features/organisations/organisation_service.dart';
import '../theme/colors.dart';

const _orange = Color(0xFFFF9800);
const _green = Color(0xFF4CAF50);
const _red = Color(0xFFE53935);

/// Super admin: every organisation with status, subscription and pause control.
class ActiveOrganizationsScreen extends ConsumerStatefulWidget {
  const ActiveOrganizationsScreen({super.key});

  @override
  ConsumerState<ActiveOrganizationsScreen> createState() => _ActiveOrganizationsScreenState();
}

class _ActiveOrganizationsScreenState extends ConsumerState<ActiveOrganizationsScreen> {
  String _query = '';
  bool _pausedOnly = false;
  String? _busyOrg;

  Future<void> _refresh() async {
    ref.invalidate(organisationsProvider);
    ref.invalidate(orgSubscriptionsProvider);
    await ref.read(organisationsProvider.future).catchError((_) => <Organisation>[]);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }

  Future<void> _togglePause(Organisation org) async {
    final unpause = org.isPaused;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(unpause ? 'Unpause ${org.name}?' : 'Pause ${org.name}?'),
        content: Text(unpause
            ? 'Access is restored and the subscription end date is extended by the paused duration.'
            : 'Members lose access and the subscription clock stops until you unpause.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: unpause ? _green : _orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(unpause ? 'Unpause' : 'Pause'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyOrg = org.id);
    try {
      final svc = ref.read(organisationServiceProvider);
      if (unpause) {
        await svc.unpause(org.id);
      } else {
        await svc.pause(org.id);
      }
      _snack(unpause ? 'Organisation unpaused' : 'Organisation paused');
      await _refresh();
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busyOrg = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organisationsProvider);
    final subs = ref.watch(orgSubscriptionsProvider).valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Active Organizations'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D2D2D),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            tooltip: 'New organisation',
            onPressed: () async {
              await context.push('/super-admin/add-organization');
              _refresh();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _refresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: orgsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text(e is ApiException ? e.message : 'Could not load organisations')),
            Center(child: TextButton(onPressed: _refresh, child: const Text('Retry'))),
          ]),
          data: (orgs) {
            final total = orgs.length;
            final paused = orgs.where((o) => o.isPaused).length;
            final active = orgs.where((o) => !o.isPaused && o.approved).length;
            final items = orgs.where((o) {
              if (_pausedOnly && !o.isPaused) return false;
              if (_query.isEmpty) return true;
              return o.name.toLowerCase().contains(_query) || (o.email ?? '').toLowerCase().contains(_query);
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                          decoration: const InputDecoration(
                            hintText: 'Search organizations...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      selected: _pausedOnly,
                      showCheckmark: false,
                      avatar: Icon(Icons.pause, size: 18, color: _pausedOnly ? Colors.white : const Color(0xFF2D2D2D)),
                      label: const Text('Paused Only'),
                      labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _pausedOnly ? Colors.white : const Color(0xFF2D2D2D)),
                      backgroundColor: const Color(0xFFF3EEF8),
                      selectedColor: _orange,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      onSelected: (v) => setState(() => _pausedOnly = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Organization Status Overview', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatBox(icon: Icons.business, label: 'Total', value: total, color: AppColors.primary, bg: const Color(0xFFE3E7F0)),
                          const SizedBox(width: 12),
                          _StatBox(icon: Icons.check_circle, label: 'Active', value: active, color: _green, bg: const Color(0xFFE8F5E9)),
                          const SizedBox(width: 12),
                          _StatBox(icon: Icons.pause_circle_filled, label: 'Paused', value: paused, color: _orange, bg: const Color(0xFFFFF3E0)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(child: Text('No organisations match', style: TextStyle(color: Colors.grey.shade600))),
                  ),
                for (final org in items) ...[
                  _OrgCard(
                    org: org,
                    sub: subs[org.id],
                    busy: _busyOrg == org.id,
                    onTogglePause: () => _togglePause(org),
                    onOpen: () => context.push('/super-admin/org/${org.id}'),
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.label, required this.value, required this.color, required this.bg});
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text('$value', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: color, height: 1)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  const _OrgCard({required this.org, this.sub, required this.busy, required this.onTogglePause, required this.onOpen});
  final Organisation org;
  final OrgSubscriptionRow? sub;
  final bool busy;
  final VoidCallback onTogglePause;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d/M/yyyy');
    final isFree = sub?.isFree ?? true;
    final expired = sub == null || sub!.isExpired;
    final daysLeft = sub?.endDate == null ? null : sub!.endDate!.difference(DateTime.now()).inDays;

    Widget line(IconData icon, String text, Color color, {bool bold = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: TextStyle(fontSize: 16, color: color, fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
            ],
          ),
        );

    return Material(
      color: const Color(0xFFF3EEF8),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.business, size: 30, color: AppColors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(org.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: isFree ? _orange : AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text(isFree ? 'FREE' : 'PAID', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if ((org.email ?? '').isNotEmpty) line(Icons.email, org.email!, Colors.grey.shade700),
              org.isPaused
                  ? line(Icons.pause_circle_filled, 'PAUSED', _orange, bold: true)
                  : org.approved
                      ? line(Icons.check_circle, 'ACTIVE', _green, bold: true)
                      : line(Icons.block, 'NOT APPROVED', _red, bold: true),
              line(expired ? Icons.cancel : Icons.verified, 'Subscription: ${sub == null ? 'None' : (expired ? 'Expired' : 'Active')}',
                  expired ? _red : _green),
              if (sub?.startDate != null) line(Icons.calendar_today, 'Started: ${df.format(sub!.startDate!.toLocal())}', AppColors.primary),
              if (sub?.endDate != null) line(Icons.event, 'Expires: ${df.format(sub!.endDate!.toLocal())}', _orange),
              if (daysLeft != null) line(Icons.schedule, 'Days Left: $daysLeft', daysLeft < 0 ? _red : AppColors.primary),
              const SizedBox(height: 6),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: busy ? null : onTogglePause,
                  style: FilledButton.styleFrom(
                    backgroundColor: org.isPaused ? _green : _orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(org.isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(org.isPaused ? 'Unpause Organization' : 'Pause Organization',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
