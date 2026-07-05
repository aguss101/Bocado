import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final bool disponible;
  final String versionName;
  const UpdateInfo(this.disponible, this.versionName);
}

class UpdateService {
  static const _channel = MethodChannel('com.example.bocado/app');

  static UpdateInfo? _cache;

  static UpdateInfo? get cached => _cache;

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

  static Future<void> abrirDescarga() async {
    try {
      await _channel.invokeMethod('abrirDescarga');
    } catch (_) {}
  }

  static Future<bool> avisoYaVisto(String versionName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('update_aviso_$versionName') ?? false;
  }

  static Future<void> marcarAvisoVisto(String versionName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('update_aviso_$versionName', true);
  }
}
