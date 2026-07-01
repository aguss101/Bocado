import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultado del chequeo de versión contra el version.json remoto.
class UpdateInfo {
  final bool disponible;
  final String versionName;
  const UpdateInfo(this.disponible, this.versionName);
}

class UpdateService {
  static const _channel = MethodChannel('com.example.bocado/app');

  static UpdateInfo? _cache;

  /// Último resultado del chequeo (para que la barra de navegación sepa si
  /// mostrar el botón "Actualizar" sin volver a pegarle a la red).
  static UpdateInfo? get cached => _cache;

  /// Consulta version.json remoto y compara con la versión instalada.
  /// Devuelve null si no hay conexión (en ese caso no molestamos al usuario).
  /// En builds de desarrollo (flutter run / debug) no chequea: el versionCode
  /// local es un valor fijo de respaldo, siempre "atrasado" frente a lo publicado.
  static Future<UpdateInfo?> verificar() async {
    if (kDebugMode) return null;
    try {
      final json = await _channel.invokeMethod<String>('verificarActualizacion');
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      _cache = UpdateInfo(
        map['disponible'] == true,
        (map['versionName'] ?? '').toString(),
      );
      return _cache;
    } catch (_) {
      return null;
    }
  }

  /// Abre la descarga del APK en el navegador (vía Intent nativo).
  static Future<void> abrirDescarga() async {
    try {
      await _channel.invokeMethod('abrirDescarga');
    } catch (_) {}
  }

  /// El cartel de primer plano se muestra una sola vez por versión nueva.
  static Future<bool> avisoYaVisto(String versionName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('update_aviso_$versionName') ?? false;
  }

  static Future<void> marcarAvisoVisto(String versionName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('update_aviso_$versionName', true);
  }
}
