import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_client.dart';
import '../features/organisations/organisation_service.dart';
import '../theme/colors.dart';

/// Super admin: every organisation with its subscription state.
class ActiveOrganizationsScreen extends ConsumerStatefulWidget {
  const ActiveOrganizationsScreen({super.key});

  @override
  ConsumerState<ActiveOrganizationsScreen> createState() => _ActiveOrganizationsScreenState();
}

class _ActiveOrganizationsScreenState extends ConsumerState<ActiveOrganizationsScreen> {
  String _query = '';

  Future<void> _refresh() async {
    ref.invalidate(organisationsProvider);
    ref.invalidate(orgSubscriptionsProvider);
    await ref.read(organisationsProvider.future).catchError((_) => <Organisation>[]);
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organisationsProvider);
    final subs = ref.watch(orgSubscriptionsProvider).valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Organisations'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push('/super-admin/add-organization');
          _refresh();
        },
        icon: const Icon(Icons.add_business),
        label: const Text('New'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search organisations',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: orgsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(children: [
                  const SizedBox(height: 120),
                  Center(child: Text(e is ApiException ? e.message : 'Could not load organisations')),
                  Center(child: TextButton(onPressed: _refresh, child: const Text('Retry'))),
                ]),
                data: (orgs) {
                  final items = orgs.where((o) =>
                      _query.isEmpty || o.name.toLowerCase().contains(_query) || (o.email ?? '').toLowerCase().contains(_query)).toList();
                  if (items.isEmpty) {
                    return ListView(children: const [SizedBox(height: 120), Center(child: Text('No organisations found'))]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrgCard(org: items[i], sub: subs[items[i].id]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  const _OrgCard({required this.org, this.sub});
  final Organisation org;
  final OrgSubscriptionRow? sub;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (!org.approved) chips.add(_chip('Not approved', Colors.orange));
    if (org.isPaused) chips.add(_chip('Paused', Colors.blueGrey));
    if (sub == null) {
      chips.add(_chip('No subscription', Colors.grey));
    } else if (sub!.isExpired || !sub!.isActive && !org.isPaused) {
      chips.add(_chip('${sub!.planLabel} · expired', Colors.red));
    } else {
      final d = sub!.daysLeft;
      chips.add(_chip(d == null ? sub!.planLabel : '${sub!.planLabel} · $d d left', sub!.isFree ? Colors.teal : Colors.green));
    }

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/super-admin/org/${org.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.business, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(org.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    if ((org.email ?? '').isNotEmpty)
                      Text(org.email!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: chips),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
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
