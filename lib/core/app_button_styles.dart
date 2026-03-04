import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle primaryButton({
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: padding,
    );
  }

  static ButtonStyle outlinedButton({
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.bg,
      side: const BorderSide(color: AppColors.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: padding,
    );
  }
}
