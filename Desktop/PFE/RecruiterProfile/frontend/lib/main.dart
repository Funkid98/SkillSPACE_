import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pfe/core/network/api_client.dart';
import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'recruiter_profile.dart';
import 'package:reactive_theme/reactive_theme.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeMode = await ReactiveMode.getSavedThemeMode();
  runApp(RecruiterApp(savedThemeMode: themeMode));
}

class RecruiterApp extends StatelessWidget {
  final ThemeMode? savedThemeMode;
  const RecruiterApp({super.key, this.savedThemeMode});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authRepository = AuthRepositoryImpl(apiClient: apiClient);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthCubit(authRepository: authRepository)..checkAuthStatus(),
        ),
      ],
      child: ReactiveThemer(
        savedThemeMode: savedThemeMode,
        builder: (themeMode) {
          return MaterialApp(
            title: 'SkillSpace Recruiter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state.loggedInUser != null) {
                  return const RecruiterShell();
                }
                return AuthPage(onSuccess: () {});
              },
            ),
          );
        },
      ),
    );
  }
}
