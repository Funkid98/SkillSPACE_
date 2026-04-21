import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'dashboard_screen.dart';
import 'formateur_profile_screen.dart';
import '../services/formateur_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const MainNavigationScreen({super.key, this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}


class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  String _profileImageBase64 = '';
  final FormateurService _formateurService = FormateurService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userId = context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
    if (userId.isEmpty) return;
    final profile = await _formateurService.getProfile(userId);
    if (profile != null && profile.profilePicture.isNotEmpty && mounted) {
      setState(() {
        _profileImageBase64 = profile.profilePicture;
      });
    }
  }

  final List<Widget> _pages = [
    const DashboardScreen(),
    const FormateurProfileScreenWrapper(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main content
          Expanded(
            child: _pages[_selectedIndex == 2 ? 0 : _selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState.loggedInUser;
        final profilePic = user?['profilePicture'] as String?;
        final imageBase64 = (profilePic != null && profilePic.isNotEmpty) ? profilePic : _profileImageBase64;

        return Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1))),
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
                        backgroundImage: MemoryImage(base64Decode(imageBase64)),
                      )
                    else
                      const Icon(Icons.hub, color: Color(0xFFE9652B), size: 30),
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
          _buildNavItem(0, 'Tableau de bord', Icons.grid_view_outlined),
          _buildNavItem(1, 'Mon profil', Icons.person_outline),
          _buildNavItem(2, 'Mes formations', Icons.school_outlined),
          const Spacer(),
          // Logout
          const Divider(),
          _buildNavItem(-1, 'Déconnexion', Icons.logout, color: Colors.grey),
          const SizedBox(height: 20),
        ],
      ),
    );
      },
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, {Color? color}) {
    // Both Dashboard (0) and Mes formations (2) are active when _selectedIndex is 0 or 2
    bool isDashboardActive = _selectedIndex == 0 || _selectedIndex == 2;
    bool isSelected = false;

    if (index == 0 || index == 2) {
      isSelected = isDashboardActive;
    } else {
      isSelected = _selectedIndex == index;
    }

    return InkWell(
      onTap: () async {
        if (index == -1) {
          // Handle Logout
          await context.read<AuthCubit>().logout();
          if (widget.onLogout != null) {
            widget.onLogout!();
          } else {
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const AuthPage(
                          onSuccess: null,
                        )),
                (route) => false,
              );
            }
          }
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
}
