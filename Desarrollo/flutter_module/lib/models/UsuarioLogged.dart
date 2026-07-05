import 'dart:convert';
import 'dart:typed_data';

class usuario_Logged {
  int id;
  int id_Cuenta;
  String usuario;
  String? fotoBase64;
  String? bannerBase64;
  Uint8List? fotoReady;
  Uint8List? bannerReady;
  String? fotoUrl;
  String? bannerUrl;
  bool visibilidad;
  String? bio;

  usuario_Logged(
    this.id,
    this.id_Cuenta,
    this.usuario,
    this.fotoBase64,
    this.bannerBase64, {
    this.fotoUrl,
    this.bannerUrl,
    this.visibilidad = true,
        this.bio,
  }) {
    fotoReady   = _decode(fotoBase64);
    bannerReady = _decode(bannerBase64);
  }

  static Uint8List? _decode(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }
  factory usuario_Logged.fromJson(Map<String, dynamic> json) {
    return usuario_Logged(
      json['id'] ?? 0,
      json['id_cuenta'] ?? 1,
      json['usuario'] ?? 'Usuario Desconocido',
      null,
      null,
      fotoUrl: json['foto'],
      bannerUrl: json['banner'],
      visibilidad: (json['visibilidad'] as bool?) ?? true,
      bio: json['bio'],
    );
  }
}
