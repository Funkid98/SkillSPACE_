import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pfe/core/network/cookie_service.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'dashboard_screen.dart';
import 'formateur_profile_screen.dart';
import '../services/formateur_service.dart';
import '../services/dashboard_service.dart';
import '../cubits/trainer_cubit.dart';
import '../cubits/trainer_state.dart';
import '../widgets/mesh_gradient_background.dart';
import 'package:pfe/core/widgets/spline_robot.dart';

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
  final ValueNotifier<Offset?> _mouseNotifier = ValueNotifier<Offset?>(null);

  @override
  void initState() {
    super.initState();
    _loadPersistedIndex();
  }

  @override
  void dispose() {
    _mouseNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedIndex() async {
    try {
      final savedIndex = CookieService.getInt('trainer_active_index');
      if (savedIndex != null && savedIndex < 3) {
        setState(() => _selectedIndex = savedIndex);
      }
    } catch (e) {
      debugPrint('Error loading trainer index: $e');
    }
  }

  Future<void> _updateIndex(int index) async {
    setState(() => _selectedIndex = index);
    CookieService.setInt('trainer_active_index', index);
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

    final isDark = ReactiveMode.isDarkMode(context);
    return BlocProvider(
      create: (context) => TrainerCubit(_dashboardService, _formateurService)
        ..fetchAllData(userId),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Allow background to show
        body: MeshGradientBackground(
          child: isMobile
              ? Column(
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.white.withOpacity(0.7),
                        border: Border(
                            bottom: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFEAE8E3),
                                width: 1)),
                      ),
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Builder(builder: (localCtx) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('SkillSpace',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1E3A8A))),
                                  Row(
                                    children: [
                                      ReactiveThemeBtn.fromScratch(
                                        onTap: () {},
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Icon(
                                            isDark
                                                ? Icons.light_mode_rounded
                                                : Icons.dark_mode_rounded,
                                            color: const Color(0xFFE9652B),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.logout,
                                            color: Color(0xFFE9652B)),
                                        onPressed: () =>
                                            _showLogoutConfirmation(localCtx),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
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
                  onTap: (index) => _updateIndex(index),
                  selectedItemColor: const Color(0xFFE9652B),
                  unselectedItemColor: Colors.grey[400],
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
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

            final isDark = ReactiveMode.isDarkMode(context);
            return MouseRegion(
                onHover: (event) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final localPos = box.globalToLocal(event.position);
                    _mouseNotifier.value = Offset(
                      localPos.dx / box.size.width,
                      localPos.dy / box.size.height,
                    );
                  }
                },
                onExit: (_) {
                  _mouseNotifier.value = null;
                },
                child: Container(
                  width: 260,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.transparent : Colors.white,
                    border: Border(
                      right: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.08),
                          width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.15)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isDark ? 30 : 15,
                        spreadRadius: -5,
                        offset: const Offset(10, 0),
                      ),
                    ],
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // ── Spline 3D background ──────────────────────────
                            if (isDark)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: SplineRobot(
                                    mouseNotifier: _mouseNotifier,
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                  ),
                                ),
                              ),
                            // ── Gradient overlay ──────────────────────────────
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.35, 0.65, 1.0],
                                    colors: isDark
                                        ? [
                                            Colors.black.withValues(alpha: 0.88),
                                            Colors.black.withValues(alpha: 0.62),
                                            Colors.black.withValues(alpha: 0.70),
                                            Colors.black.withValues(alpha: 0.92),
                                          ]
                                        : [
                                            Colors.white.withValues(alpha: 0.8),
                                            Colors.white.withValues(alpha: 0.5),
                                            Colors.white.withValues(alpha: 0.6),
                                            Colors.white.withValues(alpha: 0.9),
                                          ],
                                  ),
                                ),
                              ),
                            ),
                            // ── Sidebar content ────────────────────────────────
                            Column(
                              children: [
                                const SizedBox(height: 30),
                                // Logo
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  child: Row(
                                    children: [
                                      if (imageBase64.isNotEmpty)
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundImage: MemoryImage(
                                              base64Decode(imageBase64)),
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
                                          color: isDark
                                              ? Colors.white
                                              : Colors.blue[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),
                                // Nav Items
                                _buildNavItem(sideCtx, 0, 'Tableau de bord',
                                    Icons.grid_view_outlined),
                                _buildNavItem(sideCtx, 1, 'Mon profil',
                                    Icons.person_outline),
                                _buildNavItem(sideCtx, 2, 'Mes formations',
                                    Icons.school_outlined),
                                const Spacer(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: _ThemeToggle(),
                                ),
                                const SizedBox(height: 16),
                                // Logout
                                const Divider(),
                                _AnimatedLogoutButton(
                                  label: 'Déconnexion',
                                  onTap: () => _showLogoutConfirmation(sideCtx),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ));
          },
        );
      },
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, String title, IconData icon) {
    bool isDashboardActive = _selectedIndex == 0 || _selectedIndex == 2;
    bool isSelected = false;

    if (index == 0 || index == 2) {
      isSelected = isDashboardActive;
    } else {
      isSelected = _selectedIndex == index;
    }

    return _FormateurNavItem(
      title: title,
      icon: icon,
      isActive: isSelected,
      onTap: () {
        if (index == -1) {
          _showLogoutConfirmation(context);
          return;
        }
        _updateIndex(index);
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                'Déconnexion',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Voulez-vous vraiment vous déconnecter de SkillSpace ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Annuler',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        if (widget.onLogout != null) {
                          widget.onLogout!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE9652B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Déconnexion',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: (isDark ? Colors.white : Colors.grey).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ReactiveThemeBtn.fromScratch(
              onTap: () {},
              child: _ThemeBtn(
                icon: Icons.light_mode_rounded,
                label: 'Clair',
                isActive: !isDark,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ReactiveThemeBtn.fromScratch(
              onTap: () {},
              child: _ThemeBtn(
                icon: Icons.dark_mode_rounded,
                label: 'Sombre',
                isActive: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _ThemeBtn({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFFE9652B) : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isActive && !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 14,
              color: isActive
                  ? (isDark ? Colors.white : const Color(0xFFE9652B))
                  : (isDark ? Colors.white60 : Colors.grey[600])),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive
                  ? (isDark ? Colors.white : const Color(0xFF1E3A8A))
                  : (isDark ? Colors.white60 : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormateurNavItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FormateurNavItem({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FormateurNavItem> createState() => _FormateurNavItemState();
}

class _FormateurNavItemState extends State<_FormateurNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ReactiveMode.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              _isHovered ? 6 : 0,
              0,
              0,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? (isDark
                      ? const Color(0xFFE9652B).withOpacity(0.15)
                      : const Color(0xFFE9652B).withOpacity(0.1))
                  : (_isHovered
                      ? (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isActive
                    ? const Color(0xFFE9652B).withOpacity(0.3)
                    : (_isHovered
                        ? (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05))
                        : Colors.transparent),
                width: 1,
              ),
              boxShadow: widget.isActive || _isHovered
                  ? [
                      BoxShadow(
                        color: widget.isActive
                            ? const Color(0xFFE9652B).withOpacity(0.2)
                            : Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.isActive)
                  Positioned(
                    left: -14,
                    top: 2,
                    bottom: 2,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE9652B),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE9652B).withOpacity(0.5),
                              blurRadius: 6,
                            )
                          ]),
                    ),
                  ),
                Row(
                  children: [
                    Icon(
                      widget.icon,
                      size: 20,
                      color: widget.isActive
                          ? const Color(0xFFE9652B)
                          : (_isHovered
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white70 : Colors.grey[700])),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            widget.isActive ? FontWeight.w700 : FontWeight.w500,
                        color: widget.isActive
                            ? const Color(0xFFE9652B)
                            : (_isHovered
                                ? (isDark ? Colors.white : Colors.black87)
                                : (isDark ? Colors.white70 : Colors.grey[700])),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _AnimatedLogoutButton({required this.onTap, required this.label});

  @override
  State<_AnimatedLogoutButton> createState() => _AnimatedLogoutButtonState();
}

class _AnimatedLogoutButtonState extends State<_AnimatedLogoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? Colors.red.withOpacity(0.5)
                    : Colors.red.withOpacity(0.2),
              ),
              color: _isHovered
                  ? Colors.red.withOpacity(0.15)
                  : Colors.red.withOpacity(0.05),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform:
                      Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
                  child: Icon(Icons.logout_rounded,
                      size: 17,
                      color: _isHovered
                          ? Colors.red
                          : Colors.red.withOpacity(0.8)),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        _isHovered ? Colors.red : Colors.red.withOpacity(0.8),
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
