/// Codifica un id entero a un slug corto reversible para usar en links públicos
/// (perfiles y recetas), de modo que el id real no quede a la vista en la URL.
///
/// No es criptografía: es una biyección determinista (multiplicación modular tipo
/// Knuth/Optimus + base62). Alcanza para que el id no sea obvio ni predecible en el
/// link, sin tocar la base de datos ni hacer consultas extra (decodifica local).
class IdCodec {
  // Módulo primo (2^31 - 1): cualquier multiplicador en [1, _mod) es coprimo → invertible.
  static const int _mod = 2147483647;

  // Multiplicadores distintos por tipo: el mismo id da slugs distintos en perfil vs receta.
  static const int _multPerfil = 1580030173;
  static const int _multReceta = 1212121211;

  // Letras primero para que los slugs cortos empiecen con letra. Todos URL-safe.
  static const String _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  static String encodePerfil(int id) => _encode(id, _multPerfil);
  static int? decodePerfil(String slug) => _decode(slug, _multPerfil);

  static String encodeReceta(int id) => _encode(id, _multReceta);
  static int? decodeReceta(String slug) => _decode(slug, _multReceta);

  static String _encode(int id, int mult) => _toBase62((id * mult) % _mod);

  static int? _decode(String slug, int mult) {
    final y = _fromBase62(slug);
    if (y == null || y <= 0 || y >= _mod) return null;
    final id = (y * _modInverse(mult, _mod)) % _mod;
    return id > 0 ? id : null;
  }

  static String _toBase62(int n) {
    if (n == 0) return _alphabet[0];
    final b = _alphabet.length;
    final chars = <String>[];
    var x = n;
    while (x > 0) {
      chars.add(_alphabet[x % b]);
      x ~/= b;
    }
    return chars.reversed.join();
  }

  static int? _fromBase62(String s) {
    if (s.isEmpty) return null;
    final b = _alphabet.length;
    var n = 0;
    for (var i = 0; i < s.length; i++) {
      final idx = _alphabet.indexOf(s[i]);
      if (idx < 0) return null;
      n = n * b + idx;
    }
    return n;
  }

  // Inverso modular por Euclides extendido (mult es coprimo con _mod primo → siempre existe).
  static int _modInverse(int a, int m) {
    int t = 0, newT = 1;
    int r = m, newR = a % m;
    while (newR != 0) {
      final q = r ~/ newR;
      final tmpT = t - q * newT;
      t = newT;
      newT = tmpT;
      final tmpR = r - q * newR;
      r = newR;
      newR = tmpR;
    }
    if (t < 0) t += m;
    return t;
  }
}
