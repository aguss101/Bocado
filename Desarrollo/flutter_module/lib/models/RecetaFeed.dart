import 'dart:convert';

class RecetaFeed {
  ///Receta:
  final int idReceta;
  final String nombre;
  final double caloriasTotales;
  final int porciones;
  final String? foto;
  final double precioPorcion;
  final List<String> etiquetas;
  final double precio;
  final bool activo;
  final bool visibilidad;

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
    required this.activo,
    required this.visibilidad,
    required this.precio,
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
    // Función auxiliar para decodificar si es String o usar si es List
    List<dynamic> decodeList(dynamic val) {
      if (val == null) return [];
      if (val is String) {
        try { return jsonDecode(val); } catch (e) { return []; }
      }
      return val as List<dynamic>;
    }

    return RecetaFeed(
      idReceta: (json['id_receta'] as num?)?.toInt() ?? 0,
      nombre: json['nombre_receta'] ?? '',
      caloriasTotales: (json['calorias_totales'] as num?)?.toDouble() ?? 0.0,
      porciones: (json['porciones'] as num?)?.toInt() ?? 0,
      foto: json['foto'],
      precioPorcion: (json['precio_porcion'] as num?)?.toDouble() ?? 0.0,
      // Aquí forzamos la conversión a List<String>
      etiquetas: List<String>.from(decodeList(json['lista_etiquetas'])),
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      activo: json['activo'] ?? true,
      visibilidad: json['visibilidad'] ?? true,

      usuarioTarget: (json['id_usuario'] as num?)?.toInt() ?? 0,
      apellidoNombre: json['apellido_nombre'] ?? '',
      nombreUsuario: json['usuario'] ?? 'desconocido',
      fotoUsuario: json['foto_perfil'],

      cantidadComentarios: (json['cant_comentarios'] as num?)?.toInt() ?? 0,
      promedioCalificacion: (json['promedio_calificacion'] as num?)?.toDouble() ?? 0.0,
      cantidadFavoritos: (json['cant_favoritos'] as num?)?.toInt() ?? 0,

      // Aquí decodificamos la lista de mapas
      interacciones: decodeList(json['lista_interacciones'])
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),

      proteinasTotales: (json['proteinas_totales'] as num?)?.toDouble() ?? 0.0,
      carbohidratosTotales: (json['carbohidratos_totales'] as num?)?.toDouble() ?? 0.0,
      grasasTotales: (json['grasas_totales'] as num?)?.toDouble() ?? 0.0,
    );
  }
  bool isLikedBy(int idUsuario){
    return interacciones.any((i)=> i['tipo'] == 'like' && i['id_usuario'] == idUsuario);
  }
  bool isSavedBy(int idUsuario){
    return interacciones.any((i)=> i['tipo'] == 'save' && i['id_usuario'] == idUsuario);
  }
}