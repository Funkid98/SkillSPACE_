import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/l10n_cubit.dart';
import 'core/l10n/app_localizations.dart';
import 'core/keyboard_fix.dart'; // ← ADD THIS IMPORT (put keyboard_fix.dart in lib/core/)
import 'package:pfe/core/network/api_client.dart';
import 'package:pfe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:skillspace/features/landing/presentation/pages/landing_page.dart';
import 'package:skillspace/features/dashboard_shell/dashboard_shell.dart';
import 'package:recruiter_profile/recruiter_profile.dart' as recruiter;
import 'package:trainer_profile/screens/main_navigation_screen.dart';
import 'package:pfe/core/network/cookie_service.dart';
import 'package:reactive_theme/reactive_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FIX: Must be called AFTER ensureInitialized and BEFORE runApp.
  // Intercepts bad synthesized keyboard events on Flutter Web (Alt+Tab desync)
  // before Flutter's engine assertion fires. Safe no-op on mobile/desktop.
  KeyboardFix.apply();

  final staySignedIn = CookieService.getBool('stay_signed_in') ?? true;

  if (!staySignedIn) {
    CookieService.remove('jwt_token');
    CookieService.remove('user_data');
  }

  final apiClient = ApiClient();
  final authRepository = AuthRepositoryImpl(apiClient: apiClient);
  final savedThemeMode = await ReactiveMode.getSavedThemeMode();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => L10nCubit()),
        BlocProvider(
          create: (context) =>
              AuthCubit(authRepository: authRepository)..checkAuthStatus(),
        ),
        BlocProvider(
          create: (context) =>
              ForgotPasswordCubit(authRepository: authRepository),
        ),
      ],
      child: SkillSpaceApp(savedThemeMode: savedThemeMode),
    ),
  );
}

class SkillSpaceApp extends StatelessWidget {
  final ThemeMode? savedThemeMode;
  const SkillSpaceApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<L10nCubit, Locale>(
      builder: (context, locale) {
        return ReactiveThemer(
          savedThemeMode: savedThemeMode,
          builder: (reactiveMode) {
            return BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                final Widget home = _resolveHome(context, authState, locale);

                return MaterialApp(
                  // Key forces a full rebuild when auth state changes (login/logout)
                  key: ValueKey(
                      '${authState.loggedInUser != null}_$reactiveMode'),
                  title: 'SkillSpace',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light.copyWith(
                    scaffoldBackgroundColor: Colors.transparent,
                    canvasColor: Colors.transparent,
                  ),
                  darkTheme: AppTheme.dark.copyWith(
                    scaffoldBackgroundColor: Colors.transparent,
                    canvasColor: Colors.transparent,
                  ),
                  themeMode: reactiveMode,
                  locale: locale,
                  supportedLocales: const [
                    Locale('en'),
                    Locale('fr'),
                    Locale('ar'),
                  ],
                  localizationsDelegates: const [
                    AppLocalizationsDelegate(),
                    recruiter.RecruiterLocalizationsDelegate(),
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: home,
                );
              },
            );
          },
        );
      },
    );
  }

  // FIX: Extracted home resolution into a helper to reduce nesting and
  // avoid rebuilding the entire MaterialApp widget tree inline.
  Widget _resolveHome(
      BuildContext context, AuthState authState, Locale locale) {
    if (authState.loggedInUser == null) {
      return const LandingPage();
    }

    return Builder(
      builder: (ctx) {
        Future<void> handleLogout() async {
          await ctx.read<AuthCubit>().logout();
          if (ctx.mounted) {
            Navigator.of(ctx, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LandingPage()),
              (route) => false,
            );
          }
        }

        switch (authState.role) {
          case UserRole.recruteur:
            return recruiter.RecruiterShell(
              currentLocale: locale,
              onLocaleChanged: (newLocale) =>
                  ctx.read<L10nCubit>().setLocale(newLocale),
              onLogout: handleLogout,
            );

          case UserRole.formateur:
            return MainNavigationScreen(onLogout: handleLogout);

          default:
            return DashboardShell(
              initialUserData: authState.loggedInUser,
              onLogout: handleLogout,
            );
        }
      },
    );
  }
}
