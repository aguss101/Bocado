import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_module/models/usuario_Logged.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/recipe_editor_screen.dart';
import 'services/session_service.dart';
import 'services/usuario_service.dart';
import 'config/debug_config.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  usuario_Logged? savedUser;

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    initError = 'SupabaseConfig.initialize() falló: $e';
  }

  try {
    savedUser = await SessionService.loadSession();
    if (savedUser != null) {
      try {
        final vigente = await UsuarioService.sesionVigente(savedUser.id);
        if (!vigente) {
          await SessionService.clearSession();
          savedUser = null;
        }
      } on PlatformException {
        // Sin conexión: confiamos en la sesión cacheada (modo offline).
      }
    }
  } catch (e) {
    initError ??= 'SessionService.loadSession() falló: $e';
  }

  runApp(BocadoApp(savedUser: savedUser, initError: initError));
}

class BocadoApp extends StatefulWidget {
  final usuario_Logged? savedUser;
  final String? initError;
  const BocadoApp({super.key, this.savedUser, this.initError});

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
    if (widget.initError != null) {
      return _InitErrorScreen(error: widget.initError!);
    }
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

class _InitErrorScreen extends StatelessWidget {
  final String error;
  const _InitErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0701),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFD96E11), size: 56),
              const SizedBox(height: 16),
              const Text(
                'Error de inicialización',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                error,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reiniciá la app. Si persiste, verificá que MainActivity registre AccessChannel correctamente.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
