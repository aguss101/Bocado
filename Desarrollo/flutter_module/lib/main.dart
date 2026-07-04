import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'theme/App.dart';
import 'theme/Notifier.dart';
import 'screens/LogIn.dart';
import 'screens/Feed.dart';
import 'screens/Profil.dart';
import 'screens/EditRecipe.dart';
import 'screens/DetailRecipe.dart';
import 'services/Session.dart';
import 'services/Usuario.dart';
import 'services/Navigation.dart';
import 'route_observer.dart';
import 'config/DebugConfig.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  usuario_Logged? savedUser;
  DeepLinkTarget? deepLinkTarget;

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
    NavigationService.initIncomingLinks();
    final deepLink = await NavigationService.getInitialDeepLink();
    if (deepLink != null) deepLinkTarget = NavigationService.parse(deepLink);
  } catch (e) {
    initError ??= 'SessionService.loadSession() falló: $e';
  }

  runApp(BocadoApp(savedUser: savedUser, initError: initError, deepLinkTarget: deepLinkTarget));
}

class BocadoApp extends StatefulWidget {
  final usuario_Logged? savedUser;
  final String? initError;
  final DeepLinkTarget? deepLinkTarget;
  const BocadoApp({super.key, this.savedUser, this.initError, this.deepLinkTarget});

  @override
  State<BocadoApp> createState() => _BocadoAppState();
}

class _BocadoAppState extends State<BocadoApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<DeepLinkTarget>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _deepLinkSub = NavigationService.deepLinks.listen(_onDeepLink);
  }

  void _onDeepLink(DeepLinkTarget target) {
    final user = widget.savedUser;
    if (user == null) return;
    final nav = _navigatorKey.currentState;
    if (nav == null) return;
    final Widget pantalla = switch (target.tipo) {
      DeepLinkTipo.perfil => ProfileScreen(
          themeNotifier: _themeNotifier,
          user: user,
          idUsuarioTarget: target.id,
        ),
      DeepLinkTipo.receta => RecipeDetailScreen(
          themeNotifier: _themeNotifier,
          user: user,
          idReceta: target.id,
          protFeed: 0,
          carbFeed: 0,
          grasFeed: 0,
        ),
    };
    nav.push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
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
      if (widget.deepLinkTarget != null) {
        return _DeepLinkLauncher(
          user: widget.savedUser!,
          themeNotifier: _themeNotifier,
          target: widget.deepLinkTarget!,
        );
      }
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
          // App en español: fuerza el locale para que widgets nativos (ej. el
          // calendario de showDatePicker) se muestren en español sin depender
          // del idioma del dispositivo.
          locale: const Locale('es'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
          ],
          navigatorKey: _navigatorKey,
          navigatorObservers: [routeObserver],
          home: _resolveHome(),
        );
      },
    );
  }
}

class _DeepLinkLauncher extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;
  final DeepLinkTarget target;
  const _DeepLinkLauncher({required this.user, required this.themeNotifier, required this.target});

  @override
  State<_DeepLinkLauncher> createState() => _DeepLinkLauncherState();
}

class _DeepLinkLauncherState extends State<_DeepLinkLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrir());
  }

  void _abrir() {
    final destino = switch (widget.target.tipo) {
      DeepLinkTipo.perfil => ProfileScreen(
          themeNotifier: widget.themeNotifier,
          user: widget.user,
          idUsuarioTarget: widget.target.id,
        ),
      DeepLinkTipo.receta => RecipeDetailScreen(
          themeNotifier: widget.themeNotifier,
          user: widget.user,
          idReceta: widget.target.id,
          protFeed: 0,
          carbFeed: 0,
          grasFeed: 0,
        ),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    return FeedScreen(themeNotifier: widget.themeNotifier, user: widget.user);
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
