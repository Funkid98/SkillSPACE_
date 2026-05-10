import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const heroLabel = TextStyle(
    color: AppColors.orange,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  static const heroTitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 55,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -1,
  );

  static const heroTitleLight = TextStyle(
    color: Colors.white,
    fontSize: 55,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -1,
  );

  static const heroSubtitle = TextStyle(
    color: AppColors.textGray,
    fontSize: 20,
    height: 1.6,
  );

  static const heroSubtitleLight = TextStyle(
    color: Colors.white70,
    fontSize: 20,
    height: 1.6,
  );

  static const sectionLabel = TextStyle(
    color: AppColors.orange,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const sectionTitleLight = TextStyle(
    color: Colors.white,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static const sectionSubtitle = TextStyle(
    color: AppColors.textGray,
    fontSize: 15,
    height: 1.6,
  );

  static const sectionSubtitleLight = TextStyle(
    color: Colors.white70,
    fontSize: 15,
    height: 1.6,
  );

  static const cardTitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const cardTitleLight = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const cardDesc = TextStyle(
    color: AppColors.textGray,
    fontSize: 13,
    height: 1.5,
  );

  static const cardDescLight = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    height: 1.5,
  );

  static const navBrand = TextStyle(
    color: AppColors.navy,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const navBrandLight = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const navItem = TextStyle(
    color: AppColors.textDark,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const navItemLight = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const footerBrand = TextStyle(
    color: AppColors.navy,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static const footerBrandLight = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static const footerLink = TextStyle(
    color: AppColors.textGray,
    fontSize: 13,
  );

  static const footerLinkLight = TextStyle(
    color: Colors.white70,
    fontSize: 13,
  );

  static const stepNumber = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w900,
  );
}
