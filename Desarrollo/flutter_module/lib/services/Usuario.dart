import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/UsuarioLogged.dart';

class UsuarioService {
  static const _channel = MethodChannel('com.example.bocado/access');
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Nación/género/fecha (datos que Google no provee) en el onboarding.

  static Future<GoogleAuth> signInWithGoogle() async {
  // Siempre aparezca el selector de cuentas
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return GoogleAuth.cancelado(); // el usuario canceló

    // 1) ¿Ya existe una cuenta con ese correo? → login.
    final String response =
        await _channel.invokeMethod('loginGoogle', {'email': account.email});
    final List<dynamic> lista = jsonDecode(response);
    if (lista.isNotEmpty) {
      return GoogleAuth.login(usuario_Logged.fromJson(lista.first));
    }

    // 2) datos de google:
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

  /// Crea el usuario de Google en la app.
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

  /// La cuenta existe y está activa?.

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
    return usuario_Logged.fromJson(data);
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
    final Map<String, dynamic> data = jsonDecode(response);
    return usuario_Logged.fromJson(data);
  }

  // ── Reestablecer pass (OTP) ─────────────────────────────────
  static Future<void> solicitarOtp(String correo) async {
    await _channel.invokeMethod('solicitarOtp', {'correo': correo});
  }

  /// Valida código OTP.
  static Future<bool> verificarOtp(String correo, String codigo) async {
    final bool ok = await _channel.invokeMethod('verificarOtp', {
      'correo': correo,
      'codigo': codigo,
    });
    return ok;
  }

  /// Re-verifica el OTP y cambia la contraseña.
  static Future<void> resetearPassword(String correo, String codigo, String nueva) async {
    await _channel.invokeMethod('resetearPassword', {
      'correo': correo,
      'codigo': codigo,
      'nueva': nueva,
    });
  }
}

class GoogleAuth {
  /// != null  → el correo tiene cuenta: login.
  final usuario_Logged? existente;

  /// != null  → usuario nuevo: falta completar el perfil (onboarding).
  final GooglePerfil? nuevo;

  const GoogleAuth._(this.existente, this.nuevo);

  factory GoogleAuth.cancelado() => const GoogleAuth._(null, null);
  factory GoogleAuth.login(usuario_Logged u) => GoogleAuth._(u, null);
  factory GoogleAuth.registroPendiente(GooglePerfil p) => GoogleAuth._(null, p);

  bool get cancelado => existente == null && nuevo == null;
}

/// Datos de google y onboarding
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
