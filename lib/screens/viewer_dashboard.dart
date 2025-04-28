import 'package:flutter/material.dart';
import 'base_dashboard_screen.dart';

class ViewerDashboard extends StatelessWidget {
  const ViewerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseDashboardScreen(
      title: 'Viewer Dashboard',
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            'Overview',
            Icons.dashboard,
            () {
              // Navigate to overview
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
          _buildDashboardCard(
            context,
            'Analytics',
            Icons.analytics,
            () {
              // Navigate to analytics
            },
          ),
          _buildDashboardCard(
            context,
            'Documents',
            Icons.description,
            () {
              // Navigate to documents
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