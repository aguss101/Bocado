import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/RecetaFeed.dart';

class RecetaService {
  static const _channel = MethodChannel('com.example.bocado/recetas');

  static Future<List<RecetaFeed>> _fetchRecetas(String method, [dynamic args]) async {
    final String json = await _channel.invokeMethod(method, args);
    final List<dynamic> lista = jsonDecode(json);
    return lista.map((e) => RecetaFeed.fromJson(e)).toList();
  }

  static Future<List<RecetaFeed>> getRecetas({
    required String seed,
    required int limit,
    required int offset,
    required int viewerId,
  }) =>
      _fetchRecetas('getRecetas', {
        'seed': seed,
        'limit': limit,
        'offset': offset,
        'viewerId': viewerId,
      });



  static Future<List<RecetaFeed>> getRecetasUsuario(int usuarioId, {int? limit, int? offset}) =>
      _fetchRecetas('getRecetasUsuario', {
        'usuarioId': usuarioId,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      });

  static Future<List<RecetaFeed>> getMisRecetas(int usuarioId) =>
      _fetchRecetas('getMisRecetas', {'usuarioId': usuarioId});

  static Future<List<RecetaFeed>> getGuardadosUsuario(int usuarioId, {int? limit, int? offset}) =>
      _fetchRecetas('getGuardadosUsuario', {
        'usuarioId': usuarioId,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      });

  static Future<int> contarRecetas(int usuarioId) async {
    final result =
        await _channel.invokeMethod('contarRecetas', {'usuarioId': usuarioId});
    return result as int;
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

  static Future<Map<String, dynamic>> getRecetaParaEditar(int idReceta) async {
    final String json = await _channel.invokeMethod(
      'getRecetaID',
      {'id_receta': idReceta},
    );
    return jsonDecode(json) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getAlimentos() async {
    final result = await _channel.invokeMethod('getAlimentos');
    return List<Map<String, dynamic>>.from(
      (result as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<Map<String, dynamic>> addAlimento(
    String nombre,
    int idUsuario, {
    required int idMedida,
    required double precioBase,
  }) async {
    final result = await _channel.invokeMethod(
      'addAlimento',
      {
        'nombre': nombre,
        'id_usuario': idUsuario,
        'id_medida': idMedida,
        'precio_base': precioBase,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<bool> actualizarPrecioAlimento({
    required int idAlimento,
    required int idUsuario,
    required int idMedida,
    required double precioBase,
  }) async {
    final result = await _channel.invokeMethod(
      'actualizarPrecioAlimento',
      {
        'id_alimento': idAlimento,
        'id_usuario': idUsuario,
        'id_medida': idMedida,
        'precio_base': precioBase,
      },
    );
    return result as bool;
  }

  static Future<Map<String, dynamic>> saveReceta(Map<String, dynamic> datos) async {
    final result = await _channel.invokeMethod('saveReceta', datos);
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateReceta(Map<String, dynamic> datos) async {
    final result = await _channel.invokeMethod('updateReceta', datos);
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> eliminarReceta(int idReceta, int idUsuario) async {
    await _channel.invokeMethod('eliminarReceta',
      {
        'id_receta': idReceta,
        'id_usuario': idUsuario,
      },
    );
  }

  static Future<List<RecetaFeed>> buscarRecetas(String query) =>
      _fetchRecetas('buscarReceta', {
        'query': query,
      });

}
