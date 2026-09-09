import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_repository.dart';
import '../auth/session.dart';

/// App bar action that confirms and then logs the user out.
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key, this.color});

  final Color? color;

  static Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authRepositoryProvider).logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return PopupMenuButton<String>(
      icon: Icon(Icons.account_circle_outlined, color: color),
      tooltip: user?.fullName ?? 'Account',
      onSelected: (v) {
        if (v == 'logout') confirmAndLogout(context, ref);
      },
      itemBuilder: (_) => [
        if (user != null)
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(user.email, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text(user.role, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              ],
            ),
          ),
        if (user != null) const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Log out'),
          ),
        ),
      ],
    );
  }
}
