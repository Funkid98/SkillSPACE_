import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../core/l10n/l10n_cubit.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../cubits/recruiter_profile_cubit.dart';

enum RecruiterTab { dashboard, profile, offers, candidates }

extension RecruiterTabInfo on RecruiterTab {
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case RecruiterTab.dashboard:
        return l10n.dashboard;
      case RecruiterTab.profile:
        return l10n.profile;
      case RecruiterTab.offers:
        return l10n.jobs;
      case RecruiterTab.candidates:
        return l10n.candidatesPageTitle;
    }
  }

  IconData get icon {
    switch (this) {
      case RecruiterTab.dashboard:
        return Icons.dashboard_rounded;
      case RecruiterTab.profile:
        return Icons.person_rounded;
      case RecruiterTab.offers:
        return Icons.work_rounded;
      case RecruiterTab.candidates:
        return Icons.people_rounded;
    }
  }
}

class RecruiterSidebar extends StatelessWidget {
  final RecruiterTab activeTab;
  final ValueChanged<RecruiterTab> onTabSelected;

  const RecruiterSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: isRtl
              ? BorderSide.none
              : const BorderSide(color: AppColors.border, width: 1),
          left: isRtl
              ? const BorderSide(color: AppColors.border, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: BlocBuilder<RecruiterProfileCubit, RecruiterProfileState>(
              builder: (context, state) {
                if (state is RecruiterProfileLoaded) {
                  final profile = state.profile;
                  return Row(
                    children: [
                      if (profile.logoUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              profile.logoUrl,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => const Icon(Icons.business, size: 32, color: AppColors.textGray),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          profile.entreprise.isNotEmpty ? profile.entreprise : 'SkillSpace',
                          style: AppTextStyles.navBrand.copyWith(fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }
                return const Row(
                  children: [
                    Text('SkillSpace', style: AppTextStyles.navBrand),
                  ],
                );
              },
            ),
          ),
          ...RecruiterTab.values.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final tab = entry.value;
              return AnimatedReveal(
                delay: Duration(milliseconds: 100 + (index * 100)),
                direction: RevealDirection.fromLeft,
                child: _NavItem(
                  tab: tab,
                  isActive: tab == activeTab,
                  onTap: () => onTabSelected(tab),
                ),
              );
            },
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _LanguageSelector(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.logout_rounded,
                  size: 18, color: AppColors.textGray),
              label: Text(
                l10n.logout,
                style: const TextStyle(color: AppColors.textGray, fontSize: 14),
              ),
              style: TextButton.styleFrom(
                alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final RecruiterTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.iconBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 20,
                  color: isActive ? AppColors.orange : AppColors.textGray,
                ),
                const SizedBox(width: 12),
                Text(
                  tab.label(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.textDark : AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<L10nCubit>().state;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LangBtn(
              label: 'FR',
              isActive: currentLocale.languageCode == 'fr',
              onTap: () =>
                  context.read<L10nCubit>().setLocale(const Locale('fr')),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _LangBtn(
              label: 'EN',
              isActive: currentLocale.languageCode == 'en',
              onTap: () =>
                  context.read<L10nCubit>().setLocale(const Locale('en')),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _LangBtn(
              label: 'AR',
              isActive: currentLocale.languageCode == 'ar',
              onTap: () =>
                  context.read<L10nCubit>().setLocale(const Locale('ar')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangBtn({
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? AppColors.navy : AppColors.textGray,
          ),
        ),
      ),
    );
  }
}
