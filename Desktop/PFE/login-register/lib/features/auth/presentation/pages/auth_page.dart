import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_validator/form_validator.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/string_extension.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/forgot_password_cubit.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AuthPage({super.key, this.onSuccess});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  bool _isDarkMode = true; // Default to dark mode
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _entrepriseCtrl = TextEditingController();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  bool _showForgot = false;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _entrepriseCtrl.dispose();
    super.dispose();
  }

  void _transition() {
    _fadeCtrl.reset();
    _slideCtrl.reset();
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  void _showForgotFlow() {
    setState(() => _showForgot = true);
    _transition();
  }

  void _hideForgotFlow() {
    context.read<ForgotPasswordCubit>().reset();
    setState(() => _showForgot = false);
    _transition();
  }

  void _onTabSwitch(AuthTab tab) {
    context.read<AuthCubit>().switchTab(tab);
    _transition();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (prev, curr) =>
              (curr.githubAwaitingCode && !prev.githubAwaitingCode) ||
              (curr.isSuccess && !prev.isSuccess),
          listener: (context, state) {
            if (state.githubAwaitingCode) {
              _showGithubCodeDialog(context);
            } else if (state.isSuccess) {
              if (state.loggedInUser != null) {
                // Success (either Login or post-Registration verification)
                final user = state.loggedInUser;
                String welcomeMsg;
                String displayName;
                final company = user?['entreprise']?.toString() ?? '';
                final userRole =
                    (user?['role']?.toString() ?? '').toLowerCase();

                if (company.isNotEmpty ||
                    userRole == 'recruiter' ||
                    userRole == 'recruteur') {
                  displayName = company.isNotEmpty
                      ? company
                      : user?['email']?.toString() ?? 'Entreprise';
                  welcomeMsg = 'Bienvenue $displayName !';
                } else {
                  final firstName = user?['firstName']?.toString() ?? '';
                  displayName = firstName.isNotEmpty
                      ? firstName.capitalize()
                      : user?['email']?.toString() ?? 'Utilisateur';
                  welcomeMsg = 'Bienvenue, $displayName !';
                }
                AppToast.showSuccess(context, welcomeMsg);
                if (widget.onSuccess != null) {
                  widget.onSuccess!();
                }
              } else if (state.tab == AuthTab.register) {
                // This branch is now only for cases where registration
                // doesn't immediately log in (though we've moved to verification)
                AppToast.showSuccess(context, 'Compte créé avec succès !');
                context.read<AuthCubit>().switchTab(AuthTab.login);
                context.read<AuthCubit>().clearSuccess();
              }
            }
          },
        ),
      ],
      child: _VibrantBackground(
        isDark: _isDarkMode,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      _isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      key: ValueKey(_isDarkMode),
                      color:
                          _isDarkMode ? Colors.amber[300] : Colors.indigo[900],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1000;

              if (isWide) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _WideHeroContent(isDark: _isDarkMode),
                        ),
                        const SizedBox(width: 80),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: _AuthFormContent(
                                isDarkMode: _isDarkMode,
                                showForgot: _showForgot,
                                fadeAnim: _fadeAnim,
                                slideAnim: _slideAnim,
                                onTabSwitch: _onTabSwitch,
                                onForgotFlow: _showForgotFlow,
                                onHideForgotFlow: _hideForgotFlow,
                                loginFormKey: _loginFormKey,
                                registerFormKey: _registerFormKey,
                                emailCtrl: _emailCtrl,
                                passCtrl: _passCtrl,
                                firstCtrl: _firstCtrl,
                                lastCtrl: _lastCtrl,
                                entrepriseCtrl: _entrepriseCtrl,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _HeroPanel(isDark: _isDarkMode, isPlayful: true),
                      const _TrailLine(),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                            child: _AuthFormContent(
                              isDarkMode: _isDarkMode,
                              showForgot: _showForgot,
                              fadeAnim: _fadeAnim,
                              slideAnim: _slideAnim,
                              onTabSwitch: _onTabSwitch,
                              onForgotFlow: _showForgotFlow,
                              onHideForgotFlow: _hideForgotFlow,
                              loginFormKey: _loginFormKey,
                              registerFormKey: _registerFormKey,
                              emailCtrl: _emailCtrl,
                              passCtrl: _passCtrl,
                              firstCtrl: _firstCtrl,
                              lastCtrl: _lastCtrl,
                              entrepriseCtrl: _entrepriseCtrl,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showGithubCodeDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🔑 Connexion GitHub',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Votre navigateur va s\'ouvrir avec une page GitHub.\n\nCopiez le code affiché sur cette page, puis collez-le ici :',
              style: TextStyle(fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              decoration: InputDecoration(
                hintText: 'Coller le code ici...',
                prefixIcon: const Icon(Icons.code_rounded,
                    size: 18, color: AppTheme.textGrey),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a2666),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthCubit>().submitGithubCode(codeCtrl.text);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Panel ───────────────────────────────────────────────────────────────
class _HeroPanel extends StatelessWidget {
  final bool isDark;
  final bool isPlayful;
  const _HeroPanel({required this.isDark, required this.isPlayful});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2B6B).withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8622A), Color(0xFFFF8A50)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8622A).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text('SkillSpace',
                  style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 28),
          Text('Vos compétences sont\nvotre meilleur atout',
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  height: 1.2,
                  letterSpacing: -1.0)),
          const SizedBox(height: 12),
          Text(
            'La plateforme IA qui connecte les talents\naux meilleures opportunités.',
            style: TextStyle(
                color:
                    isDark ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                fontSize: 14,
                height: 1.6),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _StatChip(
                  value: '15k+',
                  label: 'Talents',
                  isDark: isDark,
                  isPlayful: isPlayful),
              const SizedBox(width: 12),
              _StatChip(
                  value: '150+',
                  label: 'Entreprises',
                  isDark: isDark,
                  isPlayful: isPlayful),
              const SizedBox(width: 12),
              _StatChip(
                  value: '87%',
                  label: 'Satisfaction',
                  isDark: isDark,
                  isPlayful: isPlayful),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatefulWidget {
  final String value;
  final String label;
  final bool isPlayful;
  final bool isDark;
  const _StatChip(
      {required this.value,
      required this.label,
      required this.isDark,
      required this.isPlayful});

  @override
  State<_StatChip> createState() => _StatChipState();
}

class _StatChipState extends State<_StatChip> {
  Offset _offset = Offset.zero;

  void _runAway() {
    if (!widget.isPlayful) return;
    setState(() {
      final random = math.Random();
      _offset = Offset(
        (random.nextDouble() - 0.5) * 180,
        (random.nextDouble() - 0.5) * 180,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => _runAway(),
        onExit: (_) => setState(() => _offset = Offset.zero),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFF1E2B6B).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: widget.isDark
                    ? Colors.white.withOpacity(0.12)
                    : const Color(0xFF1E2B6B).withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Text(widget.value,
                  style: TextStyle(
                      color: widget.isDark
                          ? Colors.white
                          : const Color(0xFF1E2B6B),
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.grey[500],
                      fontSize: 9.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab Switcher ─────────────────────────────────────────────────────────────
class _TabSwitcher extends StatelessWidget {
  final AuthTab selected;
  final void Function(AuthTab) onSwitch;
  final bool isDark;
  const _TabSwitcher(
      {required this.selected, required this.onSwitch, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFF1E2B6B).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _TabItem(
              label: 'Connexion',
              active: selected == AuthTab.login,
              isDark: isDark,
              onTap: () => onSwitch(AuthTab.login)),
          const SizedBox(width: 8),
          _TabItem(
              label: 'Inscription',
              active: selected == AuthTab.register,
              isDark: isDark,
              onTap: () => onSwitch(AuthTab.register)),
        ],
      ),
    );
  }
}

class _TrailLine extends StatelessWidget {
  const _TrailLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFE8622A).withOpacity(0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  const _TabItem(
      {required this.label,
      required this.active,
      required this.onTap,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE8622A) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: const Color(0xFFE8622A).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? Colors.white
                      : (isDark
                          ? Colors.white.withOpacity(0.5)
                          : const Color(0xFF1E2B6B).withOpacity(0.5)),
                  fontSize: 15)),
        ),
      ),
    );
  }
}

