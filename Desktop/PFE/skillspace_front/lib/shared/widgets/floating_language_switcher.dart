import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/app_colors.dart';
import '../../../core/l10n/l10n_cubit.dart';

class FloatingLanguageSwitcher extends StatelessWidget {
  const FloatingLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final currentLocale = context.watch<L10nCubit>().state;

    return Positioned(
      bottom: 24,
      right: isRtl ? null : 24,
      left: isRtl ? 24 : null,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangOption(
                label: 'FR',
                isActive: currentLocale.languageCode == 'fr',
                onTap: () =>
                    context.read<L10nCubit>().setLocale(const Locale('fr')),
              ),
              _LangOption(
                label: 'EN',
                isActive: currentLocale.languageCode == 'en',
                onTap: () =>
                    context.read<L10nCubit>().setLocale(const Locale('en')),
              ),
              _LangOption(
                label: 'AR',
                isActive: currentLocale.languageCode == 'ar',
                onTap: () =>
                    context.read<L10nCubit>().setLocale(const Locale('ar')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.white : AppColors.textGray,
          ),
        ),
      ),
    );
  }
}
