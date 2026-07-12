import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'theme/App.dart';
import 'theme/Notifier.dart';
import 'theme/ColorblindNotifier.dart';
import 'screens/LogIn.dart';
import 'screens/Feed.dart';
import 'screens/Profile.dart';
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
  final colorblindNotifier = ColorblindNotifier();
  await colorblindNotifier.load();

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
      }
    }
    NavigationService.initIncomingLinks();
    final deepLink = await NavigationService.getInitialDeepLink();
    if (deepLink != null) deepLinkTarget = NavigationService.parse(deepLink);
  } catch (e) {
    initError ??= 'SessionService.loadSession() falló: $e';
  }

  runApp(BocadoApp(
    savedUser: savedUser,
    initError: initError,
    deepLinkTarget: deepLinkTarget,
    colorblindNotifier: colorblindNotifier,
  ));
}

class BocadoApp extends StatefulWidget {
  final usuario_Logged? savedUser;
  final String? initError;
  final DeepLinkTarget? deepLinkTarget;
  final ColorblindNotifier colorblindNotifier;
  const BocadoApp({
    super.key,
    this.savedUser,
    this.initError,
    this.deepLinkTarget,
    required this.colorblindNotifier,
  });

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
    if (target.tipo == DeepLinkTipo.verificarCorreo) return;
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
      DeepLinkTipo.verificarCorreo => const SizedBox.shrink(),
    };
    final String routeName = switch (target.tipo) {
      DeepLinkTipo.perfil => 'perfil/${target.id}',
      DeepLinkTipo.receta => 'receta/${target.id}',
      DeepLinkTipo.verificarCorreo => '',
    };
    nav.push(MaterialPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (_) => pantalla,
    ));
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    _themeNotifier.dispose();
    widget.colorblindNotifier.dispose();
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
    return ColorblindScope(
      notifier: widget.colorblindNotifier,
      child: ValueListenableBuilder<ColorblindConfig>(
        valueListenable: widget.colorblindNotifier,
        builder: (_, cbConfig, __) {
          return ValueListenableBuilder<ThemeMode>(
            valueListenable: _themeNotifier,
            builder: (_, themeMode, __) {
              return MaterialApp(
                title: 'Bocado',
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: AppTheme.light(cbConfig),
                darkTheme: AppTheme.dark(cbConfig),
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
                navigatorObservers: [routeObserver, bocadoRouteTracker],
                home: _resolveHome(),
              );
            },
          );
        },
      ),
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
    if (widget.target.tipo == DeepLinkTipo.verificarCorreo) return;
    final String routeName = switch (widget.target.tipo) {
      DeepLinkTipo.perfil => 'perfil/${widget.target.id}',
      DeepLinkTipo.receta => 'receta/${widget.target.id}',
      DeepLinkTipo.verificarCorreo => '',
    };
    pushOrReuse(
      context,
      routeName,
      (_) => switch (widget.target.tipo) {
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
        DeepLinkTipo.verificarCorreo => const SizedBox.shrink(),
      },
    );
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
