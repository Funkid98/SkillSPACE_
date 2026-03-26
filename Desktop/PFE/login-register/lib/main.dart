import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'features/auth/presentation/pages/auth_page.dart';

void main() {
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
          home: const AuthPage(),
        ),
      ),
    );
  }
}
