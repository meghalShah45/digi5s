import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api/api_client.dart';
import '../core/auth/session.dart';
import '../core/utils/open_file.dart';
import '../features/red_tags/models/red_tag.dart';
import '../features/red_tags/services/red_tag_service.dart';
import '../theme/colors.dart';

class RedTagDetailsScreen extends ConsumerStatefulWidget {
  final String tagId;
  const RedTagDetailsScreen({Key? key, required this.tagId}) : super(key: key);

  @override
  ConsumerState<RedTagDetailsScreen> createState() => _RedTagDetailsScreenState();
}

class _RedTagDetailsScreenState extends ConsumerState<RedTagDetailsScreen> {
  final _remarksController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _decide(bool approve) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(redTagServiceProvider).approveRedTag(
            id: widget.tagId,
            approve: approve,
            remarks: _remarksController.text,
            adminUserId: user.id,
          );
      ref.invalidate(orgRedTagsProvider);
      ref.invalidate(redTagByIdProvider(widget.tagId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'Red tag approved.' : 'Red tag rejected.'),
          backgroundColor: approve ? Colors.green.shade700 : Colors.red.shade700,
        ));
        _remarksController.clear();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(redTagByIdProvider(widget.tagId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Red Tag Details'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _error(e is ApiException ? e.message : 'Could not load this red tag.'),
        data: (tag) {
          if (tag == null) return _error('Red tag not found.');
          final canDecide = (user?.isAdmin ?? false) && tag.isPending;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orgRedTagsProvider);
              ref.invalidate(redTagByIdProvider(widget.tagId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoCard(tag: tag),
                const SizedBox(height: 16),
                if (tag.path != null && tag.path!.isNotEmpty) ...[
                  _PhotoCard(url: tag.path!),
                  const SizedBox(height: 16),
                ],
                _ActivityCard(activity: tag.activity),
                if (canDecide) ...[
                  const SizedBox(height: 16),
                  _buildDecisionCard(),
                ] else if (tag.isPending) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.hourglass_top, color: Colors.orange),
                      title: const Text('Awaiting organisation admin review'),
                      subtitle: Text('Raised ${DateFormat('d MMM yyyy').format(tag.createdAt.toLocal())}'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _error(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(orgRedTagsProvider);
                ref.invalidate(redTagByIdProvider(widget.tagId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _buildDecisionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Remarks (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _decide(true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _decide(false),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.tag});
  final RedTag tag;

  @override
  Widget build(BuildContext context) {
    final grey = TextStyle(fontSize: 14, color: Colors.grey[700]);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(tag.description.isEmpty ? '(no description)' : tag.description,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                RedTagStatusChip(status: tag.status),
              ],
            ),
            const SizedBox(height: 14),
            if (tag.zoneName.isNotEmpty) Text('Zone: ${tag.zoneName}', style: grey),
            if (tag.email.isNotEmpty) Text('Raised by: ${tag.email}', style: grey),
            Text('Raised on: ${DateFormat('d MMM yyyy, h:mm a').format(tag.createdAt.toLocal())}', style: grey),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final isImage = RegExp(r'\.(png|jpe?g|gif|webp)', caseSensitive: false).hasMatch(url);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openRemoteFile(context, url),
        child: isImage
            ? Image.network(
                url,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(height: 80, child: Center(child: Text('Image unavailable'))),
                loadingBuilder: (_, child, p) => p == null ? child : const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
              )
            : ListTile(leading: Icon(fileIcon(url)), title: const Text('Attachment'), trailing: const Icon(Icons.open_in_new)),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final List<Activity> activity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (activity.isEmpty)
              const Text('No activity recorded')
            else
              for (final a in activity.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: RedTagStatusChip(status: a.status),
                  title: Text(a.description.isEmpty ? a.status : a.description),
                  subtitle: Text('${a.actionBy.isEmpty ? 'system' : a.actionBy} · ${DateFormat('d MMM yyyy, h:mm a').format(a.actionOn.toLocal())}'),
                ),
          ],
        ),
      ),
    );
  }
}

class RedTagStatusChip extends StatelessWidget {
  const RedTagStatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    final color = switch (s) {
      'PENDING' => Colors.orange,
      'APPROVED' || 'COMPLETED' => Colors.green,
      'REJECTED' => Colors.red,
      'VERIFY' => Colors.blue,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(s, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
