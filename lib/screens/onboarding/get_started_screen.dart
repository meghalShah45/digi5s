import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';

/// Landing screen after the intro: free trial, subscribe, or sign in.
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Get Started'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          children: [
            const Text(
              'Welcome to Digi5S',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose how you want to get started:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _OptionCard(
              icon: Icons.rocket_launch,
              color: const Color(0xFFFF9800),
              title: 'Start Free Trial',
              subtitle: 'Try Digi5S for free and explore all features. No payment required.',
              onTap: () => context.push('/free-trial'),
            ),
            const SizedBox(height: 22),
            _OptionCard(
              icon: Icons.subscriptions,
              color: const Color(0xFF4CAF50),
              title: 'Subscribe',
              subtitle: 'Subscribe your organization and unlock full access.',
              onTap: () => context.push('/subscribe'),
            ),
            const SizedBox(height: 22),
            _OptionCard(
              icon: Icons.login,
              color: AppColors.primary,
              title: 'Sign In',
              subtitle: 'Already have an account? Sign in here.',
              onTap: () => context.push('/login'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3EEF8),
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 8),
                    Text(subtitle, style: TextStyle(fontSize: 15.5, height: 1.4, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
