import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/RecetaFeed.dart';

class InteraccionesService {
  static const _channel = MethodChannel('com.example.bocado/interacciones');

  static Future<bool> toggleInteraction(Map<String, dynamic> datos) async{
    final result = await _channel.invokeMethod('toggleInteraction', datos);
    return result as bool;
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