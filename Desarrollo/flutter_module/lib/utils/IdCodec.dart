class IdCodec {
  static const int _mod = 2147483647;

  static const int _multPerfil = 1580030173;
  static const int _multReceta = 1212121211;

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
