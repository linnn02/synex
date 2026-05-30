import 'package:flutter/material.dart';

import 'models/api_models.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const HalykHealthApp());
}

class HalykHealthApp extends StatefulWidget {
  const HalykHealthApp({super.key});

  @override
  State<HalykHealthApp> createState() => _HalykHealthAppState();
}

class _HalykHealthAppState extends State<HalykHealthApp> {
  final ApiService _apiService = ApiService(
    baseUrl: const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:4000/api',
    ),
  );
  AppUser? _user;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Halyk Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A884),
          primary: const Color(0xFF007F6D),
          secondary: const Color(0xFF168DE2),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF4F7F8),
          foregroundColor: Color(0xFF14202B),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCFDDE2)),
          ),
        ),
      ),
      home: _user == null
          ? LoginScreen(
              apiService: _apiService,
              onLoggedIn: (user) => setState(() => _user = user),
            )
          : HomeScreen(apiService: _apiService, user: _user!),
    );
  }
}