// ─── Shared Label ─────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, {this.isDark = true});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF1E2B6B).withOpacity(0.8))),
      );
}

// ─── Role Selector ────────────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  final UserRole selected;
  final String sectionLabel;
  final bool isDark;
  const _RoleSelector(
      {required this.selected, this.sectionLabel = 'Rôle', this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(sectionLabel, isDark: isDark),
        Row(
          children: [
            _RoleCard(
                role: UserRole.candidat,
                icon: Icons.school_outlined,
                label: 'Candidat',
                isDark: isDark,
                selected: selected),
            const SizedBox(width: 8),
            _RoleCard(
                role: UserRole.recruteur,
                icon: Icons.business_outlined,
                label: 'Recruteur',
                isDark: isDark,
                selected: selected),
            const SizedBox(width: 8),
            _RoleCard(
                role: UserRole.formateur,
                icon: Icons.analytics_outlined,
                label: 'Formateur',
                isDark: isDark,
                selected: selected),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String label;
  final UserRole selected;
  final bool isDark;
  const _RoleCard(
      {required this.role,
      required this.icon,
      required this.label,
      required this.isDark,
      required this.selected});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<AuthCubit>().selectRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8622A).withOpacity(0.15)
                : (isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFFE8622A)
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.3)),
                width: isSelected ? 2 : 1),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFE8622A).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? const Color(0xFFE8622A)
                    : (isDark
                        ? Colors.white.withOpacity(0.5)
                        : const Color(0xFF1E2B6B).withOpacity(0.4)),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFFE8622A)
                          : (isDark
                              ? Colors.white.withOpacity(0.6)
                              : const Color(0xFF1E2B6B).withOpacity(0.6)))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Form ───────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final AuthState state;
  final bool isDark;
  final VoidCallback onForgot;
  const _LoginForm(
      {required this.formKey,
      required this.emailCtrl,
      required this.passCtrl,
      required this.state,
      required this.isDark,
      required this.onForgot});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StaggeredReveal(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Se Connecter',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E2B6B),
                          letterSpacing: -1.0)),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 2,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              )),
          const SizedBox(height: 24),
          if (state.error != null) ...[
            _StaggeredReveal(index: 2, child: _ErrorBanner(state.error!)),
            const SizedBox(height: 10),
          ],
          _StaggeredReveal(index: 3, child: _Label('Email', isDark: isDark)),
          _StaggeredReveal(
              index: 4,
              child: TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                    fontSize: 15),
                decoration: _inputDecoration(
                  hint: 'vous@exemple.com',
                  icon: Icons.mail_outline_rounded,
                  isDark: isDark,
                ),
                validator: ValidationBuilder()
                    .required('Email requis')
                    .email('Email invalide')
                    .build(),
              )),
          const SizedBox(height: 16),
          _StaggeredReveal(
              index: 5, child: _Label('Mot de passe', isDark: isDark)),
          _StaggeredReveal(
              index: 6,
              child: TextFormField(
                controller: passCtrl,
                obscureText: !state.passwordVisible,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                    fontSize: 15),
                decoration: _inputDecoration(
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.passwordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF1E2B6B).withOpacity(0.5),
                      size: 18,
                    ),
                    onPressed: () => context.read<AuthCubit>().togglePassword(),
                  ),
                ),
                validator:
                    ValidationBuilder().required('Mot de passe requis').build(),
              )),
          const SizedBox(height: 20),
          _StaggeredReveal(
              index: 7,
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: state.staySignedIn,
                      activeColor: const Color(0xFFE8622A),
                      checkColor: Colors.white,
                      side: BorderSide(
                          color:
                              (isDark ? Colors.white : const Color(0xFF1E2B6B))
                                  .withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: (_) =>
                          context.read<AuthCubit>().toggleStaySignedIn(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.read<AuthCubit>().toggleStaySignedIn(),
                    child: Text(
                      'Rester connecté(e)',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )),
          const SizedBox(height: 20),
          _StaggeredReveal(
              index: 8,
              child: _RoleSelector(selected: state.role, isDark: isDark)),
          const SizedBox(height: 28),
          _StaggeredReveal(
              index: 9,
              child: _SubmitButton(
                label: 'Se connecter',
                isLoading: state.isLoading,
                onTap: () {
                  if (formKey.currentState?.validate() ?? false) {
                    context
                        .read<AuthCubit>()
                        .login(emailCtrl.text, passCtrl.text);
                  }
                },
              )),
          const SizedBox(height: 24),
          _StaggeredReveal(index: 10, child: _OrDivider(isDark: isDark)),
          const SizedBox(height: 24),
          _StaggeredReveal(
              index: 11,
              child: _SocialLoginButtons(
                isLoading: state.isLoading,
                isDark: isDark,
                onGoogleTap: () => context.read<AuthCubit>().signInWithGoogle(),
                onGithubTap: () => context.read<AuthCubit>().signInWithGithub(),
              )),
          const SizedBox(height: 14),
          _StaggeredReveal(
              index: 12,
              child: Center(
                child: TextButton(
                  onPressed: onForgot,
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE8622A)),
                  child: const Text('Mot de passe oublié ?',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Register Form ────────────────────────────────────────────────────────────
class _RegisterForm extends StatelessWidget {
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController entrepriseCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final GlobalKey<FormState> formKey;
  final AuthState state;
  final bool isDark;
  const _RegisterForm(
      {required this.formKey,
      required this.firstCtrl,
      required this.lastCtrl,
      required this.entrepriseCtrl,
      required this.emailCtrl,
      required this.passCtrl,
      required this.state,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StaggeredReveal(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Créer un Compte',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color:
                              isDark ? Colors.white : const Color(0xFF1E2B6B),
                          letterSpacing: -1.0)),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 2,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              )),
          const SizedBox(height: 24),
          if (state.error != null) ...[
            _StaggeredReveal(index: 2, child: _ErrorBanner(state.error!)),
            const SizedBox(height: 10),
          ],
          if (state.role != UserRole.recruteur)
            _StaggeredReveal(
                index: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Prénom', isDark: isDark),
                            TextFormField(
                              controller: firstCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                  hint: 'Jean', isDark: isDark),
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E2B6B),
                                  fontSize: 15),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-ZÀ-ÿ\s-]')),
                              ],
                              validator: ValidationBuilder()
                                  .required('Prénom requis')
                                  .minLength(4, 'Minimum 4 caractères')
                                  .build(),
                            ),
                          ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Nom', isDark: isDark),
                            TextFormField(
                              controller: lastCtrl,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E2B6B),
                                  fontSize: 15),
                              decoration: _inputDecoration(
                                  hint: 'Dupont', isDark: isDark),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-ZÀ-ÿ\s-]')),
                              ],
                              validator: ValidationBuilder()
                                  .required('Nom requis')
                                  .minLength(4, 'Minimum 4 caractères')
                                  .build(),
                            ),
                          ]),
                    ),
                  ],
                )),
          if (state.role == UserRole.recruteur) ...[
            const SizedBox(height: 16),
            _StaggeredReveal(
                index: 3,
                child: _Label('Nom de l\'entreprise', isDark: isDark)),
            _StaggeredReveal(
                index: 4,
                child: TextFormField(
                  controller: entrepriseCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                      fontSize: 15),
                  decoration: _inputDecoration(
                    hint: 'SkillSpace Inc.',
                    icon: Icons.business_rounded,
                    isDark: isDark,
                  ),
                  validator: state.role == UserRole.recruteur
                      ? ValidationBuilder()
                          .required('Nom de l\'entreprise requis')
                          .build()
                      : null,
                )),
          ],
          const SizedBox(height: 16),
          _StaggeredReveal(index: 5, child: _Label('Email', isDark: isDark)),
          _StaggeredReveal(
              index: 6,
              child: TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                    fontSize: 15),
                decoration: _inputDecoration(
                  hint: 'vous@exemple.com',
                  icon: Icons.mail_outline_rounded,
                  isDark: isDark,
                ),
                validator: ValidationBuilder()
                    .required('Email requis')
                    .email('Email invalide')
                    .build(),
              )),
          const SizedBox(height: 16),
          _StaggeredReveal(
              index: 7, child: _Label('Mot de passe', isDark: isDark)),
          _StaggeredReveal(
              index: 8,
              child: TextFormField(
                controller: passCtrl,
                obscureText: !state.passwordVisible,
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                    fontSize: 15),
                decoration: _inputDecoration(
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.passwordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF1E2B6B).withOpacity(0.5),
                      size: 18,
                    ),
                    onPressed: () => context.read<AuthCubit>().togglePassword(),
                  ),
                ),
                validator: ValidationBuilder()
                    .required('Mot de passe requis')
                    .minLength(6, 'Minimum 6 caractères')
                    .build(),
              )),
          const SizedBox(height: 20),
          _StaggeredReveal(
              index: 9,
              child: _RoleSelector(
                  selected: state.role,
                  sectionLabel: 'Je suis un(e)',
                  isDark: isDark)),
          const SizedBox(height: 28),
          _StaggeredReveal(
              index: 10,
              child: _SubmitButton(
                label: 'Créer mon compte',
                isLoading: state.isLoading,
                onTap: () {
                  if (formKey.currentState?.validate() ?? false) {
                    context.read<AuthCubit>().register(
                          firstCtrl.text,
                          lastCtrl.text,
                          emailCtrl.text,
                          passCtrl.text,
                          entreprise: entrepriseCtrl.text,
                        );
                  }
                },
              )),
          const SizedBox(height: 24),
          _StaggeredReveal(index: 11, child: _OrDivider(isDark: isDark)),
          const SizedBox(height: 24),
          _StaggeredReveal(
              index: 12,
              child: _SocialLoginButtons(
                isLoading: state.isLoading,
                isDark: isDark,
                onGoogleTap: () => context.read<AuthCubit>().signInWithGoogle(),
                onGithubTap: () => context.read<AuthCubit>().signInWithGithub(),
              )),
          const SizedBox(height: 24),
          _StaggeredReveal(
              index: 13,
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
                            .withOpacity(0.4)),
                    children: const [
                      TextSpan(text: 'En vous inscrivant, vous acceptez nos '),
                      TextSpan(
                          text: 'CGU',
                          style: TextStyle(
                              color: Color(0xFFF7931E),
                              fontWeight: FontWeight.w700)),
                      TextSpan(text: ' et '),
                      TextSpan(
                          text: 'politique de confidentialité',
                          style: TextStyle(
                              color: Color(0xFFF7931E),
                              fontWeight: FontWeight.w700)),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Signup Verification Flow ────────────────────────────────────────────────
class _SignupVerificationFlow extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDark;
  const _SignupVerificationFlow({required this.onBack, required this.isDark});

  @override
  State<_SignupVerificationFlow> createState() =>
      _SignupVerificationFlowState();
}

