import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/animated_reveal.dart';
import '../cubits/recruiter_profile_cubit.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../../../../shared/widgets/notification_bell.dart';

enum RecruiterTab { dashboard, profile, offers, candidates }

extension RecruiterTabInfo on RecruiterTab {
  String label(BuildContext context) {
    final l10n = RecruiterLocalizations.of(context);
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
  final VoidCallback? onLogout;
  final Locale? currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  const RecruiterSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.onLogout,
    this.currentLocale,
    this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = RecruiterLocalizations.of(context);
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
            padding: const EdgeInsets.fromLTRB(24, 24, 12, 40),
            child: BlocBuilder<RecruiterProfileCubit, RecruiterProfileState>(
              builder: (context, state) {
                Widget nameWidget;
                if (state is RecruiterProfileLoaded) {
                  final profile = state.profile;
                  nameWidget = Row(
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
                              errorBuilder: (ctx, _, __) => const Icon(
                                  Icons.business,
                                  size: 32,
                                  color: AppColors.textGray),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          profile.entreprise.isNotEmpty
                              ? profile.entreprise
                              : 'SkillSpace',
                          style: AppTextStyles.navBrand.copyWith(fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                } else {
                  nameWidget =
                      const Text('SkillSpace', style: AppTextStyles.navBrand);
                }
                return Row(
                  children: [
                    Expanded(child: nameWidget),
                    const NotificationBell(isRecruiter: true),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LanguageSelector(
              currentLocale: currentLocale ?? Localizations.localeOf(context),
              onLocaleChanged: onLocaleChanged,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TextButton.icon(
              onPressed: () => _showLogoutConfirmation(context, onLogout),
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

  void _showLogoutConfirmation(BuildContext context, [VoidCallback? onLogout]) {
    final l10n = RecruiterLocalizations.of(context);
    AwesomeDialog(
      context: context,
      width: 380,
      padding: EdgeInsets.zero,
      dialogType: DialogType.noHeader,
      customHeader: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child:
            const Icon(Icons.logout_rounded, size: 40, color: AppColors.orange),
      ),
      animType: AnimType.scale,
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            l10n.logout,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            'Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.cancel.toUpperCase(),
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await context.read<AuthCubit>().logout();
                        if (context.mounted) {
                          if (onLogout != null) {
                            onLogout();
                          }
                        }
                      },
                      child: Text(
                        l10n.logout.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ).show();
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

class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale>? onLocaleChanged;

  const LanguageSelector({
    required this.currentLocale,
    this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: LangBtn(
              label: 'FR',
              isActive: currentLocale.languageCode == 'fr',
              onTap: () => onLocaleChanged?.call(const Locale('fr')),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: LangBtn(
              label: 'EN',
              isActive: currentLocale.languageCode == 'en',
              onTap: () => onLocaleChanged?.call(const Locale('en')),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: LangBtn(
              label: 'AR',
              isActive: currentLocale.languageCode == 'ar',
              onTap: () => onLocaleChanged?.call(const Locale('ar')),
            ),
          ),
        ],
      ),
    );
  }
}

class LangBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const LangBtn({
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
                    color: Colors.black.withValues(alpha: 0.05),
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
