class Validaciones {
  Validaciones._();

  static final RegExp _correoRegExp =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  static final RegExp _usuarioRegExp = RegExp(r'^[\w.]+$');

  static String? nombre(String value, {required String campo}) {
    final v = value.trim();
    if (v.isEmpty) return 'Ingresá tu $campo.';
    if (v.length > 50) return 'El $campo es demasiado largo (máx. 50 caracteres).';
    return null;
  }

  static String? correo(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Ingresá tu correo electrónico.';
    if (!_correoRegExp.hasMatch(v)) {
      return 'El correo no tiene un formato válido (ej: nombre@dominio.com).';
    }
    return null;
  }

  static String? usuario(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Ingresá un nombre de usuario.';
    if (v.length < 3) return 'El usuario debe tener al menos 3 caracteres.';
    if (v.contains(' ')) return 'El usuario no puede tener espacios.';
    if (!_usuarioRegExp.hasMatch(v)) {
      return 'El usuario solo puede tener letras, números, "." y "_".';
    }
    return null;
  }

  static String? contrasena(String value) {
    if (value.isEmpty) return 'Ingresá una contraseña.';
    if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
    return null;
  }

  static String? requerido(String? value, String mensaje) {
    if (value == null || value.trim().isEmpty) return mensaje;
    return null;
  }
}
