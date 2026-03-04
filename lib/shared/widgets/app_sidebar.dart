import 'package:flutter/material.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/app_text_styles.dart';

enum DashboardTab { tableau, profil, offres, simulation, formations }

extension DashboardTabInfo on DashboardTab {
  String get label {
    switch (this) {
      case DashboardTab.tableau:
        return 'Tableau de bord';
      case DashboardTab.profil:
        return 'Mon profil';
      case DashboardTab.offres:
        return 'Offres d\'emploi';
      case DashboardTab.simulation:
        return 'Simulation entretien';
      case DashboardTab.formations:
        return 'Formations';
    }
  }

  IconData get icon {
    switch (this) {
      case DashboardTab.tableau:
        return Icons.dashboard_outlined;
      case DashboardTab.profil:
        return Icons.person_outline;
      case DashboardTab.offres:
        return Icons.work_outline;
      case DashboardTab.simulation:
        return Icons.chat_bubble_outline;
      case DashboardTab.formations:
        return Icons.school_outlined;
    }
  }
}

// ─── Desktop Sidebar ──────────────────────────────────────────────────────────
class AppSidebar extends StatelessWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabSelected;

  const AppSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Text('SkillSpace', style: AppTextStyles.navBrand),
          ),
          ...DashboardTab.values.map(
            (tab) => _NavItem(
              tab: tab,
              isActive: tab == activeTab,
              onTap: () => onTabSelected(tab),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon:
                  const Icon(Icons.logout, size: 18, color: AppColors.textGray),
              label: const Text(
                'Déconnexion',
                style: TextStyle(color: AppColors.textGray, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Top Bar ───────────────────────────────────────────────────────────
class MobileTopBar extends StatelessWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabSelected;

  const MobileTopBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  void _openDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MobileDrawer(
        activeTab: activeTab,
        onTabSelected: (tab) {
          Navigator.pop(context);
          onTabSelected(tab);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('SkillSpace', style: AppTextStyles.navBrand),
          GestureDetector(
            onTap: () => _openDrawer(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: AppColors.navy, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Drawer ────────────────────────────────────────────────────────────
class _MobileDrawer extends StatelessWidget {
  final DashboardTab activeTab;
  final ValueChanged<DashboardTab> onTabSelected;

  const _MobileDrawer({
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Brand
          const Row(
            children: [
              Text('SkillSpace', style: AppTextStyles.navBrand),
            ],
          ),
          const SizedBox(height: 16),

          // Nav items
          ...DashboardTab.values.map(
            (tab) => _DrawerItem(
              tab: tab,
              isActive: tab == activeTab,
              onTap: () => onTabSelected(tab),
            ),
          ),

          const Divider(height: 32),

          // Logout
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading:
                const Icon(Icons.logout, color: AppColors.textGray, size: 20),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: AppColors.textGray, fontSize: 14),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final DashboardTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.textDark : AppColors.textGray,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item (Desktop) ───────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final DashboardTab tab;
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.iconBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 18,
                  color: isActive ? AppColors.orange : AppColors.textGray,
                ),
                const SizedBox(width: 10),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
