import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/receta_feed.dart';

class RecetaService {
  static const _channel = MethodChannel('com.example.bocado/recetas');

  static Future<List<RecetaFeed>> getRecetas() async {
    final String json = await _channel.invokeMethod('getRecetas');
    final List<dynamic> lista = jsonDecode(json);
    return lista.map((e) => RecetaFeed.fromJson(e)).toList();
  }

  static Future<List<RecetaFeed>> getRecetasUsuario(int usuarioId) async {
    final String json = await _channel.invokeMethod(
      'getRecetasUsuario',
      {'usuarioId': usuarioId},
    );
    final List<dynamic> lista = jsonDecode(json);
    return lista.map((e) => RecetaFeed.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> getRecetaDetalle(int idReceta) async {
    final String json = await _channel.invokeMethod(
      'getRecetaDetalle',
      {'id': idReceta},
    );
    final List<dynamic> lista = jsonDecode(json);
    if (lista.isEmpty) throw Exception('Receta no encontrada');
    return lista.first as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getAlimentos() async {
    final result = await _channel.invokeMethod('getAlimentos');
    return List<Map<String, dynamic>>.from(
      (result as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<Map<String, dynamic>> addAlimento(String nombre, int idUsuario) async {
    final result = await _channel.invokeMethod(
      'addAlimento',
      {'nombre': nombre, 'id_usuario': idUsuario},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<Map<String, dynamic>> saveReceta(Map<String, dynamic> datos) async {
    final result = await _channel.invokeMethod('saveReceta', datos);
    return jsonDecode(result as String) as Map<String, dynamic>;
  }
}
