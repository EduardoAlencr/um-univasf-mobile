import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeColor { blue, green, orange, red, gray, yellow }

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.color = BadgeColor.blue});

  final String label;
  final BadgeColor color;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  (Color, Color) _colors() {
    switch (color) {
      case BadgeColor.blue:
        return (AppColors.blueSoft, AppColors.blueDark);
      case BadgeColor.green:
        return (AppColors.greenSoft, AppColors.greenText);
      case BadgeColor.orange:
        return (AppColors.orangeSoft, AppColors.orangeText);
      case BadgeColor.red:
        return (AppColors.redSoft, AppColors.redText);
      case BadgeColor.gray:
        return (AppColors.soft2, AppColors.ink2);
      case BadgeColor.yellow:
        return (AppColors.yellowSoft, AppColors.yellowText);
    }
  }
}
