import 'package:flutter/material.dart';

import 'colors.dart';

/// Theme shared by the mobile app and the super admin web console.
ThemeData buildAppTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2D2D2D),
        elevation: 0.5,
        centerTitle: true,
      ),
    );
