import 'package:flutter/material.dart';

/// Design tokens extraídos do protótipo HTML (univasf_mobile_prototipo.html).
class AppColors {
  AppColors._();

  static const ink = Color(0xFF1D1B20);
  static const ink2 = Color(0xFF6E6A66);
  static const canvas = Color(0xFFF3F5F7);
  static const card = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF7F8FA);
  static const soft2 = Color(0xFFEDEFF2);
  static const border = Color(0xFFE7E9EC);

  static const blue = Color(0xFF0091DA);
  static const blueDark = Color(0xFF0B6FA8);
  static const blueSoft = Color(0xFFE3F4FD);

  static const gradStart = Color(0xFF00B4F0);
  static const gradEnd = Color(0xFF0077C8);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradStart, gradEnd],
  );

  static const yellow = Color(0xFFFFCB05);
  static const yellowSoft = Color(0xFFFFF4D6);
  static const yellowText = Color(0xFF8A6D00);

  static const green = Color(0xFF46A171);
  static const greenSoft = Color(0xFFE8F1EC);
  static const greenText = Color(0xFF2F7351);

  static const orange = Color(0xFFD5803B);
  static const orangeSoft = Color(0xFFFBEBDE);
  static const orangeText = Color(0xFFA35A1D);

  static const red = Color(0xFFE56458);
  static const redSoft = Color(0xFFFCE9E7);
  static const redText = Color(0xFFB3402F);
}

class AppRadius {
  AppRadius._();
  static const card = 20.0;
  static const hero = 24.0;
  static const pill = 999.0;
  static const module = 20.0;
}

ThemeData buildAppTheme() {
  const baseTextColor = AppColors.ink;
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      surface: AppColors.canvas,
    ),
    fontFamily: 'Segoe UI',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
        color: baseTextColor,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: baseTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        color: AppColors.ink2,
        height: 1.45,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: AppColors.ink2,
      ),
    ),
    dividerColor: AppColors.border,
    splashFactory: NoSplash.splashFactory,
  );
}
