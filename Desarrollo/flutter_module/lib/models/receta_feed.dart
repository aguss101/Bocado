class RecetaFeed {
  ///Receta:
  final int idReceta;
  final String nombre;
  final double caloriasTotales;
  final int porciones;
  final String? foto;
  final double precioPorcion;
  final List<String> etiquetas;

  ///Usuario:
  final String apellidoNombre;
  final String nombreUsuario;
  final String? fotoUsuario;

  ///Comentarios, Calificacion y Favs:
  final int cantidadComentarios;
  final double promedioCalificacion;
  final int cantidadFavoritos;

  ///Nutrientes:
  final double proteinasTotales;
  final double carbohidratosTotales;
  final double grasasTotales;

  RecetaFeed({
    required this.idReceta, // Lo pedimos en el constructor
    required this.nombre,
    required this.caloriasTotales,
    required this.porciones,
    required this.foto,
    required this.precioPorcion,
    required this.etiquetas,
    required this.apellidoNombre,
    required this.nombreUsuario,
    required this.fotoUsuario,
    required this.cantidadComentarios,
    required this.promedioCalificacion,
    required this.cantidadFavoritos,
    required this.proteinasTotales,
    required this.carbohidratosTotales,
    required this.grasasTotales
  });

  factory RecetaFeed.fromJson(Map<String, dynamic> json) {
    return RecetaFeed(
      // Mapeamos el ID
      idReceta: json['id_receta'] ?? 0,

      ///Receta:
      nombre: json['nombre_receta'] ?? '',
      caloriasTotales: (json['calorias_totales'] ?? 0).toDouble(),
      porciones: json['porciones'] ?? 0,
      foto: json['foto'],
      precioPorcion: (json['precio_porcion'] ?? 0).toDouble(),
      etiquetas: List<String>.from(json['lista_etiquetas'] ?? []),

      ///Usuarios:
      apellidoNombre: json['apellido_nombre'] ?? '',
      nombreUsuario: json['usuario'] ?? 'desconocido',
      fotoUsuario: json['foto_perfil'],

      ///Comentarios, Calificaciones y Favs:
      cantidadComentarios: json['cant_comentarios'] ?? 0,
      promedioCalificacion: (json['promedio_calificacion'] ?? 0).toDouble(),
      cantidadFavoritos: json['cant_favoritos'] ?? 0,

      ///Nutrientes:
      proteinasTotales: (json['proteinas_totales'] ?? 0).toDouble(),
      carbohidratosTotales: (json['carbohidratos_totales'] ?? 0).toDouble(),
      grasasTotales: (json['grasas_totales'] ?? 0).toDouble(),
    );
  }
}