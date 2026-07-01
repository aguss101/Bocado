import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/UsuarioLogged.dart';
import '../models/UserProfile.dart';

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
  static Future<List<UserProfile>> getSeguidores(int idUsuario, {int? limit, int? offset}) async{
    try{
      final String jsonString = await _channel.invokeMethod('getSeguidores', {
        'id_usuario': idUsuario,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      });
      final List<dynamic> jsonList = jsonDecode(jsonString);

      return jsonList.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> actualizarPerfil({
    required int id,
    required String usuario,
    String? correo,
    int? idGenero,
    String? fotoUrl,
    String? bannerUrl,
    bool? visibilidad,
  }) async {
    await _channel.invokeMethod('actualizarPerfil', {
      'id': id,
      'usuario': usuario,
      if (correo != null && correo.isNotEmpty) 'correo': correo,
      if (idGenero != null) 'id_genero': idGenero,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      if (bannerUrl != null) 'bannerUrl': bannerUrl,
      if (visibilidad != null) 'visibilidad': visibilidad,
    });
  }

  /// Trae los campos editables del PROPIO perfil: { usuario, correo, id_genero }.
  static Future<Map<String, dynamic>> getPerfilEditable(int id) async {
    final String response =
        await _channel.invokeMethod('getPerfilEditable', {'id_usuario': id});
    return jsonDecode(response) as Map<String, dynamic>;
  }

  /// Conteo liviano de seguidores del usuario (Java trae solo los id_seguidor).
  static Future<int> contarSeguidores(int id) async {
    final result = await _channel.invokeMethod('contarSeguidores', {'id_usuario': id});
    return result as int;
  }

  /// Conteo liviano de usuarios a los que sigue este usuario (id_seguidor = id).
  static Future<int> contarSiguiendo(int id) async {
    final result = await _channel.invokeMethod('contarSiguiendo', {'id_usuario': id});
    return result as int;
  }

  /// Comprueba si [idSeguidor] ya sigue a [idSeguido].
  static Future<bool> estasSiguiendo(int idSeguidor, int idSeguido) async {
    final result = await _channel.invokeMethod('estasSiguiendo', {
      'id_seguidor': idSeguidor,
      'id_seguido': idSeguido,
    });
    return result as bool;
  }

  /// Lista de quién sigue a [idUsuario] (inverso de getSeguidores).
  static Future<List<UserProfile>> getSeguidoresDe(int idUsuario, {int? limit, int? offset}) async {
    try {
      final String jsonString = await _channel.invokeMethod('getSeguidoresDe', {
        'id_usuario': idUsuario,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      });
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// De [idsSeguido], cuáles ya sigue [idSeguidor]. Un solo pedido para toda una lista.
  static Future<Set<int>> estasSiguiendoVarios(int idSeguidor, List<int> idsSeguido) async {
    if (idsSeguido.isEmpty) return {};
    try {
      final String jsonString = await _channel.invokeMethod('estasSiguiendoVarios', {
        'id_seguidor': idSeguidor,
        'ids_seguido': idsSeguido,
      });
      final List<dynamic> lista = jsonDecode(jsonString);
      return lista.map((e) => e as int).toSet();
    } catch (e) {
      return {};
    }
  }

  /// Aplica cambios de perfil tras verificar el OTP, de forma atómica
  /// (RPC actualizar_perfil_otp). [datos] = p_data: usuario, correo, id_genero, foto, banner.
  /// Lanza PlatformException si el código es inválido/vencido.
  static Future<void> actualizarPerfilOtp({
    required int id,
    required String codigo,
    required Map<String, dynamic> datos,
  }) async {
    await _channel.invokeMethod('actualizarPerfilOtp', {
      'id': id,
      'codigo': codigo,
      'datos': datos,
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
