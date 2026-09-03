import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showUmToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.5),
      ),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      duration: const Duration(milliseconds: 3200),
    ),
  );
}
