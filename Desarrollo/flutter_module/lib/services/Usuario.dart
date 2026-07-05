import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/UsuarioLogged.dart';
import '../models/UserProfile.dart';

class UsuarioService {
  static const _channel = MethodChannel('com.example.bocado/access');
  static final GoogleSignIn _googleSignIn = GoogleSignIn();


  static Future<GoogleAuth> signInWithGoogle() async {
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return GoogleAuth.cancelado();

    final String response =
        await _channel.invokeMethod('loginGoogle', {'email': account.email});
    final List<dynamic> lista = jsonDecode(response);
    if (lista.isNotEmpty) {
      return GoogleAuth.login(usuario_Logged.fromJson(lista.first));
    }

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
    String? bio,
  }) async {
    await _channel.invokeMethod('actualizarPerfil', {
      'id': id,
      'usuario': usuario,
      if (correo != null && correo.isNotEmpty) 'correo': correo,
      if (idGenero != null) 'id_genero': idGenero,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      if (bannerUrl != null) 'bannerUrl': bannerUrl,
      if (visibilidad != null) 'visibilidad': visibilidad,
      if (bio != null) 'bio': bio,
    });
  }

  static Future<Map<String, dynamic>> getPerfilEditable(int id) async {
    final String response =
        await _channel.invokeMethod('getPerfilEditable', {'id_usuario': id});
    return jsonDecode(response) as Map<String, dynamic>;
  }

  static Future<int> contarSeguidores(int id) async {
    final result = await _channel.invokeMethod('contarSeguidores', {'id_usuario': id});
    return result as int;
  }

  static Future<int> contarSiguiendo(int id) async {
    final result = await _channel.invokeMethod('contarSiguiendo', {'id_usuario': id});
    return result as int;
  }

  static Future<bool> estasSiguiendo(int idSeguidor, int idSeguido) async {
    final result = await _channel.invokeMethod('estasSiguiendo', {
      'id_seguidor': idSeguidor,
      'id_seguido': idSeguido,
    });
    return result as bool;
  }

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

  static Future<void> solicitarOtp(String correo) async {
    await _channel.invokeMethod('solicitarOtp', {'correo': correo});
  }

  static Future<bool> verificarOtp(String correo, String codigo) async {
    final bool ok = await _channel.invokeMethod('verificarOtp', {
      'correo': correo,
      'codigo': codigo,
    });
    return ok;
  }

  static Future<void> resetearPassword(String correo, String codigo, String nueva) async {
    await _channel.invokeMethod('resetearPassword', {
      'correo': correo,
      'codigo': codigo,
      'nueva': nueva,
    });
  }
}

class GoogleAuth {
  final usuario_Logged? existente;

  final GooglePerfil? nuevo;

  const GoogleAuth._(this.existente, this.nuevo);

  factory GoogleAuth.cancelado() => const GoogleAuth._(null, null);
  factory GoogleAuth.login(usuario_Logged u) => GoogleAuth._(u, null);
  factory GoogleAuth.registroPendiente(GooglePerfil p) => GoogleAuth._(null, p);

  bool get cancelado => existente == null && nuevo == null;
}

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
