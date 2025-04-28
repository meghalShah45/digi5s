import 'package:flutter/material.dart';
import 'base_dashboard_screen.dart';
import 'home_screen.dart';

class OrgAdminDashboard extends StatelessWidget {
  const OrgAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseDashboardScreen(
      title: 'Organization Admin Dashboard',
      body: const HomeScreen(),
    );
  }
} 