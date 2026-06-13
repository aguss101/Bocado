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
  final int usuarioTarget;
  final String apellidoNombre;
  final String nombreUsuario;
  final String? fotoUsuario;

  ///Comentarios, Calificacion y Favs:
  final int cantidadComentarios;
  final double promedioCalificacion;
  final int cantidadFavoritos;
  final List<Map<String, dynamic>> interacciones;

  ///Nutrientes:
  final double proteinasTotales;
  final double carbohidratosTotales;
  final double grasasTotales;

  RecetaFeed({
    required this.idReceta,
    required this.nombre,
    required this.caloriasTotales,
    required this.porciones,
    required this.foto,
    required this.precioPorcion,
    required this.etiquetas,
    required this.usuarioTarget,
    required this.apellidoNombre,
    required this.nombreUsuario,
    required this.fotoUsuario,
    required this.cantidadComentarios,
    required this.promedioCalificacion,
    required this.cantidadFavoritos,
    required this.interacciones,
    required this.proteinasTotales,
    required this.carbohidratosTotales,
    required this.grasasTotales
  });

  factory RecetaFeed.fromJson(Map<String, dynamic> json) {
    return RecetaFeed(
      idReceta: json['id_receta'] ?? 0,

      ///Receta:
      nombre: json['nombre_receta'] ?? '',
      caloriasTotales: (json['calorias_totales'] ?? 0).toDouble(),
      porciones: json['porciones'] ?? 0,
      foto: json['foto'],
      precioPorcion: (json['precio_porcion'] ?? 0).toDouble(),
      etiquetas: List<String>.from(json['lista_etiquetas'] ?? []),

      ///Usuarios:
      usuarioTarget: json ['id_usuario'] ?? 0,
      apellidoNombre: json['apellido_nombre'] ?? '',
      nombreUsuario: json['usuario'] ?? 'desconocido',
      fotoUsuario: json['foto_perfil'],

      ///Comentarios, Calificaciones y Favs:
      cantidadComentarios: json['cant_comentarios'] ?? 0,
      promedioCalificacion: (json['promedio_calificacion'] ?? 0).toDouble(),
      cantidadFavoritos: json['cant_favoritos'] ?? 0,
      interacciones: (json['lista_interacciones'] as List?)?.map((item)=> Map<String, dynamic>.from(item)).toList() ?? [],

      ///Nutrientes:
      proteinasTotales: (json['proteinas_totales'] ?? 0).toDouble(),
      carbohidratosTotales: (json['carbohidratos_totales'] ?? 0).toDouble(),
      grasasTotales: (json['grasas_totales'] ?? 0).toDouble(),
    );
  }
  bool isLikedBy(int idUsuario){
    return interacciones.any((i)=> i['tipo'] == 'like' && i['id_usuario'] == idUsuario);
  }
  bool isSavedBy(int idUsuario){
    return interacciones.any((i)=> i['tipo'] == 'save' && i['id_usuario'] == idUsuario);
  }
}