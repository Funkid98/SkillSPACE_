import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/presentation/pages/landing_page.dart';

void main() {
  runApp(const SkillSpaceApp());
}

class SkillSpaceApp extends StatelessWidget {
  const SkillSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LandingPage(),
    );
  }
}
