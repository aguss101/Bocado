import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/usuario_Logged.dart';

class UsuarioService {
  static const _channel = MethodChannel('com.example.bocado/access');

  static Future<usuario_Logged> login(String usuario, String contrasena) async {
    final String response = await _channel.invokeMethod(
      'loginJava',
      {'usuario': usuario, 'contrasena': contrasena},
    );
    final data = jsonDecode(response);
    return usuario_Logged(
      data['id'],
      data['id_cuenta'],
      data['usuario'],
      data['foto'],
      data['banner'],
    );
  }

  static Future<usuario_Logged> registrar({
    required int nacion,
    required int genero,
    required String nombre,
    required String apellido,
    required String email,
    required String usuario,
    required String password,
    required String fechaNacimiento,
  }) async {
    final String response = await _channel.invokeMethod('registerJava', {
      'nacion': nacion,
      'genero': genero,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'usuario': usuario,
      'password': password,
      'fechaNacimiento': fechaNacimiento,
    });
    final data = jsonDecode(response);
    return usuario_Logged(
      data['id'],
      data['id_cuenta'],
      data['usuario'],
      data['foto'],
      data['banner'],
    );
  }

  static Future<List<dynamic>> getNaciones() async {
    final String json = await _channel.invokeMethod('getNaciones');
    return jsonDecode(json);
  }

  static Future<List<dynamic>> getGeneros() async {
    final String json = await _channel.invokeMethod('getGeneros');
    return jsonDecode(json);
  }

  static Future<void> actualizarPerfil({
    required int id,
    required String usuario,
    String? correo,
    String? genero,
    String? fotoUrl,
    String? bannerUrl,
  }) async {
    await _channel.invokeMethod('actualizarPerfil', {
      'id': id,
      'usuario': usuario,
      if (correo != null && correo.isNotEmpty) 'correo': correo,
      if (genero != null) 'genero': genero,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      if (bannerUrl != null) 'bannerUrl': bannerUrl,
    });
  }
}