class _SignupVerificationFlowState extends State<_SignupVerificationFlow> {
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              emoji: '🛡️',
              currentStep: 2,
              onBack: widget.onBack,
              isDark: widget.isDark,
              title: 'Vérifiez votre email',
              subtitle: 'Un code a été envoyé à ${state.verificationEmail}.',
            ),
            if (state.error != null) ...[
              _ErrorBanner(state.error!),
              const SizedBox(height: 10),
            ],
            _Label('Code de vérification', isDark: widget.isDark),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  color:
                      widget.isDark ? Colors.white : const Color(0xFF1E2B6B)),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration(
                hint: '1234',
                icon: Icons.verified_user_outlined,
                isDark: widget.isDark,
              ),
              onChanged: (_) => context.read<AuthCubit>().clearError(),
            ),
            const SizedBox(height: 28),
            _SubmitButton(
              label: 'Vérifier mon compte',
              isLoading: state.isLoading,
              onTap: () {
                if (_otpCtrl.text.isNotEmpty) {
                  context.read<AuthCubit>().verifySignup(_otpCtrl.text);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FORGOT PASSWORD FLOW
// ═════════════════════════════════════════════════════════════════════════════

class _ForgotPasswordFlow extends StatelessWidget {
  final VoidCallback onBack;
  final bool isDark;
  const _ForgotPasswordFlow({required this.onBack, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                      .animate(anim),
              child: child,
            ),
          ),
          child: switch (state.step) {
            ForgotStep.email => _ForgotStepEmail(
                key: const ValueKey('fp_email'),
                onBack: onBack,
                isDark: isDark),
            ForgotStep.otp => _ForgotStepOtp(
                key: const ValueKey('fp_otp'), onBack: onBack, isDark: isDark),
            ForgotStep.newPassword => _ForgotStepNewPass(
                key: const ValueKey('fp_pass'), onBack: onBack, isDark: isDark),
            ForgotStep.success => _ForgotSuccess(
                key: const ValueKey('fp_ok'), onDone: onBack, isDark: isDark),
          },
        );
      },
    );
  }
}

