import 'package:flutter/material.dart';
import 'package:flutter_module/models/usuario_Logged.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/recipe_editor_screen.dart';
import 'config/debug_config.dart';

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
            user: usuario_Logged(kDebugUsuarioId, kDebugCuentaId, kDebugUsuarioNombre, null, null),
          )
              : LoginScreen(themeNotifier: _themeNotifier),
        );
      },
    );
  }
}