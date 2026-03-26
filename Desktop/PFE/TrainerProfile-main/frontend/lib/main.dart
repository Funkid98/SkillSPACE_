import 'package:flutter/material.dart';
import 'screens/formateur_profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Skillspace - Formateur',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      home: const FormateurProfileScreen(),
    );
  }
}
