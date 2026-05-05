import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pfe/core/network/api_client.dart';
import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'recruiter_profile.dart';

void main() {
  runApp(const RecruiterApp());
}

class RecruiterApp extends StatelessWidget {
  const RecruiterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authRepository = AuthRepositoryImpl(apiClient: apiClient);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(authRepository: authRepository)..checkAuthStatus(),
        ),
      ],
      child: MaterialApp(
        title: 'SkillSpace Recruiter',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state.loggedInUser != null) {
              return const RecruiterShell();
            }
            return AuthPage(onSuccess: () {});
          },
        ),
      ),
    );
  }
}
