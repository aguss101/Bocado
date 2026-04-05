import 'package:flutter_module/models/receta_feed.dart';
import 'package:flutter_module/screens/recipe_detail.dart';

class RecetaDetail {
  ///RecetaFeed:
  final RecetaFeed receta;
  ///Datos que quiero en la nueva pantalla:
  final List<IngredientItem> ingredientes;
  final List<PreparationStep> pasos;
  ///Lo sacamos de pasos o les parece hacer un nuevo campo en la tabla Recetas?
  final String tiempoPreparacion;

  RecetaDetail({
    required this.receta,
    required this.ingredientes,
    required this.pasos,
    required this.tiempoPreparacion
  });

  factory RecetaDetail.fromJson(Map<String, dynamic> json){
    return RecetaDetail(
        receta: RecetaFeed.fromJson(json),
        ingredientes: (json['recetas_alimentos']as List? ?? []).map((item) => IngredientItem.fromJson(item)).toList(),
        pasos: PreparationStep.parsearInstrucciones(json['instrucciones']),
        tiempoPreparacion: (json['tiempo_preparacion'] ?? 'N/A'));
  }
}