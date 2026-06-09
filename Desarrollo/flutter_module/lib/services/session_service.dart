import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_Logged.dart';

class SessionService {
  static const _keyId        = 'session_id';
  static const _keyIdCuenta  = 'session_id_cuenta';
  static const _keyUsuario   = 'session_usuario';
  static const _keyFoto      = 'session_foto';
  static const _keyBanner    = 'session_banner';
  static const _keyFotoUrl   = 'session_foto_url';
  static const _keyBannerUrl = 'session_banner_url';

  /// Persiste los datos del usuario logueado en el dispositivo.
  static Future<void> saveSession(usuario_Logged user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyId,       user.id);
    await prefs.setInt(_keyIdCuenta, user.id_Cuenta);
    await prefs.setString(_keyUsuario, user.usuario);
    if (user.fotoBase64   != null) await prefs.setString(_keyFoto,      user.fotoBase64!);
    if (user.bannerBase64 != null) await prefs.setString(_keyBanner,    user.bannerBase64!);
    if (user.fotoUrl      != null) await prefs.setString(_keyFotoUrl,   user.fotoUrl!);
    if (user.bannerUrl    != null) await prefs.setString(_keyBannerUrl, user.bannerUrl!);
  }

  /// Devuelve el usuario guardado, o null si no hay sesión activa.
  static Future<usuario_Logged?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyId);
    if (id == null) return null;

    return usuario_Logged(
      id,
      prefs.getInt(_keyIdCuenta) ?? 0,
      prefs.getString(_keyUsuario) ?? '',
      prefs.getString(_keyFoto),
      prefs.getString(_keyBanner),
      fotoUrl:   prefs.getString(_keyFotoUrl),
      bannerUrl: prefs.getString(_keyBannerUrl),
    );
  }

  /// Borra la sesión guardada (logout).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyId);
    await prefs.remove(_keyIdCuenta);
    await prefs.remove(_keyUsuario);
    await prefs.remove(_keyFoto);
    await prefs.remove(_keyBanner);
    await prefs.remove(_keyFotoUrl);
    await prefs.remove(_keyBannerUrl);
  }
}
