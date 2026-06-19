class UserProfile {
  final int idSeguido;
  final int idSeguidor;
  final String nombreUsuario;
  final String? fotoUrl;
  final int totalRecetas;

  UserProfile({
    required this.idSeguido,
    required this.idSeguidor,
    required this.nombreUsuario,
    this.fotoUrl,
    required this.totalRecetas,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      idSeguido: json['id_seguido'] ?? 0,
      idSeguidor: json['id_seguidor'] ?? 0,
      nombreUsuario: json['nombre_usuario'] ?? 'Usuario Desconocido',
      fotoUrl: json['foto_url'],
      totalRecetas: json['total_recetas'] ?? 0,
    );
  }
}