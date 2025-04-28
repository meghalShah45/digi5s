import 'package:flutter/material.dart';
import 'base_dashboard_screen.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseDashboardScreen(
      title: 'Super Admin Dashboard',
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            'User Management',
            Icons.people,
            () {
              // Navigate to user management
            },
          ),
          _buildDashboardCard(
            context,
            'Organization Management',
            Icons.business,
            () {
              // Navigate to organization management
            },
          ),
          _buildDashboardCard(
            context,
            'System Settings',
            Icons.settings,
            () {
              // Navigate to system settings
            },
          ),
          _buildDashboardCard(
            context,
            'Reports',
            Icons.assessment,
            () {
              // Navigate to reports
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 