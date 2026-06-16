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

  /// Parsea 'bocado://perfil/123' y devuelve 123, o null si el formato no coincide.
  static int? parsePerfilId(String deepLink) {
    try {
      final uri = Uri.parse(deepLink);
      if (uri.scheme == 'bocado' && uri.host == 'perfil') {
        final segments = uri.pathSegments;
        if (segments.isNotEmpty) return int.tryParse(segments.first);
      }
    } catch (_) {}
    return null;
  }
}
