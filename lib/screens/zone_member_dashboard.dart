import 'package:flutter/material.dart';
import 'base_dashboard_screen.dart';

class ZoneMemberDashboard extends StatelessWidget {
  const ZoneMemberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseDashboardScreen(
      title: 'Zone Member Dashboard',
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            'My Tasks',
            Icons.task,
            () {
              // Navigate to my tasks
            },
          ),
          _buildDashboardCard(
            context,
            'Team Calendar',
            Icons.calendar_today,
            () {
              // Navigate to team calendar
            },
          ),
          _buildDashboardCard(
            context,
            'My Performance',
            Icons.analytics,
            () {
              // Navigate to my performance
            },
          ),
          _buildDashboardCard(
            context,
            'Resources',
            Icons.folder,
            () {
              // Navigate to resources
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