class UsuarioBusqueda {
  final int id;
  final String usuario;
  final String? foto;

  UsuarioBusqueda({
    required this.id,
    required this.usuario,
    this.foto,
  });

  factory UsuarioBusqueda.fromJson(Map<String, dynamic> json) {
    return UsuarioBusqueda(
      id: json['id'] ?? 0,
      usuario: json['usuario'] ?? 'Usuario Desconocido',
      foto: json['foto'],
    );
  }
}