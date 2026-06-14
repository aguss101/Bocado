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
}