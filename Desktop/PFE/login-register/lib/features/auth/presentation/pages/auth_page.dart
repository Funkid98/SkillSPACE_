import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_validator/form_validator.dart';
import '../../../../core/theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/utils/string_extension.dart';
import '../../../../core/widgets/particle_background.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/forgot_password_cubit.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AuthPage({super.key, this.onSuccess});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
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
      child: ParticleBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                    const _HeroPanel(),
                    const _TrailLine(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                    child: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        return Column(
                          children: [
                            if (!_showForgot)
                              _TabSwitcher(
                                selected: authState.tab,
                                onSwitch: _onTabSwitch,
                              ),
                            if (!_showForgot) const SizedBox(height: 24),
                            FadeTransition(
                              opacity: _fadeAnim,
                              child: SlideTransition(
                                position: _slideAnim,
                                child: _showForgot
                                    ? _ForgotPasswordFlow(
                                        onBack: _hideForgotFlow)
                                    : authState.awaitingVerification
                                        ? _SignupVerificationFlow(
                                            onBack: () => context
                                                .read<AuthCubit>()
                                                .cancelVerification(),
                                          )
                                        : authState.tab == AuthTab.login
                                            ? _LoginForm(
                                                formKey: _loginFormKey,
                                                emailCtrl: _emailCtrl,
                                                passCtrl: _passCtrl,
                                                state: authState,
                                                onForgot: _showForgotFlow,
                                              )
                                            : _RegisterForm(
                                                formKey: _registerFormKey,
                                                firstCtrl: _firstCtrl,
                                                lastCtrl: _lastCtrl,
                                                entrepriseCtrl: _entrepriseCtrl,
                                                emailCtrl: _emailCtrl,
                                                passCtrl: _passCtrl,
                                                state: authState,
                                              ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2666), Color(0xFF243180), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('SkillSpace',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Vos compétences sont\nvotre meilleur atout',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1.3,
                  letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(
            'La plateforme IA qui connecte les talents\naux meilleures opportunités.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 12.5,
                height: 1.5),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              _StatChip(value: '2 000+', label: 'Candidats'),
              SizedBox(width: 8),
              _StatChip(value: '150+', label: 'Entreprises'),
              SizedBox(width: 8),
              _StatChip(value: '93%', label: 'Satisfaction'),
              SizedBox(width: 8),
              _StatChip(value: '45j', label: 'Délai moy.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 9.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Switcher ─────────────────────────────────────────────────────────────
class _TabSwitcher extends StatelessWidget {
  final AuthTab selected;
  final void Function(AuthTab) onSwitch;
  const _TabSwitcher({required this.selected, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFEBE8E2),
          borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TabItem(
              label: 'Connexion',
              active: selected == AuthTab.login,
              onTap: () => onSwitch(AuthTab.login)),
          _TabItem(
              label: 'Inscription',
              active: selected == AuthTab.register,
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
            AppTheme.accent.withOpacity(0.5),
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
  const _TabItem(
      {required this.label, required this.active, required this.onTap});

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
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.textDark : AppTheme.textGrey,
                  fontSize: 14)),
        ),
      ),
    );
  }
}

// ─── Shared Label ─────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppTheme.textDark)),
      );
}

// ─── Role Selector ────────────────────────────────────────────────────────────
class _RoleSelector extends StatelessWidget {
  final UserRole selected;
  final String sectionLabel;
  const _RoleSelector({required this.selected, this.sectionLabel = 'Rôle'});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(sectionLabel),
        Row(
          children: [
            _RoleCard(
                role: UserRole.candidat,
                emoji: '🎓',
                label: 'Candidat',
                selected: selected),
            const SizedBox(width: 8),
            _RoleCard(
                role: UserRole.recruteur,
                emoji: '🏢',
                label: 'Recruteur',
                selected: selected),
            const SizedBox(width: 8),
            _RoleCard(
                role: UserRole.formateur,
                emoji: '📊',
                label: 'Formateur',
                selected: selected),
          ],
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final String emoji;
  final String label;
  final UserRole selected;
  const _RoleCard(
      {required this.role,
      required this.emoji,
      required this.label,
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isSelected ? AppTheme.accent : AppTheme.border,
                width: isSelected ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.accent.withOpacity(0.18)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 14 : 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.accent : AppTheme.textDark)),
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
  final VoidCallback onForgot;
  const _LoginForm(
      {required this.formKey,
      required this.emailCtrl,
      required this.passCtrl,
      required this.state,
      required this.onForgot});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bon retour ! ',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Connectez-vous pour continuer',
              style: TextStyle(fontSize: 13.5, color: AppTheme.textGrey)),
          const SizedBox(height: 26),
          if (state.error != null) ...[
            _ErrorBanner(state.error!),
            const SizedBox(height: 10),
          ],
          const _Label('Email'),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'vous@exemple.com',
              prefixIcon: Icon(Icons.mail_outline_rounded,
                  size: 18, color: AppTheme.textGrey),
            ),
            validator: ValidationBuilder()
                .required('Email requis')
                .email('Email invalide')
                .build(),
          ),
          const SizedBox(height: 16),
          const _Label('Mot de passe'),
          TextFormField(
            controller: passCtrl,
            obscureText: !state.passwordVisible,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppTheme.textGrey),
              suffixIcon: IconButton(
                icon: Icon(
                  state.passwordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textGrey,
                  size: 18,
                ),
                onPressed: () => context.read<AuthCubit>().togglePassword(),
              ),
            ),
            validator:
                ValidationBuilder().required('Mot de passe requis').build(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: state.staySignedIn,
                  activeColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onChanged: (_) =>
                      context.read<AuthCubit>().toggleStaySignedIn(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.read<AuthCubit>().toggleStaySignedIn(),
                child: const Text(
                  'Rester connecté(e)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _RoleSelector(selected: state.role),
          const SizedBox(height: 28),
          _SubmitButton(
            label: 'Se connecter',
            isLoading: state.isLoading,
            onTap: () {
              if (formKey.currentState?.validate() ?? false) {
                context.read<AuthCubit>().login(emailCtrl.text, passCtrl.text);
              }
            },
          ),
          const SizedBox(height: 24),
          const _OrDivider(),
          const SizedBox(height: 24),
          _SocialLoginButtons(
            isLoading: state.isLoading,
            onGoogleTap: () => context.read<AuthCubit>().signInWithGoogle(),
            onGithubTap: () => context.read<AuthCubit>().signInWithGithub(),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: onForgot,
              style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
              child: const Text('Mot de passe oublié ?',
                  style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
            ),
          ),
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
  const _RegisterForm(
      {required this.formKey,
      required this.firstCtrl,
      required this.lastCtrl,
      required this.entrepriseCtrl,
      required this.emailCtrl,
      required this.passCtrl,
      required this.state});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Créer un compte ',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Commencez votre parcours SkillSpace',
              style: TextStyle(fontSize: 13.5, color: AppTheme.textGrey)),
          const SizedBox(height: 26),
          if (state.error != null) ...[
            _ErrorBanner(state.error!),
            const SizedBox(height: 10),
          ],
          if (state.role != UserRole.recruteur)
            Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Prénom'),
                        TextFormField(
                          controller: firstCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(hintText: 'Jean'),
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
                        const _Label('Nom'),
                        TextFormField(
                          controller: lastCtrl,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(hintText: 'Dupont'),
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
            ),
          if (state.role == UserRole.recruteur) ...[
            const SizedBox(height: 16),
            const _Label('Nom de l\'entreprise'),
            TextFormField(
              controller: entrepriseCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'SkillSpace Inc.',
                prefixIcon: Icon(Icons.business_rounded,
                    size: 18, color: AppTheme.textGrey),
              ),
              validator: state.role == UserRole.recruteur
                  ? ValidationBuilder()
                      .required('Nom de l\'entreprise requis')
                      .build()
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          const _Label('Email'),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'vous@exemple.com',
              prefixIcon: Icon(Icons.mail_outline_rounded,
                  size: 18, color: AppTheme.textGrey),
            ),
            validator: ValidationBuilder()
                .required('Email requis')
                .email('Email invalide')
                .build(),
          ),
          const SizedBox(height: 16),
          const _Label('Mot de passe'),
          TextFormField(
            controller: passCtrl,
            obscureText: !state.passwordVisible,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppTheme.textGrey),
              suffixIcon: IconButton(
                icon: Icon(
                  state.passwordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppTheme.textGrey,
                  size: 18,
                ),
                onPressed: () => context.read<AuthCubit>().togglePassword(),
              ),
            ),
            validator: ValidationBuilder()
                .required('Mot de passe requis')
                .minLength(6, 'Minimum 6 caractères')
                .build(),
          ),
          const SizedBox(height: 20),
          _RoleSelector(selected: state.role, sectionLabel: 'Je suis un(e)'),
          const SizedBox(height: 20),
          _SubmitButton(
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
          ),
          const SizedBox(height: 24),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(fontSize: 11.5, color: AppTheme.textGrey),
                children: [
                  TextSpan(text: 'En vous inscrivant, vous acceptez nos '),
                  TextSpan(
                      text: 'CGU',
                      style: TextStyle(
                          color: AppTheme.accent, fontWeight: FontWeight.w600)),
                  TextSpan(text: ' et '),
                  TextSpan(
                      text: 'politique de confidentialité',
                      style: TextStyle(
                          color: AppTheme.accent, fontWeight: FontWeight.w600)),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Signup Verification Flow ────────────────────────────────────────────────
class _SignupVerificationFlow extends StatefulWidget {
  final VoidCallback onBack;
  const _SignupVerificationFlow({required this.onBack});

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
              title: 'Vérifiez votre email',
              subtitle: 'Un code a été envoyé à ${state.verificationEmail}.',
            ),
            if (state.error != null) ...[
              _ErrorBanner(state.error!),
              const SizedBox(height: 10),
            ],
            const _Label('Code de vérification'),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '1234',
                prefixIcon: Icon(Icons.verified_user_outlined,
                    size: 18, color: AppTheme.textGrey),
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
  const _ForgotPasswordFlow({required this.onBack});

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
            ForgotStep.email =>
              _ForgotStepEmail(key: const ValueKey('fp_email'), onBack: onBack),
            ForgotStep.otp =>
              _ForgotStepOtp(key: const ValueKey('fp_otp'), onBack: onBack),
            ForgotStep.newPassword => _ForgotStepNewPass(
                key: const ValueKey('fp_pass'), onBack: onBack),
            ForgotStep.success =>
              _ForgotSuccess(key: const ValueKey('fp_ok'), onDone: onBack),
          },
        );
      },
    );
  }
}

