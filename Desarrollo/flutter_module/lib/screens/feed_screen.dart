import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_notifier.dart';
import '../theme/app_theme.dart';
import '../models/receta_feed.dart';
import 'recipe_detail.dart';
import 'shared_drawer.dart';

class FeedScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final int usuarioId;
  final String usuarioNombre;

  const FeedScreen({
    super.key,
    required this.themeNotifier,
    required this.usuarioId,
    required this.usuarioNombre,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<RecetaFeed> recipesFeed = [];
  bool _estaCargando = true;

  static const _channel = MethodChannel('com.example.bocado/recetas');

  @override
  void initState(){
    super.initState();
    _traerRecetas();
  }

  Future<void> _traerRecetas() async{
    try{
      final recipesJson = await _channel.invokeMethod('getRecetas');
      final List<dynamic> listDynamic = jsonDecode(recipesJson);
      final List<RecetaFeed> listRecipes = listDynamic.map((item) => RecetaFeed.fromJson(item)).toList();

      if(mounted){
        setState(() {
          recipesFeed = listRecipes;
          _estaCargando = false;
        });
      }
    } catch (e){
      print(e);
      if(mounted) setState(() {_estaCargando = false;});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final surfaceColor = isDark ? const Color(0xFF1A1108) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D1D0E) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0701) : Colors.grey.shade50,
      endDrawer: SharedDrawer(
        usuarioId: widget.usuarioId,
        usuarioNombre: widget.usuarioNombre,
        themeNotifier: widget.themeNotifier,
        rutaActual: 'inicio',
      ),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0D0701).withValues(alpha: 0.9) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text('Bocado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFFDF7F2) : Colors.black,
                )),
          ],
        ),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: widget.themeNotifier,
            builder: (_, mode, __) => IconButton(
              onPressed: widget.themeNotifier.toggle,
              icon: Icon(
                mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: AppTheme.primary,
              ),
            ),
          ),
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openEndDrawer(),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    widget.usuarioNombre.isNotEmpty ? widget.usuarioNombre[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _estaCargando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: recipesFeed.length,
              itemBuilder: (context, index) {
                final recetaActual = recipesFeed[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(
                          themeNotifier: widget.themeNotifier,
                          usuarioId: widget.usuarioId,
                          usuarioNombre: widget.usuarioNombre,
                          idReceta: recetaActual.idReceta,
                          protFeed: recetaActual.proteinasTotales,
                          carbFeed: recetaActual.carbohidratosTotales,
                          grasFeed: recetaActual.grasasTotales,
                        ),
                      ),
                    );
                  },
                  child: _FeedArticleCard(
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    secondary: secondary,
                    receta: recetaActual,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. COMPONENTE PRIVADO: Tarjeta de la Receta ──
class _FeedArticleCard extends StatefulWidget {
  final Color surfaceColor;
  final Color borderColor;
  final Color secondary;
  final RecetaFeed receta;

  const _FeedArticleCard({
    required this.surfaceColor,
    required this.borderColor,
    required this.secondary,
    required this.receta,
  });

  @override
  State<_FeedArticleCard> createState() => _FeedArticleCardState();
}

class _FeedArticleCardState extends State<_FeedArticleCard> {
  bool _isLiked = false;
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final String fotoUrl = widget.receta.foto ?? '';
    final Widget imageHeader = AspectRatio(
      aspectRatio: 16 / 9,
      child: fotoUrl.startsWith('http')
          ? Image.network(fotoUrl, fit: BoxFit.cover)
          : Image.network(
        'https://images.unsplash.com/photo-1485921325833-c519f76c4927?q=80&w=600&auto=format&fit=crop',
        fit: BoxFit.cover,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGEN Y BADGES
          Stack(
            children: [
              imageHeader,
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    // PRECIO DINÁMICO
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_money, color: AppTheme.primary, size: 14),
                          Text(
                              '${widget.receta.precioPorcion.toStringAsFixed(2)} / porción',
                              style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    if (widget.receta.etiquetas.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                            widget.receta.etiquetas.first,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // CONTENIDO
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABECERA NOMBRE Y PERFIL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.receta.nombre,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Rinde ${widget.receta.porciones} porciones',
                            style: TextStyle(fontSize: 12, color: widget.secondary),
                          ),
                        ],
                      ),
                    ),
                    // FOTO DE PERFIL DEL USUARIO CREADOR
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(
                          widget.receta.fotoUsuario ?? 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: widget.secondary),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GRILLA NUTRICIONAL CON VARIABLES DE LA BD
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutriCol('CALORÍAS', '${widget.receta.caloriasTotales.toInt()}', widget.secondary),
                      _buildDivider(widget.borderColor),
                      _buildNutriCol('PROTEÍNAS', '${widget.receta.proteinasTotales}g', widget.secondary, valueColor: AppTheme.primary),
                      _buildDivider(widget.borderColor),
                      _buildNutriCol('CARBOS', '${widget.receta.carbohidratosTotales}g', widget.secondary),
                      _buildDivider(widget.borderColor),
                      _buildNutriCol('GRASAS', '${widget.receta.grasasTotales}g', widget.secondary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // BOTONES DE ACCIÓN SOCIALES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildActionButton(
                          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                          label: '${widget.receta.cantidadFavoritos}', // Dinámico
                          color: _isLiked ? AppTheme.primary : widget.secondary,
                          onTap: () => setState(() { _isLiked = !_isLiked; }),
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: '${widget.receta.cantidadComentarios}', // Dinámico
                          color: widget.secondary,
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Compartir',
                          color: widget.secondary,
                          onTap: () {},
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isSaved = !_isSaved),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isSaved ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: _isSaved ? Colors.white : AppTheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Guardar',
                              style: TextStyle(
                                color: _isSaved ? Colors.white : AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutriCol(String label, String value, Color secondary, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: secondary, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(height: 30, width: 1, color: color);
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}