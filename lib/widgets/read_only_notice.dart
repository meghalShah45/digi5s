import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/dashboard/dashboard_repository.dart';

/// Shown at the top of any screen that creates or changes data. Renders
/// nothing unless the organisation is read-only (expired / paused / no
/// subscription), in which case it explains why the submit button is disabled.
class ReadOnlyNotice extends ConsumerWidget {
  const ReadOnlyNotice({super.key, this.margin = const EdgeInsets.only(bottom: 16)});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(orgReadOnlyProvider)) return const SizedBox.shrink();
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final why = status == null || !status.exists
        ? 'your organisation has no active subscription'
        : status.isExpired
            ? 'your organisation\'s subscription expired on ${_fmt(status.endDate!)}'
            : 'your organisation is paused';
    final color = Colors.red.shade700;
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'View-only mode: $why. You can browse everything, but nothing can be added or changed until it is renewed.',
              style: TextStyle(color: color, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

/// Builds a submit control that is disabled while the organisation is read-only.
/// `builder` receives `true` when the control must be disabled.
class ReadOnlyGate extends ConsumerWidget {
  const ReadOnlyGate({super.key, required this.builder});

  final Widget Function(BuildContext context, bool readOnly) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => builder(context, ref.watch(orgReadOnlyProvider));
}
