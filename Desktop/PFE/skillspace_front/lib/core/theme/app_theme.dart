import 'package:flutter/material.dart';
import '../app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          secondary: AppColors.orange,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ).copyWith(
            overlayColor:
                WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
        ),
      );
}
