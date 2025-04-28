import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';

class Manage5STasksScreen extends StatelessWidget {
  const Manage5STasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Manage 5S Tasks'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.go('/zone-leader-dashboard'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTaskCard(
              context,
              title: 'Create New Task',
              icon: Icons.add_task,
              bgColor: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1565C0),
              onTap: () => context.push('/create-5s-task'),
            ),
            const SizedBox(height: 20),
            _buildTaskCard(
              context,
              title: 'Approve Task',
              icon: Icons.approval,
              bgColor: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              onTap: () => context.push('/approve-5s-task'),
            ),
            const SizedBox(height: 20),
            _buildTaskCard(
              context,
              title: 'My Tasks',
              icon: Icons.task_alt,
              bgColor: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFEF6C00),
              onTap: () => context.push('/my-5s-tasks'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }
} 