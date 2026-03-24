import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const BocadoApp());
}

class BocadoApp extends StatelessWidget {
  const BocadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _BocadoAppWithTheme();
  }
}

class _BocadoAppWithTheme extends StatefulWidget {
  @override
  State<_BocadoAppWithTheme> createState() => _BocadoAppWithThemeState();
}

class _BocadoAppWithThemeState extends State<_BocadoAppWithTheme> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, themeMode, __) {
        return MaterialApp(
          title: 'Bocado',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: LoginScreen(themeNotifier: _themeNotifier),
        );
      },
    );
  }
}