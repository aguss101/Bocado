/// Validaciones reutilizables para los formularios de autenticación.
///
/// Cada método devuelve un **mensaje de error específico** si el dato es
/// inválido, o `null` si está OK. Así las pantallas pueden encadenarlas con
/// `??` y mostrar el primer error concreto que encuentren.
class Validaciones {
  Validaciones._();

  // Formato de correo: algo@dominio.tld (tld de 2+ caracteres).
  static final RegExp _correoRegExp =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  // Usuario: letras, números, punto y guion bajo (sin espacios ni símbolos).
  static final RegExp _usuarioRegExp = RegExp(r'^[\w.]+$');

  /// Nombre o apellido. [campo] se usa para personalizar el mensaje.
  static String? nombre(String value, {required String campo}) {
    final v = value.trim();
    if (v.isEmpty) return 'Ingresá tu $campo.';
    if (v.length > 50) return 'El $campo es demasiado largo (máx. 50 caracteres).';
    return null;
  }

  /// Correo: requerido + formato válido.
  static String? correo(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Ingresá tu correo electrónico.';
    if (!_correoRegExp.hasMatch(v)) {
      return 'El correo no tiene un formato válido (ej: nombre@dominio.com).';
    }
    return null;
  }

  /// Nombre de usuario: requerido, mínimo 3, sin espacios ni símbolos raros.
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

  /// Contraseña: requerida, mínimo 8 caracteres (igual que el backend).
  static String? contrasena(String value) {
    if (value.isEmpty) return 'Ingresá una contraseña.';
    if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
    return null;
  }

  /// Campo de texto genérico requerido con un [mensaje] a medida.
  static String? requerido(String? value, String mensaje) {
    if (value == null || value.trim().isEmpty) return mensaje;
    return null;
  }
}