class _ForgotStepEmail extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDark;
  const _ForgotStepEmail(
      {super.key, required this.onBack, required this.isDark});

  @override
  State<_ForgotStepEmail> createState() => _ForgotStepEmailState();
}

class _ForgotStepEmailState extends State<_ForgotStepEmail> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepHeader(
                emoji: '📬',
                currentStep: 1,
                onBack: widget.onBack,
                isDark: widget.isDark,
                title: 'Mot de passe oublié',
                subtitle: 'Entrez votre e-mail pour recevoir un code.',
              ),
              if (state.error != null) ...[
                _ErrorBanner(state.error!),
                const SizedBox(height: 10),
              ],
              _Label('Email', isDark: widget.isDark),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                    color:
                        widget.isDark ? Colors.white : const Color(0xFF1E2B6B)),
                decoration: _inputDecoration(
                  hint: 'vous@exemple.com',
                  isDark: widget.isDark,
                ),
                validator: ValidationBuilder()
                    .required('Email requis')
                    .email('Email invalide')
                    .build(),
              ),
              const SizedBox(height: 28),
              _SubmitButton(
                label: 'Envoyer le code',
                isLoading: state.isLoading,
                onTap: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    context
                        .read<ForgotPasswordCubit>()
                        .sendOtp(_emailCtrl.text);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ForgotStepOtp extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDark;
  const _ForgotStepOtp({super.key, required this.onBack, required this.isDark});

  @override
  State<_ForgotStepOtp> createState() => _ForgotStepOtpState();
}

