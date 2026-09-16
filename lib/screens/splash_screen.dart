import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Shown while the stored session is being read. The router redirects away
/// as soon as the session state is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/digi5s_logo.png', width: 140, height: 140),
            const SizedBox(height: 40),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
