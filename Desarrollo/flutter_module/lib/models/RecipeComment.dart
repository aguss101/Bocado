class RecipeComment {
  final int idComentario;
  final int? idComentarioPadre;
  final int idUsuario;
  final String comentario;
  final DateTime fechaComentario;
  final double? calificacion;
  final String nombreUsuario;
  final String avatarUrl;
  List<RecipeComment> respuestas;

  RecipeComment({
    required this.idComentario,
    this.idComentarioPadre,
    required this.idUsuario,
    required this.comentario,
    required this.fechaComentario,
    this.calificacion,
    required this.nombreUsuario,
    this.avatarUrl = '',
    this.respuestas = const [],
  });

  factory RecipeComment.fromJson(Map<String, dynamic> json){
    return RecipeComment(
      idComentario: json["id_comentario"],
      idComentarioPadre: json["id_comentario_padre"],
      idUsuario: json["id_comentarista"],
      comentario: json["comentario"],
      fechaComentario: DateTime.parse(json["fecha_comentario"]),
      calificacion: json["calificacion"]?.toDouble(),
      nombreUsuario: json["usuario"],
      avatarUrl: json["foto"] ?? '',
      respuestas: json["respuestas"] != null
          ? (json["respuestas"] as List).map((r) => RecipeComment.fromJson(r)).toList()
          : [],
    );
  }
}