import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_module/models/usuario_Logged.dart';
import 'package:flutter_module/screens/feed_screen.dart';
import 'package:flutter_module/screens/shared_drawer.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

class RecipeDetailData {
  final String titulo;
  final String categoria;
  final String imageUrl;
  final double calorias;
  final String proteina;
  final String carbos;
  final String grasas;
  final String duracion;
  final String porciones;
  final List<IngredientItem> ingredientes;
  final List<PreparationStep> pasos;

  const RecipeDetailData({
    required this.titulo,
    required this.categoria,
    required this.imageUrl,
    required this.calorias,
    required this.proteina,
    required this.carbos,
    required this.grasas,
    required this.duracion,
    required this.porciones,
    required this.ingredientes,
    required this.pasos,
  });

  factory RecipeDetailData.fromJson(Map<String, dynamic> json, double _prot, double _carb, double _gras) {
    return RecipeDetailData(
      titulo: json['nombre'] ?? '',
      categoria: 'General', ///Usar etiquetas???
      imageUrl: json['foto'] ?? '',
      calorias: (json['calorias_totales'] ?? 0).toDouble(),
      proteina: _prot.toStringAsFixed(1),
      carbos: _carb.toStringAsFixed(1),
      grasas: _gras.toStringAsFixed(1),
      duracion: 'N/A', /// Que hacemos con esto? lo sacamos directamente de las instrucciones y hacemos que lo puedan elegir desde las pantallas de crearReceta?
      porciones: '${json['porciones'] ?? 0} porciones',
      ingredientes: (json['recetas_alimentos'] as List? ?? [])
          .map((item) => IngredientItem.fromJson(item))
          .toList(),
      pasos: PreparationStep.parsearInstrucciones(json['instrucciones'] ?? ''),
    );
  }
}

class IngredientItem {
  final String nombre;
  final String cantidad;
  final bool resaltado;

  const IngredientItem({
    required this.nombre,
    required this.cantidad,
    this.resaltado = false,
  });

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> alimento = json['alimentos'] ?? {};
    return IngredientItem(
      nombre: alimento['nombre'] ?? 'Ingrediente desconocido',
      cantidad: '${json['cantidad'] ?? 0}g',
      resaltado: false,
    );
  }
}

class PreparationStep {
  final int numeroPaso;
  final String titulo;
  final String descripcion;
  final String? duracion;
  final List<String> imagenes;

  const PreparationStep({
    required this.numeroPaso,
    required this.titulo,
    required this.descripcion,
    this.duracion,
    this.imagenes = const [],
  });

  static List<PreparationStep> parsearInstrucciones(String cadena) {
    if (cadena.isEmpty) return [];

    List<String> fragmentos = cadena.split('|');
    List<PreparationStep> pasos = [];

    for (int i = 0; i < fragmentos.length; i++) {
      String pasoTrim = fragmentos[i].trim();

      if (pasoTrim.isNotEmpty) {
        pasos.add(
            PreparationStep(
              numeroPaso: i + 1,
              titulo: 'Paso ${i + 1}',
              descripcion: pasoTrim,
            )
        );
      }
    }
    return pasos;
  }
}

class RecipeDetailScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final usuario_Logged user;
  final int idReceta;
  final double protFeed;
  final double carbFeed;
  final double grasFeed;

  const RecipeDetailScreen({
    super.key,
    required this.themeNotifier,
    required this.user,
    required this.idReceta,
    required this.protFeed,
    required this.carbFeed,
    required this.grasFeed,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isFavorite = false;
  bool _isLoading = true;
  RecipeDetailData? _data;

  static const _channel = MethodChannel('com.example.bocado/recetas');

  @override
  void initState() {
    super.initState();
    _traerDetalleDeLaReceta();
  }

  Future<void> _traerDetalleDeLaReceta() async {
      try{
        final jsonString = await _channel.invokeMethod('getRecetaDetalle', {'id': widget.idReceta});
        final List<dynamic> jsonList = jsonDecode(jsonString);
        if(jsonList.isNotEmpty){
          final Map<String, dynamic> recetaJson = jsonList.first;
          if(mounted){
            setState(() {
              _data = RecipeDetailData.fromJson(
                recetaJson,
                widget.protFeed,
                widget.carbFeed,
                widget.grasFeed,
              );
              _isLoading = false;
            });
          }
        }
      } catch (e){
        print ("Error del traer de java: $e");
        if(mounted) setState(() {_isLoading = false;});
      }
    }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final surface = isDark ? AppTheme.surfaceContainerDark : AppTheme.surfaceContainerLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_data == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text("¡Ups! Error al cargar la receta", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Volver al Feed")
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: widget.themeNotifier,
                builder: (_, mode, __) => IconButton(
                  onPressed: widget.themeNotifier.toggle,
                  icon: Icon(
                    mode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _data!.imageUrl.startsWith('http')
                      ? Image.network(
                    _data!.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surfaceContainerDark,
                      child: const Icon(Icons.restaurant_menu,
                          size: 64, color: AppTheme.primary),
                    ),
                  )
                      : Container(
                    color: AppTheme.surfaceContainerDark,
                    child: const Icon(Icons.restaurant_menu,
                        size: 64, color: AppTheme.primary),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _data!.categoria.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _data!.titulo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => setState(() => _isFavorite = !_isFavorite),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _QuickInfo(
                        icon: Icons.schedule_outlined,
                        label: _data!.duracion,
                      ),
                      const SizedBox(width: 24),
                      _QuickInfo(
                        icon: Icons.restaurant_outlined,
                        label: _data!.porciones,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Información Nutricional'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.8,
                    children: [
                      _NutriCard(
                          label: 'Calorías',
                          value: '${_data!.calorias.toInt()}',
                          sub: 'por porción',
                          surface: surface,
                          outline: outline),
                      _NutriCard(
                          label: 'Proteína',
                          value: _data!.proteina,
                          sub: 'alta calidad',
                          surface: surface,
                          outline: outline),
                      _NutriCard(
                          label: 'Carbohidratos',
                          value: _data!.carbos,
                          sub: 'complejos',
                          surface: surface,
                          outline: outline),
                      _NutriCard(
                          label: 'Grasas',
                          value: _data!.grasas,
                          sub: 'totales',
                          surface: surface,
                          outline: outline),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('Ingredientes'),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.shopping_cart_outlined,
                            size: 14, color: AppTheme.primary),
                        label: const Text(
                          'AÑADIR TODO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._data!.ingredientes
                      .map((i) => _IngredientRow(item: i, outline: outline)),
                  const SizedBox(height: 28),
                  const _SectionTitle('Preparación'),
                  const SizedBox(height: 16),
                  ..._data!.pasos.asMap().entries.map((entry) {
                    final isLast = entry.key == _data!.pasos.length - 1;
                    return _StepCard(
                      step: entry.value,
                      isLast: isLast,
                      outline: outline,
                      surface: surface,
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _NutriCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color surface;
  final Color outline;

  const _NutriCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.surface,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientItem item;
  final Color outline;
  const _IngredientRow({required this.item, required this.outline});

  @override
  Widget build(BuildContext context) {
    final highlighted = item.resaltado;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppTheme.primary.withValues(alpha: 0.3)
              : outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          highlighted
              ? const Icon(Icons.check_circle,
              color: AppTheme.primary, size: 16)
              : Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.nombre,
              style: TextStyle(
                color: highlighted
                    ? AppTheme.primary.withValues(alpha: 0.9)
                    : null,
                fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            item.cantidad,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlighted
                  ? AppTheme.primary
                  : Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final PreparationStep step;
  final bool isLast;
  final Color outline;
  final Color surface;

  const _StepCard({
    required this.step,
    required this.isLast,
    required this.outline,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step.numeroPaso == 1 ? AppTheme.primary : outline,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${step.numeroPaso}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: step.numeroPaso == 1
                            ? AppTheme.primary
                            : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outline.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    if (step.duracion != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border:
                          Border.all(color: outline.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DURACIÓN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  step.duracion!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (step.imagenes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: step.imagenes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              step.imagenes[i],
                              width: 160,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 160,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.image_outlined,
                                    color: AppTheme.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}