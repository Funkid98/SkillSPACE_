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
import 'features/landing/presentation/pages/landing_page.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/dashboard_shell/dashboard_shell.dart';
import 'features/recruiter/presentation/pages/recruiter_shell.dart';
import 'features/recruiter/presentation/widgets/recruiter_sidebar.dart';
import 'shared/widgets/app_sidebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  final userDataStr = prefs.getString('user_data');
  final activeTabIndex = prefs.getInt('active_tab_index') ?? 0;

  String? role;
  if (userDataStr != null) {
    try {
      final userData = jsonDecode(userDataStr);
      role = userData['role'];
    } catch (e) {
      debugPrint('Error parsing user data: $e');
    }
  }
  
  final apiClient = ApiClient();
  final authRepository = AuthRepositoryImpl(apiClient: apiClient);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => L10nCubit()),
        BlocProvider(create: (context) => AuthCubit(authRepository: authRepository)),
        BlocProvider(create: (context) => ForgotPasswordCubit(authRepository: authRepository)),
      ],
      child: SkillSpaceApp(
        isLoggedIn: token != null,
        userRole: role,
        initialTabIndex: activeTabIndex,
      ),
    ),
  );
}

class SkillSpaceApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userRole;
  final int initialTabIndex;

  const SkillSpaceApp({
    super.key,
    this.isLoggedIn = false,
    this.userRole,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<L10nCubit, Locale>(
      builder: (context, locale) {
        Widget home;
        if (!isLoggedIn) {
          home = const LandingPage();
        } else {
          final isRecruiter = userRole == 'recruteur' || userRole == 'recruiter';
          if (isRecruiter) {
            home = RecruiterShell(
              initialTab: RecruiterTab.values[initialTabIndex.clamp(0, RecruiterTab.values.length - 1)],
            );
          } else {
            home = DashboardShell(
              initialTab: DashboardTab.values[initialTabIndex.clamp(0, DashboardTab.values.length - 1)],
            );
          }
        }

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
  }
}
