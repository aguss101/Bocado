import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/IdCodec.dart';

enum DeepLinkTipo { perfil, receta, verificarCorreo }

class DeepLinkTarget {
  final DeepLinkTipo tipo;
  final int id;
  final String? token;
  const DeepLinkTarget(this.tipo, this.id, {this.token});
}

class NavigationService {
  static const _channel = MethodChannel('com.example.bocado/navigation');

  static final _ctrl = StreamController<DeepLinkTarget>.broadcast();

  static Stream<DeepLinkTarget> get deepLinks => _ctrl.stream;

  static void initIncomingLinks() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final target = parse(call.arguments as String? ?? '');
        if (target != null) _ctrl.add(target);
      }
    });
  }

  static Future<String?> getInitialDeepLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialDeepLink');
    } catch (_) {
      return null;
    }
  }

  static DeepLinkTarget? parse(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);

      if (uri.scheme == 'bocado') {
        return _resolver(uri.host, uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null);
      }

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
    if (seccion == 'verificar-correo') {
      return DeepLinkTarget(DeepLinkTipo.verificarCorreo, 0, token: slug);
    }
    return null;
  }
}
