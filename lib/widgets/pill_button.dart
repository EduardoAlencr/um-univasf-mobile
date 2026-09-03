import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PillButtonVariant { primary, secondary, dark }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.icon,
    this.foregroundColorOverride,
  });

  final String label;
  final VoidCallback onPressed;
  final PillButtonVariant variant;
  final String? icon;
  final Color? foregroundColorOverride;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Text(icon!, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: foregroundColorOverride ?? _foreground(),
          ),
        ),
      ],
    );

    final button = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: variant == PillButtonVariant.primary ? AppColors.gradient : null,
        color: variant == PillButtonVariant.primary
            ? null
            : (variant == PillButtonVariant.dark ? AppColors.ink : AppColors.card),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: variant == PillButtonVariant.secondary ? Border.all(color: AppColors.border) : null,
        boxShadow: variant == PillButtonVariant.primary
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: content,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onPressed,
        child: button,
      ),
    );
  }

  Color _foreground() {
    switch (variant) {
      case PillButtonVariant.primary:
        return Colors.white;
      case PillButtonVariant.secondary:
        return AppColors.ink;
      case PillButtonVariant.dark:
        return Colors.white;
    }
  }
}
