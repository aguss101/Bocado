class RecipeComment {
  final int idComentario;
  final int? idComentarioPadre;
  final int idUsuario;
  final String comentario;
  final DateTime? fechaComentario;
  final double? calificacion;
  final String nombreUsuario;
  final String avatarUrl;
  List<RecipeComment> respuestas;

  RecipeComment({
    required this.idComentario,
    this.idComentarioPadre,
    required this.idUsuario,
    required this.comentario,
    this.fechaComentario,
    this.calificacion,
    required this.nombreUsuario,
    this.avatarUrl = '',
    this.respuestas = const [],
  });

  factory RecipeComment.fromJson(Map<String, dynamic> json){
    return RecipeComment(
      idComentario: (json["id_comentario"] as num?)?.toInt() ?? 0,
      idComentarioPadre: (json["id_comentario_padre"] as num?)?.toInt(),
      idUsuario: (json["id_comentarista"] as num?)?.toInt() ?? 0,
      comentario: json["comentario"] ?? '',
      fechaComentario: DateTime.tryParse(json["fecha_comentario"]?.toString() ?? ''),
      calificacion: (json["calificacion"] as num?)?.toDouble(),
      nombreUsuario: json["usuario"] ?? 'Usuario',
      avatarUrl: json["foto"] ?? '',
      respuestas: json["respuestas"] != null
          ? (json["respuestas"] as List).map((r) => RecipeComment.fromJson(r)).toList()
          : [],
    );
  }
}