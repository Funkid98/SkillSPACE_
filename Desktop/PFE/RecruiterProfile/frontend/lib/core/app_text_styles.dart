import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── Sections ──────────────────────────────────────────
  static const TextStyle sectionLabel = TextStyle(
    color: AppColors.orange,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    color: AppColors.textGray,
    fontSize: 15,
    height: 1.6,
  );

  // ─── Cards ─────────────────────────────────────────────
  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cardDesc = TextStyle(
    color: AppColors.textGray,
    fontSize: 13,
    height: 1.5,
  );

  // ─── Nav ───────────────────────────────────────────────
  static const TextStyle navBrand = TextStyle(
    color: AppColors.navy,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle navItem = TextStyle(
    color: AppColors.textDark,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // ─── Footer ────────────────────────────────────────────
  static const TextStyle footerText = TextStyle(
    color: AppColors.textGray,
    fontSize: 13,
  );

  static const TextStyle footerBrand = TextStyle(
    color: AppColors.navy,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle footerLink = TextStyle(
    color: AppColors.textGray,
    fontSize: 13,
  );

  // ─── Steps ─────────────────────────────────────────────
  static const TextStyle stepNumber = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w900,
  );
}
