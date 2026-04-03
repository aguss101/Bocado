import 'package:flutter/material.dart';
import '../theme/theme_notifier.dart';
import 'shared_drawer.dart';

// Modelo de datos para las recetas
class RecipePreview {
  final String title;
  final String category;
  final String time;
  final String level;
  final String rating;
  final String imageUrl;

  const RecipePreview({
    required this.title,
    required this.category,
    required this.time,
    required this.level,
    required this.rating,
    required this.imageUrl,
  });
}

class MyRecipesScreen extends StatefulWidget {
  final int usuarioId;
  final String usuarioNombre;
  final ThemeNotifier themeNotifier;

  const MyRecipesScreen({
    super.key,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.themeNotifier,
  });

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  static const Color bgColor = Color(0xFF0D0701);
  static const Color primaryColor = Color(0xFFD96E11);
  static const Color surfaceColor = Color(0xFF130E09);
  static const Color textColor = Color(0xFFF8FAFC);
  static const Color mutedColor = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFF1E293B);

  // Lista de recetas generada al instante
  late final List<RecipePreview> _recetasDelUsuario;

  @override
  void initState() {
    super.initState();
    // ── Cargamos las recetas de ejemplo INMEDIATAMENTE ──
    _recetasDelUsuario = [
      RecipePreview(
        title: 'Masa Madre de ${widget.usuarioNombre}',
        category: 'Panadería',
        time: '18h',
        level: 'Experto',
        rating: '4.9',
        imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=600&auto=format&fit=crop',
      ),
      RecipePreview(
        title: 'Pizza Especial (Receta #${widget.usuarioId})',
        category: 'Italiana',
        time: '45m',
        level: 'Medio',
        rating: '5.0',
        imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?q=80&w=600&auto=format&fit=crop',
      ),
      RecipePreview(
        title: 'Salmón del Chef',
        category: 'Mar',
        time: '20m',
        level: 'Fácil',
        rating: '4.7',
        imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=600&auto=format&fit=crop',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      endDrawer: SharedDrawer(
        usuarioId: widget.usuarioId,
        usuarioNombre: widget.usuarioNombre,
        themeNotifier: widget.themeNotifier,
        rutaActual: 'recetas',
      ),

      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: mutedColor),
        title: Container(
          decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12)),
          child: const TextField(
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar en mis recetas...',
              hintStyle: TextStyle(color: mutedColor),
              prefixIcon: Icon(Icons.search, color: mutedColor, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list, color: mutedColor), onPressed: () {}),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: primaryColor),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ── El cuerpo ahora se dibuja directo, sin esperas ──
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mis Recetas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 4),
                  const Text('Gestiona tu catálogo personal de creaciones culinarias.', style: TextStyle(fontSize: 14, color: mutedColor)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildFilterChip('MÁS RECIENTES'),
                      const SizedBox(width: 8),
                      _buildFilterChip('A-Z'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index == _recetasDelUsuario.length) return _buildCreateNewCard();
                  return _buildRecipeCard(_recetasDelUsuario[index]);
                },
                childCount: _recetasDelUsuario.length + 1,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Componentes de UI Internos ──

  Widget _buildRecipeCard(RecipePreview recipe) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(recipe.imageUrl, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [bgColor.withValues(alpha: 0.8), Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(recipe.category.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(recipe.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('TIEMPO', recipe.time),
                      Container(height: 20, width: 1, color: borderColor),
                      _buildMiniStat('NIVEL', recipe.level),
                      Container(height: 20, width: 1, color: borderColor),
                      _buildMiniRating(recipe.rating),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildMiniRating(String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RATING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 1)),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(width: 2),
            const Icon(Icons.star, color: primaryColor, size: 10),
          ],
        ),
      ],
    );
  }

  Widget _buildCreateNewCard() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(color: borderColor, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: mutedColor),
          ),
          const SizedBox(height: 12),
          const Text('Nueva Receta', style: TextStyle(color: mutedColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(label, style: const TextStyle(color: mutedColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }
}