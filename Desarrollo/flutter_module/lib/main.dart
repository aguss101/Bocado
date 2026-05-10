import 'package:flutter/material.dart';
import 'package:flutter_module/models/usuario_Logged.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/recipe_editor_screen.dart';
import 'services/session_service.dart';
import 'config/debug_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedUser = await SessionService.loadSession();
  runApp(BocadoApp(savedUser: savedUser));
}

class BocadoApp extends StatefulWidget {
  final usuario_Logged? savedUser;
  const BocadoApp({super.key, this.savedUser});

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

  Widget _resolveHome() {
    if (kDebugSkipLogin) {
      return RecipeEditorScreen(
        themeNotifier: _themeNotifier,
        user: usuario_Logged(kDebugUsuarioId, kDebugCuentaId, kDebugUsuarioNombre, null, null),
      );
    }
    if (widget.savedUser != null) {
      return FeedScreen(themeNotifier: _themeNotifier, user: widget.savedUser!);
    }
    return LoginScreen(themeNotifier: _themeNotifier);
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
          home: _resolveHome(),
        );
      },
    );
  }
}
