import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/recipe_editor_screen.dart';




// ── Modo debug ─────────────────────────────────────────────────────────────────
// Cambiá kDebugSkipLogin a true para entrar directo al editor sin pasar por login.
// Acordate de volver a false antes de hacer build de producción.
const bool kDebugSkipLogin = false;
const int kDebugUsuarioId = 1;
const String kDebugUsuarioNombre = 'Dev User';
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  runApp(const BocadoApp());
}

class BocadoApp extends StatefulWidget {
  const BocadoApp({super.key});

  @override
  State<BocadoApp> createState() => _BocadoAppState();
}

class _BocadoAppState extends State<BocadoApp> {
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
          home: kDebugSkipLogin
              ? RecipeEditorScreen(
            themeNotifier: _themeNotifier,
            usuarioId: kDebugUsuarioId,
            usuarioNombre: kDebugUsuarioNombre,
          )
              : LoginScreen(themeNotifier: _themeNotifier),
        );
      },
    );
  }
}