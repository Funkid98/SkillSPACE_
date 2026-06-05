import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/auth/data/datasources/google_auth_web.dart'
    if (dart.library.io) 'features/auth/data/datasources/google_auth_stub.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// URL of the main SkillSpace shell app.
/// In dev both apps run on different ports (login on :3000, shell on :3001).
/// In production they are served from the same origin under different paths.
const String _shellUrl = String.fromEnvironment(
  'SHELL_URL',
  defaultValue: 'http://localhost:3001',
);

void main() {
  // If this browser tab is the OAuth popup returning from Google,
  // send the token back to the opener and close — don't render anything.
  if (kIsWeb && handlePopupCallback()) return;

  runApp(const SkillSpaceApp());
}


class SkillSpaceApp extends StatelessWidget {
  const SkillSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (context) => AuthRepositoryImpl(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (context) =>
                  AuthCubit(authRepository: context.read<AuthRepository>())),
          BlocProvider(
              create: (context) => ForgotPasswordCubit(
                  authRepository: context.read<AuthRepository>())),
        ],
        child: MaterialApp(
          title: 'SkillSpace',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: AuthPage(
            onSuccess: () {
              // After login/register success, redirect the browser to the
              // main SkillSpace shell which hosts all role dashboards.
              if (kIsWeb) {
                html.window.location.href = _shellUrl;
              }
            },
          ),
        ),
      ),
    );
  }
}
