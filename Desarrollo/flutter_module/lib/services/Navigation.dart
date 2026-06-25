import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/IdCodec.dart';

enum DeepLinkTipo { perfil, receta }

/// Destino resuelto de un deep link: a qué pantalla ir y con qué id real.
class DeepLinkTarget {
  final DeepLinkTipo tipo;
  final int id;
  const DeepLinkTarget(this.tipo, this.id);
}

class NavigationService {
  static const _channel = MethodChannel('com.example.bocado/navigation');

  static final _ctrl = StreamController<DeepLinkTarget>.broadcast();

  /// Stream de deep links que llegan mientras la app ya está corriendo.
  static Stream<DeepLinkTarget> get deepLinks => _ctrl.stream;

  /// Registra el handler que recibe deep links de Java vía onNewIntent.
  /// Llamar una sola vez al iniciar la app.
  static void initIncomingLinks() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final target = parse(call.arguments as String? ?? '');
        if (target != null) _ctrl.add(target);
      }
    });
  }

  /// Retorna el deep link inicial si la app fue abierta desde uno, o null.
  static Future<String?> getInitialDeepLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialDeepLink');
    } catch (_) {
      return null;
    }
  }

  /// Parsea un deep link de perfil o receta y devuelve el destino con el id real
  /// (decodificado desde el slug). Acepta dos formatos por tipo:
  ///   bocado://perfil/{slug}                  · bocado://receta/{slug}
  ///   https://links.bocado.tech/perfil/{slug} · https://links.bocado.tech/receta/{slug}
  static DeepLinkTarget? parse(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);

      // Custom scheme: bocado://{perfil|receta}/{slug}
      if (uri.scheme == 'bocado') {
        return _resolver(uri.host, uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null);
      }

      // App Link: https://links.bocado.tech/{perfil|receta}/{slug}
      if (uri.scheme == 'https' && uri.host == 'links.bocado.tech') {
        final segs = uri.pathSegments;
        if (segs.length >= 2) return _resolver(segs[0], segs[1]);
      }
    } catch (_) {}
    return null;
  }

  static DeepLinkTarget? _resolver(String? seccion, String? slug) {
    if (slug == null || slug.isEmpty) return null;
    if (seccion == 'perfil') {
      final id = IdCodec.decodePerfil(slug);
      return id != null ? DeepLinkTarget(DeepLinkTipo.perfil, id) : null;
    }
    if (seccion == 'receta') {
      final id = IdCodec.decodeReceta(slug);
      return id != null ? DeepLinkTarget(DeepLinkTipo.receta, id) : null;
    }
    return null;
  }
}
