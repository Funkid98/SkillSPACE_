import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/pages/auth_page.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:pfe/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:pfe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pfe/core/network/api_client.dart';
import 'screens/main_navigation_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
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
          void navigateToMain() {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (routeContext) => MainNavigationScreen(
                  onLogout: () async {
                    await routeContext.read<AuthCubit>().logout();
                    if (routeContext.mounted) {
                      Navigator.of(routeContext).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => AuthPage(onSuccess: navigateToMain),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            );
          }

          return AuthPage(onSuccess: navigateToMain);
        }),
      ),
    );
  }
}
