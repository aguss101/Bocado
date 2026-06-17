import 'package:flutter/services.dart';

class NavigationService {
  static const _channel = MethodChannel('com.example.bocado/navigation');

  /// Retorna el deep link inicial si la app fue abierta desde uno, o null.
  static Future<String?> getInitialDeepLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialDeepLink');
    } catch (_) {
      return null;
    }
  }

  /// Parsea el id de perfil desde un deep link. Acepta dos formatos:
  ///   bocado://perfil/123                  (custom scheme)
  ///   https://links.bocado.tech/perfil/123 (App Link)
  static int? parsePerfilId(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);
      if (uri.scheme == 'bocado' && uri.host == 'perfil') {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) return int.tryParse(segments.first);
      }
      if (uri.scheme == 'https' && uri.host == 'links.bocado.tech') {
        final segments = uri.pathSegments;
        if (segments.length >= 2 && segments.first == 'perfil') {
          return int.tryParse(segments[1]);
        }
      }
    } catch (_) {}
    return null;
  }
}
