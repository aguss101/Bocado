import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class RecipeDetailData {
  final String title;
  final String category;
  final String imageUrl;
  final int calories;
  final String protein;
  final String carbs;
  final String fats;
  final String duration;
  final String servings;
  final List<IngredientItem> ingredients;
  final List<PreparationStep> steps;

  const RecipeDetailData({
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.duration,
    required this.servings,
    required this.ingredients,
    required this.steps,
  });
}

class IngredientItem {
  final String name;
  final String amount;
  final bool highlighted;

  const IngredientItem({
    required this.name,
    required this.amount,
    this.highlighted = false,
  });
}

class PreparationStep {
  final int number;
  final String title;
  final String description;
  final List<String> imageUrls;
  final String? duration;

  const PreparationStep({
    required this.number,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    this.duration,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class RecipeDetailScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final RecipeDetailData data;

  const RecipeDetailScreen({
    super.key,
    required this.themeNotifier,
    required this.data,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final surface = isDark ? AppTheme.surfaceContainerDark : AppTheme.surfaceContainerLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ──────────────────────────────────────────────────
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
                  // Imagen hero
                  widget.data.imageUrl.startsWith('http')
                      ? Image.network(
                    widget.data.imageUrl,
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

                  // Gradiente inferior
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),

                  // Título y categoría sobre la imagen
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
                            widget.data.category.toUpperCase(),
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
                          widget.data.title,
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

                  // Botón favorito
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
                          color:
                          _isFavorite ? Colors.red : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info rápida ────────────────────────────────────────
                  Row(
                    children: [
                      _QuickInfo(
                        icon: Icons.schedule_outlined,
                        label: widget.data.duration,
                      ),
                      const SizedBox(width: 24),
                      _QuickInfo(
                        icon: Icons.restaurant_outlined,
                        label: widget.data.servings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Información Nutricional ────────────────────────────
                  _SectionTitle('Información Nutricional'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _NutriCard(
                          label: 'Calorías',
                          value: '${widget.data.calories}',
                          sub: 'por porción',
                          surface: surface,
                          outline: outline),
                      _NutriCard(
                          label: 'Proteína',
                          value: widget.data.protein,
                          sub: 'alta calidad',
                          surface: surface,
                          outline: outline),
                      _NutriCard(
                          label: 'Carbohidratos',
                          value: widget.data.carbs,
                          sub: 'complejos',
                          surface: surface,
                          outline: outline),
                      _NutriCard(
                          label: 'Grasas',
                          value: widget.data.fats,
                          sub: 'totales',
                          surface: surface,
                          outline: outline),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Ingredientes ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle('Ingredientes'),
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
                  ...widget.data.ingredients
                      .map((i) => _IngredientRow(item: i, outline: outline)),
                  const SizedBox(height: 28),

                  // ── Preparación ────────────────────────────────────────
                  _SectionTitle('Preparación'),
                  const SizedBox(height: 16),
                  ...widget.data.steps.asMap().entries.map((entry) {
                    final isLast =
                        entry.key == widget.data.steps.length - 1;
                    return _StepCard(
                      step: entry.value,
                      isLast: isLast,
                      outline: outline,
                      surface: surface,
                    );
                  }),

                  const SizedBox(height: 80), // espacio para bottom nav
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Nav ───────────────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(),
    );
  }
}

// ── Componentes privados ──────────────────────────────────────────────────────

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
    final highlighted = item.highlighted;
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
              item.name,
              style: TextStyle(
                color: highlighted
                    ? AppTheme.primary.withValues(alpha: 0.9)
                    : null,
                fontWeight:
                highlighted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            item.amount,
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
          // Línea de tiempo
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
                      color: step.number == 1
                          ? AppTheme.primary
                          : outline,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${step.number}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: step.number == 1
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

          // Contenido del paso
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
                      step.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),

                    // Duración (si existe)
                    if (step.duration != null) ...[
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
                                  step.duration!,
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

                    // Imágenes del paso (si existen)
                    if (step.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: step.imageUrls.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              step.imageUrls[i],
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

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;
    final inactive = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: outline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_outlined, label: 'Inicio', active: false, inactive: inactive),
          _NavItem(icon: Icons.menu_book_outlined, label: 'Recetas', active: true, inactive: inactive),
          // FAB central
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
          _NavItem(icon: Icons.favorite_border, label: 'Favoritos', active: false, inactive: inactive),
          _NavItem(icon: Icons.person_outline, label: 'Perfil', active: false, inactive: inactive),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color inactive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.primary : inactive;
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ejemplo de uso ────────────────────────────────────────────────────────────
// Navegación desde otro screen:
//
// Navigator.push(context, MaterialPageRoute(
//   builder: (_) => RecipeDetailScreen(
//     themeNotifier: widget.themeNotifier,
//     data: RecipeDetailData(
//       title: 'Artisan Sourdough',
//       category: 'Panadería Artesanal',
//       imageUrl: 'https://...',
//       calories: 185,
//       protein: '6.2g',
//       carbs: '36g',
//       fats: '0.8g',
//       duration: '24h 30m',
//       servings: '12 rebanadas',
//       ingredients: [
//         IngredientItem(name: 'Harina de fuerza orgánica', amount: '500g'),
//         IngredientItem(name: 'Agua filtrada (tibia)', amount: '350ml'),
//         IngredientItem(name: 'Masa madre activa', amount: '100g', highlighted: true),
//         IngredientItem(name: 'Sal marina fina', amount: '10g'),
//       ],
//       steps: [
//         PreparationStep(
//           number: 1,
//           title: 'Autolisis y Mezcla',
//           description: 'Mezcla la harina y el agua...',
//           imageUrls: ['https://...', 'https://...'],
//         ),
//         PreparationStep(
//           number: 2,
//           title: 'Fermentación en Bloque',
//           description: 'Realiza 4 series de pliegues...',
//           duration: '4 - 6 horas',
//         ),
//         PreparationStep(
//           number: 3,
//           title: 'Formado y Horneado',
//           description: 'Da forma a la masa...',
//           imageUrls: ['https://...'],
//         ),
//       ],
//     ),
//   ),
// ));
