import 'dart:convert';
import 'package:flutter/services.dart';

class InteraccionesService {
  static const _channel = MethodChannel('com.example.bocado/interacciones');

  static Future<bool> toggleInteraction(Map<String, dynamic> datos) async{
    final result = await _channel.invokeMethod('toggleInteraction', datos);
    return result as bool;
  }

  /// Estado real (en BD) de las interacciones del usuario para una receta.
  /// Devuelve el set de tipos presentes, p.ej. {'like', 'save'}.
  static Future<Set<String>> fetchMisInteracciones(int idUsuario, int idReceta) async {
    final String json = await _channel.invokeMethod('fetchMisInteracciones', {
      'id_usuario': idUsuario,
      'id_receta': idReceta,
    });
    final List<dynamic> lista = jsonDecode(json);
    return lista.map((e) => e['tipo_interaccion'] as String).toSet();
  }
  static Future<String> actualizarSeguido(Map<String, dynamic> datos) async{
    final result = await _channel.invokeMethod('updateSeguido', datos);
    return result.toString();
  }
  static Future<String> fetchComentarios(int idReceta) async{
    final result = await _channel.invokeMethod('fetchComentarios', {'recetaId': idReceta});
    return result.toString();
  }
  static Future<bool> enviarComentario(Map<String, dynamic> datos) async {
    final result = await _channel.invokeMethod('enviarComentario', datos);
    return result as bool;
  }
}