class _ForgotStepOtpState extends State<_ForgotStepOtp> {
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              emoji: '🔢',
              currentStep: 2,
              onBack: () => context.read<ForgotPasswordCubit>().reset(),
              isDark: widget.isDark,
              title: 'Code de vérification',
              subtitle: 'Entrez le code envoyé à ${state.email}.',
            ),
            if (state.error != null) ...[
              _ErrorBanner(state.error!),
              const SizedBox(height: 10),
            ],
            _Label('Code OTP', isDark: widget.isDark),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  color:
                      widget.isDark ? Colors.white : const Color(0xFF1E2B6B)),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration(
                hint: '123456',
                isDark: widget.isDark,
              ),
            ),
            const SizedBox(height: 28),
            _SubmitButton(
              label: 'Vérifier',
              isLoading: state.isLoading,
              onTap: () =>
                  context.read<ForgotPasswordCubit>().verifyOtp(_otpCtrl.text),
            ),
          ],
        );
      },
    );
  }
}

class _ForgotStepNewPass extends StatefulWidget {
  final VoidCallback onBack;
  final bool isDark;
  const _ForgotStepNewPass(
      {super.key, required this.onBack, required this.isDark});

  @override
  State<_ForgotStepNewPass> createState() => _ForgotStepNewPassState();
}

