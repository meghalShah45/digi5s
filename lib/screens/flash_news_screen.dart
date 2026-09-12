import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/api/api_client.dart';
import '../core/auth/session.dart';
import '../features/flash_news/flash_news.dart';
import '../theme/colors.dart';

/// Flash news for the user's organisation. Admins and zone leaders can
/// create, edit and delete; everyone else sees the active items only.
class FlashNewsScreen extends ConsumerWidget {
  const FlashNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canManage = user?.canManage ?? false;
    final async = ref.watch(orgFlashNewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flash News'), backgroundColor: Colors.white, foregroundColor: const Color(0xFF2D2D2D)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('New'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orgFlashNewsProvider);
          await ref.read(orgFlashNewsProvider.future).catchError((_) => <FlashNews>[]);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            icon: Icons.error_outline,
            text: e is ApiException ? e.message : 'Could not load flash news.',
            action: TextButton(onPressed: () => ref.invalidate(orgFlashNewsProvider), child: const Text('Retry')),
          ),
          data: (all) {
            final items = canManage ? all : all.where((n) => n.isActive).toList();
            if (items.isEmpty) {
              return const _Message(icon: Icons.flash_off_outlined, text: 'No flash news right now.');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _FlashNewsCard(
                news: items[i],
                canManage: canManage,
                onEdit: () => _openEditor(context, ref, existing: items[i]),
                onDelete: () => _confirmDelete(context, ref, items[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {FlashNews? existing}) async {
    final user = ref.read(currentUserProvider);
    final orgId = user?.orgId;
    if (orgId == null || orgId.isEmpty) {
      _snack(context, 'Your account is not linked to an organisation.', error: true);
      return;
    }
    final result = await showModalBottomSheet<_EditorResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FlashNewsEditor(existing: existing),
    );
    if (result == null) return;
    try {
      final svc = ref.read(flashNewsServiceProvider);
      if (existing == null) {
        await svc.create(orgId: orgId, content: result.content, expiryDate: result.expiryDate);
      } else {
        await svc.update(existing.id, content: result.content, expiryDate: result.expiryDate, modifiedBy: user?.id);
      }
      ref.invalidate(orgFlashNewsProvider);
      if (context.mounted) _snack(context, existing == null ? 'Flash news published.' : 'Flash news updated.');
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, e.message, error: true);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, FlashNews news) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete flash news?'),
        content: Text(news.content, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(flashNewsServiceProvider).delete(news.id);
      ref.invalidate(orgFlashNewsProvider);
      if (context.mounted) _snack(context, 'Deleted.');
    } on ApiException catch (e) {
      if (context.mounted) _snack(context, e.message, error: true);
    }
  }

  static void _snack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700),
    );
  }
}

class _FlashNewsCard extends StatelessWidget {
  const _FlashNewsCard({required this.news, required this.canManage, required this.onEdit, required this.onDelete});
  final FlashNews news;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final expired = !news.isActive;
    final df = DateFormat('d MMM yyyy, h:mm a');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expired ? Colors.grey.shade100 : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: expired ? Colors.grey.shade300 : const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flash_on, size: 20, color: expired ? Colors.grey : const Color(0xFFC62828)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(news.content,
                    style: TextStyle(fontSize: 15, height: 1.35, color: expired ? Colors.grey.shade700 : const Color(0xFF2D2D2D))),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                expired ? 'Expired ${df.format(news.expiryDate.toLocal())}' : 'Until ${df.format(news.expiryDate.toLocal())}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (expired) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6)),
                  child: const Text('EXPIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorResult {
  final String content;
  final DateTime expiryDate;
  const _EditorResult(this.content, this.expiryDate);
}

class _FlashNewsEditor extends StatefulWidget {
  const _FlashNewsEditor({this.existing});
  final FlashNews? existing;

  @override
  State<_FlashNewsEditor> createState() => _FlashNewsEditorState();
}

class _FlashNewsEditorState extends State<_FlashNewsEditor> {
  late final TextEditingController _content;
  late DateTime _expiry;

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(text: widget.existing?.content ?? '');
    _expiry = widget.existing?.expiryDate.toLocal() ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiry.isBefore(DateTime.now()) ? DateTime.now() : _expiry,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_expiry));
    setState(() => _expiry = DateTime(date.year, date.month, date.day, time?.hour ?? 23, time?.minute ?? 59));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.existing == null ? 'New flash news' : 'Edit flash news',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _content,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Message',
              hintText: 'What should everyone know?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Show until'),
            subtitle: Text(DateFormat('d MMM yyyy, h:mm a').format(_expiry)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickExpiry,
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              final text = _content.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message')));
                return;
              }
              if (_expiry.isBefore(DateTime.now())) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expiry must be in the future')));
                return;
              }
              Navigator.pop(context, _EditorResult(text, _expiry));
            },
            child: Text(widget.existing == null ? 'Publish' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        if (action != null) Center(child: action),
      ],
    );
  }
}
