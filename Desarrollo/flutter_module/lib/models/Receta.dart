class Receta {
  final int id;
  final int idUsuario;
  final String nombre;
  final String? foto;
  final double caloriasTotales;
  final int porciones;
  final double porcionesPeso;
  final String instrucciones;
  final DateTime fechaCreacion;
  final bool visibilidad;
  final bool activo;
  final double precio;

  Receta({
    required this.id,
    required this.idUsuario,
    required this.nombre,
    this.foto,
    required this.caloriasTotales,
    required this.porciones,
    required this.porcionesPeso,
    required this.instrucciones,
    required this.fechaCreacion,
    required this.visibilidad,
    required this.activo,
    required this.precio,
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    return Receta(
      id: json['id'] ?? 0,
      idUsuario: json['id_Usuario'] ?? 0,
      nombre: json['nombre'] ?? '',
      foto: json['foto'],

      caloriasTotales: (json['calorias_Totales'] ?? 0).toDouble(),
      porciones: json['porciones'] ?? 0,
      porcionesPeso: (json['porciones_Peso'] ?? 0).toDouble(),
      instrucciones: json['instrucciones'] ?? '',

      fechaCreacion: json['fecha_Creacion'] != null
          ? DateTime.parse(json['fecha_Creacion'])
          : DateTime.now(),

      visibilidad: json['visibilidad'] ?? false,
      activo: json['activo'] ?? true,
      precio: (json['precio'] ?? 0).toDouble(),
    );
  }
}