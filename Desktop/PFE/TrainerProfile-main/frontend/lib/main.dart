import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:pfe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pfe/core/network/api_client.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final authRepository = AuthRepositoryImpl(apiClient: apiClient);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => AuthCubit(authRepository: authRepository)),
        BlocProvider(
            create: (context) =>
                ForgotPasswordCubit(authRepository: authRepository)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SkillSpace',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Builder(builder: (context) {
          return AuthPage(
            onSuccess: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              );
            },
          );
        }),
      ),
    );
  }
}