class _ForgotStepEmail extends StatefulWidget {
  final VoidCallback onBack;
  const _ForgotStepEmail({super.key, required this.onBack});

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
                title: 'Mot de passe oublié',
                subtitle: 'Entrez votre e-mail pour recevoir un code.',
              ),
              if (state.error != null) ...[
                _ErrorBanner(state.error!),
                const SizedBox(height: 10),
              ],
              const _Label('Email'),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'vous@exemple.com'),
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
  const _ForgotStepOtp({super.key, required this.onBack});

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
              title: 'Code de vérification',
              subtitle: 'Entrez le code envoyé à ${state.email}.',
            ),
            if (state.error != null) ...[
              _ErrorBanner(state.error!),
              const SizedBox(height: 10),
            ],
            const _Label('Code OTP'),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '123456'),
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
  const _ForgotStepNewPass({super.key, required this.onBack});

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
              title: 'Nouveau mot de passe',
              subtitle: 'Choisissez un mot de passe sécurisé.',
            ),
            if (state.error != null) ...[
              _ErrorBanner(state.error!),
              const SizedBox(height: 10),
            ],
            const _Label('Mot de passe'),
            TextField(
              controller: _passCtrl,
              obscureText: !state.passwordVisible,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    state.passwordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textGrey,
                    size: 18,
                  ),
                  onPressed: () =>
                      context.read<ForgotPasswordCubit>().togglePassword(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Label('Confirmer'),
            TextField(
              controller: _confirmCtrl,
              obscureText: !state.confirmPasswordVisible,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    state.confirmPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textGrey,
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
  const _ForgotSuccess({super.key, required this.onDone});

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
        const Text('Mot de passe\nréinitialisé !',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                height: 1.3)),
        const SizedBox(height: 10),
        const Text(
          'Votre mot de passe a été mis à jour.\nVous pouvez vous connecter.',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 13.5, color: AppTheme.textGrey, height: 1.5),
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
  const _StepHeader(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.onBack,
      required this.currentStep});

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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    size: 18, color: AppTheme.textDark),
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
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                height: 1.3,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(fontSize: 13.5, color: AppTheme.textGrey)),
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
        border: Border.all(color: const Color(0xFFFEB2B2).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFC53030), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFFC53030),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
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
                colors: [Color(0xFFE8622A), Color(0xFFD44D15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.accent.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
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
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppTheme.border, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('OU',
              style: TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: AppTheme.border, thickness: 1)),
      ],
    );
  }
}

class _SocialLoginButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGoogleTap;
  final VoidCallback onGithubTap;

  const _SocialLoginButtons({
    required this.isLoading,
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
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SocialButton(
            label: 'GitHub',
            onTap: isLoading ? null : onGithubTap,
            isGoogle: false,
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

  const _SocialButton({
    required this.label,
    required this.onTap,
    required this.isGoogle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
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
                color: isGoogle ? const Color(0xFFDB4437) : AppTheme.textDark,
                size: isGoogle ? 32 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
