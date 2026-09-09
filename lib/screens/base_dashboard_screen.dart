import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/logout_button.dart';

class BaseDashboardScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const BaseDashboardScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
          ),
          if (actions != null) ...actions!,
          const LogoutButton(),
        ],
      ),
      body: body,
    );
  }
} 