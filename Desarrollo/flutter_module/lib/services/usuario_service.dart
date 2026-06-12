import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/usuario_Logged.dart';

class UsuarioService {
  static const _channel = MethodChannel('com.example.bocado/access');
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Lanza el selector de cuentas de Google y resuelve el flujo:
  /// - [GoogleAuth.cancelado] si el usuario cierra el selector.
  /// - [GoogleAuth.login] si el correo ya tiene cuenta → entra directo.
  /// - [GoogleAuth.registroPendiente] si es nuevo → falta completar
  ///   nación/género/fecha (datos que Google no provee) en el onboarding.
  /// Reutilizado tanto por Login como por Registro.
  static Future<GoogleAuth> signInWithGoogle() async {
    // Forzamos a que SIEMPRE aparezca el selector de cuentas: si no,
    // google_sign_in reutiliza en silencio la última cuenta usada.
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return GoogleAuth.cancelado(); // el usuario canceló

    // 1) ¿Ya existe una cuenta con ese correo? → login directo.
    final String response =
        await _channel.invokeMethod('loginGoogle', {'email': account.email});
    final List<dynamic> lista = jsonDecode(response);
    if (lista.isNotEmpty) {
      return GoogleAuth.login(usuario_Logged.fromJson(lista.first));
    }

    // 2) Usuario nuevo: pre-cargamos lo que Google sí da para el onboarding.
    final partes = account.displayName?.split(' ') ?? [];
    final nombre = partes.isNotEmpty ? partes.first : '';
    final apellido = partes.length > 1 ? partes.sublist(1).join(' ') : '';
    return GoogleAuth.registroPendiente(GooglePerfil(
      correo: account.email,
      nombre: nombre,
      apellido: apellido,
      foto: account.photoUrl ?? '',
    ));
  }

  /// Crea el usuario de Google una vez completado el onboarding
  /// (nación/género/fecha). Devuelve el usuario ya creado.
  static Future<usuario_Logged> registrarUsuarioGoogle({
    required GooglePerfil perfil,
    required int nacion,
    required int genero,
    required String fechaNacimiento,
  }) async {
    final String response = await _channel.invokeMethod('registrarGoogle', {
      'correo': perfil.correo,
      'nombre': perfil.nombre,
      'apellido': perfil.apellido,
      'foto': perfil.foto,
      'nacion': nacion,
      'genero': genero,
      'fechaNacimiento': fechaNacimiento,
    });
    final data = jsonDecode(response);
    return usuario_Logged.fromJson(data);
  }

  static Future<usuario_Logged> login(String usuario, String contrasena) async {
    final String response = await _channel.invokeMethod(
      'loginJava',
      {'usuario': usuario, 'contrasena': contrasena},
    );
    final data = jsonDecode(response);
    return usuario_Logged.fromJson(data);
  }

  /// Revalida contra la BD que la cuenta exista y siga activa.
  /// Devuelve true si está vigente; lanza PlatformException si no hay red.
  static Future<bool> sesionVigente(int id) async {
    final String response =
        await _channel.invokeMethod('validarSesion', {'id_usuario': id});
    final List<dynamic> lista = jsonDecode(response);
    return lista.isNotEmpty;
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

  static Future<usuario_Logged> getPerfilUsuario(int idUsuarioTarget) async{
    final String response = await _channel.invokeMethod(
      'getPerfilUsuario',
      {'id_usuario': idUsuarioTarget},
    );
    final List<dynamic> lista = jsonDecode(response);
    if(lista.isEmpty) throw Exception('Usuario no encontrado');
    final Map<String, dynamic> data = lista.first;

    return usuario_Logged.fromJson(data);
  }
}

/// Resultado del flujo de autenticación con Google.
class GoogleAuth {
  /// != null  → el correo ya tenía cuenta: login directo.
  final usuario_Logged? existente;

  /// != null  → usuario nuevo: falta completar el perfil (onboarding).
  final GooglePerfil? nuevo;

  const GoogleAuth._(this.existente, this.nuevo);

  factory GoogleAuth.cancelado() => const GoogleAuth._(null, null);
  factory GoogleAuth.login(usuario_Logged u) => GoogleAuth._(u, null);
  factory GoogleAuth.registroPendiente(GooglePerfil p) => GoogleAuth._(null, p);

  bool get cancelado => existente == null && nuevo == null;
}

/// Datos que Google sí provee y que pre-cargamos en el onboarding.
class GooglePerfil {
  final String correo;
  final String nombre;
  final String apellido;
  final String foto;

  const GooglePerfil({
    required this.correo,
    required this.nombre,
    required this.apellido,
    required this.foto,
  });
}