class _ForgotStepNewPassState extends State<_ForgotStepNewPass> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              emoji: '🔒',
              currentStep: 3,
              onBack: () => context.read<ForgotPasswordCubit>().reset(),
              isDark: widget.isDark,
              title: 'Nouveau mot de passe',
              subtitle: 'Choisissez un mot de passe sécurisé.',
            ),
            if (state.error != null) ...[
              _ErrorBanner(state.error!),
              const SizedBox(height: 10),
            ],
            _Label('Mot de passe', isDark: widget.isDark),
            TextField(
              controller: _passCtrl,
              obscureText: !state.passwordVisible,
              style: TextStyle(
                  color:
                      widget.isDark ? Colors.white : const Color(0xFF1E2B6B)),
              decoration: _inputDecoration(
                hint: '••••••••',
                isDark: widget.isDark,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    state.passwordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: widget.isDark
                        ? Colors.white70
                        : const Color(0xFF1E2B6B).withOpacity(0.5),
                    size: 18,
                  ),
                  onPressed: () =>
                      context.read<ForgotPasswordCubit>().togglePassword(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Label('Confirmer', isDark: widget.isDark),
            TextField(
              controller: _confirmCtrl,
              obscureText: !state.confirmPasswordVisible,
              style: TextStyle(
                  color:
                      widget.isDark ? Colors.white : const Color(0xFF1E2B6B)),
              decoration: _inputDecoration(
                hint: '••••••••',
                isDark: widget.isDark,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    state.confirmPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: widget.isDark
                        ? Colors.white70
                        : const Color(0xFF1E2B6B).withOpacity(0.5),
                    size: 18,
                  ),
                  onPressed: () => context
                      .read<ForgotPasswordCubit>()
                      .toggleConfirmPassword(),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SubmitButton(
              label: 'Réinitialiser',
              isLoading: state.isLoading,
              onTap: () => context
                  .read<ForgotPasswordCubit>()
                  .resetPassword(_passCtrl.text, _confirmCtrl.text),
            ),
          ],
        );
      },
    );
  }
}

