import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModuleSelectionScreen extends StatelessWidget {
  const ModuleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Super Admin',
        'icon': Icons.admin_panel_settings,
        'route': '/super-admin-dashboard',
      },
      {
        'title': 'Org Admin',
        'icon': Icons.business,
        'route': '/org-admin-dashboard',
      },
      {
        'title': 'Zone Leader',
        'icon': Icons.leaderboard,
        'route': '/zone-leader-dashboard',
      },
      {
        'title': 'Zone Member',
        'icon': Icons.group,
        'route': '/zone-member-dashboard',
      },
      {
        'title': 'Viewer',
        'icon': Icons.visibility,
        'route': '/viewer-dashboard',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Module'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: modules.length,
        itemBuilder: (context, index) {
          final module = modules[index];
          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () => context.go(module['route'].toString()),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    module['icon'] as IconData,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    module['title'].toString(),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 