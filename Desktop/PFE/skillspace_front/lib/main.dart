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
            create: (context) => AuthCubit(authRepository: authRepository)),
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

            home = const LandingPage();

            return MaterialApp(
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