class _ForgotSuccess extends StatelessWidget {
  final VoidCallback onDone;
  final bool isDark;
  const _ForgotSuccess({super.key, required this.onDone, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF2ECC71).withOpacity(0.3), width: 2),
          ),
          child: const Center(child: Text('✅', style: TextStyle(fontSize: 38))),
        ),
        const SizedBox(height: 24),
        Text('Mot de passe\nréinitialisé !',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                height: 1.3)),
        const SizedBox(height: 10),
        Text(
          'Votre mot de passe a été mis à jour.\nVous pouvez vous connecter.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white70 : Colors.grey[600],
              height: 1.5),
        ),
        const SizedBox(height: 36),
        _SubmitButton(label: 'Se connecter', isLoading: false, onTap: onDone),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final int currentStep;
  final bool isDark;
  const _StepHeader(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.onBack,
      required this.currentStep,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
                          .withOpacity(0.1)),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ],
                ),
                child: Icon(Icons.arrow_back_rounded,
                    size: 18, color: isDark ? Colors.white : AppTheme.textDark),
              ),
            ),
            const Spacer(),
            Row(
              children: List.generate(3, (i) {
                final done = i < currentStep;
                final current = i == currentStep - 1;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(left: 4),
                  width: current ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: done ? AppTheme.accent : AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.textDark,
                height: 1.3,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : AppTheme.textGrey)),
        const SizedBox(height: 26),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF5252), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFFF5252),
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Submit Button ────────────────────────────────────────────────────────────
class _SubmitButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _SubmitButton(
      {required this.label, required this.isLoading, required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.96,
        upperBound: 1.0);
    _pressCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _pressCtrl,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFE8622A), Color(0xFFE91E63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFE8622A).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.2)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Social Login Helpers ───────────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  final bool isDark;
  const _OrDivider({this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
                    .withOpacity(0.1),
                thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OU',
              style: TextStyle(
                  color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
                      .withOpacity(0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ),
        Expanded(
            child: Divider(
                color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
                    .withOpacity(0.1),
                thickness: 1)),
      ],
    );
  }
}

class _SocialLoginButtons extends StatelessWidget {
  final bool isLoading;
  final bool isDark;
  final VoidCallback onGoogleTap;
  final VoidCallback onGithubTap;

  const _SocialLoginButtons({
    required this.isLoading,
    required this.isDark,
    required this.onGoogleTap,
    required this.onGithubTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            onTap: isLoading ? null : onGoogleTap,
            isGoogle: true,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SocialButton(
            label: 'GitHub',
            onTap: isLoading ? null : onGithubTap,
            isGoogle: false,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isGoogle;
  final bool isDark;

  const _SocialButton({
    required this.label,
    required this.onTap,
    required this.isGoogle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFF1E2B6B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
                .withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isGoogle ? Icons.g_mobiledata_rounded : Icons.code_rounded,
                color: isGoogle ? const Color(0xFFDB4437) : Colors.white,
                size: isGoogle ? 32 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Staggered Reveal Animation ───────────────────────────────────────────────
class _StaggeredReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final int delayMs;
  const _StaggeredReveal({
    required this.child,
    this.index = 0,
    // ignore: unused_element
    this.delayMs = 100,
  });

  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs + (widget.index * 60)),
        () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

InputDecoration _inputDecoration(
    {required String hint, IconData? icon, bool isDark = true}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
        color:
            (isDark ? Colors.white : const Color(0xFF1E2B6B)).withOpacity(0.3),
        fontSize: 14),
    prefixIcon: icon != null
        ? Icon(icon,
            size: 18,
            color: isDark
                ? Colors.white70
                : const Color(0xFF1E2B6B).withOpacity(0.7))
        : null,
    filled: true,
    fillColor: isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFF1E2B6B).withOpacity(0.03),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
          color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
              .withOpacity(0.05)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
          color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
              .withOpacity(0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: Color(0xFFE8622A), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
    ),
  );
}

// ─── Custom Background & Glass Card ──────────────────────────────────────────

class _VibrantBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _VibrantBackground({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF001220) : const Color(0xFFF8FAFC),
        image: isDark
            ? const DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2070&auto=format&fit=crop'),
                fit: BoxFit.cover,
                opacity: 0.1,
              )
            : null,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: _GlowSphere(
                color:
                    const Color(0xFFE8622A).withOpacity(isDark ? 0.15 : 0.12),
                size: 500),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: _GlowSphere(
                color: const Color(0xFF1E3A8A).withOpacity(isDark ? 0.2 : 0.15),
                size: 600),
          ),
          Positioned(
            top: 200,
            left: 100,
            child: _GlowSphere(
                color: const Color(0xFFE8622A).withOpacity(isDark ? 0.1 : 0.08),
                size: 300),
          ),
          child,
        ],
      ),
    );
  }
}

