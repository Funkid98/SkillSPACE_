import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/l10n_cubit.dart';
import 'core/l10n/app_localizations.dart';
import 'package:pfe/core/network/api_client.dart';
import 'package:pfe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:skillspace/features/landing/presentation/pages/landing_page.dart';
import 'package:skillspace/features/dashboard_shell/dashboard_shell.dart';
import 'package:recruiter_profile/recruiter_profile.dart' as recruiter;
import 'package:trainer_profile/screens/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final staySignedIn = prefs.getBool('stay_signed_in') ?? true;

  if (!staySignedIn) {
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  final apiClient = ApiClient();
  final authRepository = AuthRepositoryImpl(apiClient: apiClient);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => L10nCubit()),
        BlocProvider(
            create: (context) =>
                AuthCubit(authRepository: authRepository)..checkAuthStatus()),
        BlocProvider(
            create: (context) =>
                ForgotPasswordCubit(authRepository: authRepository)),
      ],
      child: const SkillSpaceApp(),
    ),
  );
}

class SkillSpaceApp extends StatelessWidget {
  const SkillSpaceApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<L10nCubit, Locale>(
      builder: (context, locale) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            Widget home;

            if (authState.loggedInUser != null) {
              if (authState.role == UserRole.recruteur) {
                home = Builder(
                  builder: (ctx) => recruiter.RecruiterShell(
                    currentLocale: locale,
                    onLocaleChanged: (newLocale) =>
                        ctx.read<L10nCubit>().setLocale(newLocale),
                    onLogout: () async {
                      await ctx.read<AuthCubit>().logout();
                      if (ctx.mounted) {
                        Navigator.of(ctx, rootNavigator: true)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LandingPage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                );
              } else if (authState.role == UserRole.formateur) {
                home = Builder(
                  builder: (ctx) => MainNavigationScreen(
                    onLogout: () async {
                      await ctx.read<AuthCubit>().logout();
                      if (ctx.mounted) {
                        Navigator.of(ctx, rootNavigator: true)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LandingPage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                );
              } else {
                home = Builder(
                  builder: (ctx) => DashboardShell(
                    initialUserData: authState.loggedInUser,
                    onLogout: () async {
                      await ctx.read<AuthCubit>().logout();
                      if (ctx.mounted) {
                        Navigator.of(ctx, rootNavigator: true)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LandingPage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                );
              }
            } else {
              home = const LandingPage();
            }

            return MaterialApp(
              key: ValueKey(authState.loggedInUser != null),
              title: 'SkillSpace',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
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
  }
}
