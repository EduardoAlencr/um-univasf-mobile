import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UmAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UmAppBar({super.key, required this.onAvatarTap});

  final VoidCallback onAvatarTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.yellowSoft, blurRadius: 0, spreadRadius: 3),
                    ],
                  ),
                ),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
                    children: [
                      TextSpan(text: 'UM · '),
                      TextSpan(text: 'UNIVASF', style: TextStyle(color: AppColors.blue)),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.blue.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BackRow extends StatelessWidget {
  const BackRow({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '‹ $label',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.blueDark),
            ),
          ),
        ),
      ),
    );
  }
}