class _WideHeroContent extends StatelessWidget {
  final bool isDark;
  const _WideHeroContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E2B6B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8622A), Color(0xFFFF8A50)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Text('SkillSpace',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 60),
        Text(
          'Vos compétences sont\nvotre meilleur atout',
          style: TextStyle(
            color: textColor,
            fontSize: 64,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'La plateforme IA qui connecte les talents\naux meilleures opportunités.',
          style: TextStyle(
            color: textColor.withOpacity(0.7),
            fontSize: 18,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 80),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _StatChipWide(value: '15k+', label: 'Talents', isDark: isDark),
            _StatChipWide(value: '150+', label: 'Entreprises', isDark: isDark),
            _StatChipWide(value: '87%', label: 'Satisfaction', isDark: isDark),
          ],
        ),
      ],
    );
  }
}

class _StatChipWide extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  const _StatChipWide(
      {required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E2B6B),
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: (isDark ? Colors.white : const Color(0xFF1E2B6B))
                      .withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AuthFormContent extends StatelessWidget {
  final bool isDarkMode;
  final bool showForgot;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Function(AuthTab) onTabSwitch;
  final VoidCallback onForgotFlow;
  final VoidCallback onHideForgotFlow;
  final GlobalKey<FormState> loginFormKey;
  final GlobalKey<FormState> registerFormKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController firstCtrl;
  final TextEditingController lastCtrl;
  final TextEditingController entrepriseCtrl;

  const _AuthFormContent({
    required this.isDarkMode,
    required this.showForgot,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onTabSwitch,
    required this.onForgotFlow,
    required this.onHideForgotFlow,
    required this.loginFormKey,
    required this.registerFormKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.firstCtrl,
    required this.lastCtrl,
    required this.entrepriseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showForgot && !authState.awaitingVerification) ...[
              _TabSwitcher(
                selected: authState.tab,
                isDark: isDarkMode,
                onSwitch: onTabSwitch,
              ),
              const SizedBox(height: 32),
            ],
            FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: _GlassCard(
                  isDark: isDarkMode,
                  child: showForgot
                      ? _ForgotPasswordFlow(
                          isDark: isDarkMode, onBack: onHideForgotFlow)
                      : authState.awaitingVerification
                          ? _SignupVerificationFlow(
                              isDark: isDarkMode,
                              onBack: () => context
                                  .read<AuthCubit>()
                                  .cancelVerification(),
                            )
                          : authState.tab == AuthTab.login
                              ? _LoginForm(
                                  formKey: loginFormKey,
                                  emailCtrl: emailCtrl,
                                  passCtrl: passCtrl,
                                  state: authState,
                                  isDark: isDarkMode,
                                  onForgot: onForgotFlow,
                                )
                              : _RegisterForm(
                                  formKey: registerFormKey,
                                  firstCtrl: firstCtrl,
                                  lastCtrl: lastCtrl,
                                  entrepriseCtrl: entrepriseCtrl,
                                  emailCtrl: emailCtrl,
                                  passCtrl: passCtrl,
                                  state: authState,
                                  isDark: isDarkMode,
                                ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowSphere extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowSphere({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.6),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : const Color(0xFF1E2B6B).withOpacity(0.06),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
