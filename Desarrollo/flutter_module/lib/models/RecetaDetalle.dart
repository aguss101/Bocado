import 'package:flutter_module/models/receta_feed.dart';
import 'package:flutter_module/screens/recipe_detail.dart';

class RecetaDetail {
  final RecetaFeed receta;
  final List<IngredientItem> ingredientes;
  final List<PreparationStep> pasos;
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