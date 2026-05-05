import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'dashboard_screen.dart';
import 'formateur_profile_screen.dart';
import '../services/formateur_service.dart';
import '../services/dashboard_service.dart';
import '../cubits/trainer_cubit.dart';
import '../cubits/trainer_state.dart';
// Removed invalid cross-package imports to fix URI error

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const MainNavigationScreen({super.key, this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final FormateurService _formateurService = FormateurService();
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available if needed,
    // but BlocProvider will handle it.
  }

  // We'll use a wrapper to provide the Cubit and trigger loading

  final List<Widget> _pages = [
    const DashboardScreen(),
    const FormateurProfileScreenWrapper(),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1000;

    return BlocProvider(
      create: (context) => TrainerCubit(_dashboardService, _formateurService)
        ..fetchAllData(userId),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: isMobile
            ? Column(
                children: [
                  Container(
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFEAE8E3), width: 1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Builder(builder: (localCtx) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SkillSpace',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A))),
                          IconButton(
                            icon: const Icon(Icons.logout,
                                color: Color(0xFFE9652B)),
                            onPressed: () => _showLogoutConfirmation(localCtx),
                          ),
                        ],
                      );
                    }),
                  ),
                  Expanded(
                    child: _pages[_selectedIndex == 2 ? 0 : _selectedIndex],
                  ),
                ],
              )
            : Row(
                children: [
                  // Sidebar (only on desktop)
                  if (!isMobile)
                    Builder(builder: (sideCtx) => _buildSidebar(sideCtx)),
                  // Main content
                  Expanded(
                    child: _pages[_selectedIndex == 2 ? 0 : _selectedIndex],
                  ),
                ],
              ),
        bottomNavigationBar: isMobile
            ? Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex == 2 ? 0 : _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  selectedItemColor: const Color(0xFFE9652B),
                  unselectedItemColor: Colors.grey[400],
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_rounded),
                      activeIcon: Icon(Icons.dashboard_rounded),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline_rounded),
                      activeIcon: Icon(Icons.person_rounded),
                      label: 'Profil',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.school_outlined),
                      activeIcon: Icon(Icons.school_rounded),
                      label: 'Formations',
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSidebar(BuildContext sideCtx) {
    return BlocBuilder<TrainerCubit, TrainerState>(
      builder: (context, trainerState) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState.loggedInUser;
            final profilePic = user?['profilePicture'] as String?;
            final imageBase64 = (profilePic != null && profilePic.isNotEmpty)
                ? profilePic
                : (trainerState.profileData?.profilePicture ?? '');

            return Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    right: BorderSide(color: Colors.grey.withOpacity(0.1))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        if (imageBase64.isNotEmpty)
                          CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                MemoryImage(base64Decode(imageBase64)),
                          )
                        else
                          const Icon(Icons.hub,
                              color: Color(0xFFE9652B), size: 30),
                        const SizedBox(width: 12),
                        Text(
                          'SkillSpace',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Nav Items
                  _buildNavItem(
                      sideCtx, 0, 'Tableau de bord', Icons.grid_view_outlined),
                  _buildNavItem(sideCtx, 1, 'Mon profil', Icons.person_outline),
                  _buildNavItem(
                      sideCtx, 2, 'Mes formations', Icons.school_outlined),
                  const Spacer(),
                  // Logout
                  const Divider(),
                  _buildNavItem(sideCtx, -1, 'Déconnexion', Icons.logout,
                      color: Colors.grey),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, String title, IconData icon,
      {Color? color}) {
    // Both Dashboard (0) and Mes formations (2) are active when _selectedIndex is 0 or 2
    bool isDashboardActive = _selectedIndex == 0 || _selectedIndex == 2;
    bool isSelected = false;

    if (index == 0 || index == 2) {
      isSelected = isDashboardActive;
    } else {
      isSelected = _selectedIndex == index;
    }

    return InkWell(
      onTap: () {
        if (index == -1) {
          // Handle Logout
          _showLogoutConfirmation(context);
          return;
        }
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFB68D).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFE9652B)
                  : (color ?? Colors.grey[700]),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFE9652B)
                    : (color ?? Colors.grey[700]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ANNULER', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE9652B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (widget.onLogout != null) {
                widget.onLogout!();
              }
            },
            child: const Text('DÉCONNEXION'),
          ),
        ],
      ),
    );
  }
}
