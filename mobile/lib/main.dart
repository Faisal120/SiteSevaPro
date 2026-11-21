import 'package:flutter/material.dart';

import 'core/app_controller.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  await controller.initialize();
  runApp(SiteSevaApp(controller: controller));
}

class SiteSevaApp extends StatelessWidget {
  const SiteSevaApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D6B4D),
      brightness: Brightness.light,
      surface: const Color(0xFFF7F9F7),
    );
    return MaterialApp(
      title: 'SiteSeva Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => controller.isLoggedIn
            ? HomeShell(controller: controller)
            : LoginScreen(controller: controller),
      ),
    );
  }
}
