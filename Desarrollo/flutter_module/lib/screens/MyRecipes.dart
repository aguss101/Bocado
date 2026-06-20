import 'package:flutter/material.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/Common.dart';
import '../models/RecetaFeed.dart';
import '../services/Receta.dart';
import 'BarraNavegacion.dart';
import 'DetailRecipe.dart';

enum _RecetaTab { todas, publicadas, borradores, favoritos }

enum _OrdenCampo { nombre, precio, calorias, rating }

class _OrdenOption {
  final _OrdenCampo campo;
  final bool ascendente;
  const _OrdenOption(this.campo, this.ascendente);

  String get label {
    final nombreCampo = switch (campo) {
      _OrdenCampo.nombre => 'Nombre',
      _OrdenCampo.precio => 'Precio',
      _OrdenCampo.calorias => 'Calorías',
      _OrdenCampo.rating => 'Rating',
    };
    return '$nombreCampo ${ascendente ? '↑' : '↓'}';
  }

  @override
  bool operator ==(Object other) =>
      other is _OrdenOption && other.campo == campo && other.ascendente == ascendente;

  @override
  int get hashCode => Object.hash(campo, ascendente);
}

class MyRecipesScreen extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;

  const MyRecipesScreen({
    super.key,
    required this.user,
    required this.themeNotifier,
  });

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  BocadoColors get _c => BocadoColors.of(context);
  Color get surfaceColor => _c.surface;
  Color get textColor    => _c.text;
  Color get mutedColor   => _c.muted;
  Color get borderColor  => _c.border;

  List<RecetaFeed> _recetas = [];
  bool _cargando = true;

  _RecetaTab _tabSeleccionada = _RecetaTab.todas;
  final TextEditingController _searchController = TextEditingController();
  String _busqueda = '';

  _OrdenOption _orden = const _OrdenOption(_OrdenCampo.nombre, true);

  @override
  void initState() {
    super.initState();
    _cargarRecetas();
    _searchController.addListener(() {
      setState(() => _busqueda = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarRecetas() async {
    try {
      final lista = await RecetaService.getRecetasUsuario(widget.user.id);
      if (mounted) {
        setState(() {
          _recetas = lista;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  bool _esFavorito(RecetaFeed r) => r.usuarioTarget != widget.user.id;

  bool _esPublicada(RecetaFeed r) => r.activo == true && r.visibilidad == true;

  bool _esBorrador(RecetaFeed r) => r.activo == false && r.visibilidad == false;

  String? _primeraFoto(RecetaFeed r) {
    final foto = r.foto;
    if (foto == null || foto.isEmpty) return null;
    final primera = foto.split('|').first.trim();
    return primera.isEmpty ? null : primera;
  }

  List<RecetaFeed> get _porTab {
    switch (_tabSeleccionada) {
      case _RecetaTab.todas:
        return _recetas;
      case _RecetaTab.publicadas:
        return _recetas.where(_esPublicada).toList();
      case _RecetaTab.borradores:
        return _recetas.where(_esBorrador).toList();
      case _RecetaTab.favoritos:
        return _recetas.where(_esFavorito).toList();
    }
  }

  List<RecetaFeed> get _filtradas {
    final base = _porTab;
    if (_busqueda.isEmpty) return base;
    return base.where((r) {
      final nombreMatch = r.nombre.toLowerCase().contains(_busqueda);
      final etiquetaMatch =
      r.etiquetas.any((e) => e.toLowerCase().contains(_busqueda));
      return nombreMatch || etiquetaMatch;
    }).toList();
  }

  List<RecetaFeed> get _recetasVisibles {
    final lista = List<RecetaFeed>.from(_filtradas);
    int compare(RecetaFeed a, RecetaFeed b) {
      switch (_orden.campo) {
        case _OrdenCampo.nombre:
          return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
        case _OrdenCampo.precio:
          return a.precio.compareTo(b.precio);
        case _OrdenCampo.calorias:
          return a.caloriasTotales.compareTo(b.caloriasTotales);
        case _OrdenCampo.rating:
          return a.promedioCalificacion.compareTo(b.promedioCalificacion);
      }
    }

    lista.sort(_orden.ascendente ? compare : (a, b) => compare(b, a));
    return lista;
  }

  bool _tabHabilitada(_RecetaTab tab) {
    switch (tab) {
      case _RecetaTab.todas:
        return _recetas.isNotEmpty;
      case _RecetaTab.publicadas:
        return _recetas.any(_esPublicada);
      case _RecetaTab.borradores:
        return _recetas.any(_esBorrador);
      case _RecetaTab.favoritos:
        return _recetas.any(_esFavorito);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recetasVisibles = _recetasVisibles;

    return Scaffold(
      backgroundColor: _c.bg,
      endDrawer: SharedDrawer(
        user: widget.user,
        themeNotifier: widget.themeNotifier,
        rutaActual: 'recetas',
      ),
      appBar: AppBar(
        backgroundColor: _c.bg.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: IconThemeData(color: mutedColor),
        title: Container(
          decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o etiqueta...',
              hintStyle: TextStyle(color: mutedColor),
              prefixIcon: Icon(Icons.search, color: mutedColor, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: mutedColor),
            onPressed: _abrirSelectorOrden,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.primary),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis Recetas',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recetasVisibles.length} recetas',
                    style: TextStyle(fontSize: 14, color: mutedColor),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildTabsRow()),
          SliverToBoxAdapter(child: _buildOrdenChip()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (recetasVisibles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRecipeCard(recetasVisibles[index]),
                  childCount: recetasVisibles.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTabsRow() {
    final tabs = [
      (_RecetaTab.todas, 'TODAS'),
      (_RecetaTab.publicadas, 'PUBLICADAS'),
      (_RecetaTab.borradores, 'BORRADORES'),
      (_RecetaTab.favoritos, 'FAVORITOS'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (tab, label) = tabs[index];
          final habilitada = _tabHabilitada(tab);
          final seleccionada = _tabSeleccionada == tab;
          return _buildFilterChip(
            label,
            selected: seleccionada,
            enabled: habilitada,
            onTap: habilitada ? () => setState(() => _tabSeleccionada = tab) : null,
          );
        },
      ),
    );
  }

  Widget _buildOrdenChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: _abrirSelectorOrden,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, color: AppTheme.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  _orden.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirSelectorOrden() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      isScrollControlled: true, // Esto es clave para listas largas
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final opciones = <_OrdenOption>[
          for (final campo in _OrdenCampo.values) ...[
            _OrdenOption(campo, true),
            _OrdenOption(campo, false),
          ],
        ];

        return SafeArea(
          child: Container(
            // Ajuste dinámico de altura para no exceder la pantalla
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ORDENAR POR',
                      style: TextStyle(color: mutedColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: opciones.length,
                    itemBuilder: (context, index) {
                      final opcion = opciones[index];
                      final seleccionado = _orden == opcion;
                      return ListTile(
                        dense: true, // Esto reduce la altura del ListTile
                        visualDensity: VisualDensity.compact, // Reduce el padding interno
                        title: Text(
                          opcion.label,
                          style: TextStyle(
                            color: seleccionado ? AppTheme.primary : textColor,
                            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        trailing: seleccionado
                            ? const Icon(Icons.check, color: AppTheme.primary, size: 18)
                            : null,
                        onTap: () {
                          setState(() => _orden = opcion);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final mensaje = _busqueda.isNotEmpty
        ? 'No encontramos recetas para "$_busqueda"'
        : switch (_tabSeleccionada) {
      _RecetaTab.todas => 'Todavía no tenés recetas',
      _RecetaTab.publicadas => 'No tenés recetas publicadas',
      _RecetaTab.borradores => 'No tenés borradores',
      _RecetaTab.favoritos => 'No tenés recetas favoritas',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: BocadoEmptyState(icon: Icons.ramen_dining_outlined, message: mensaje),
    );
  }

  Widget _buildRecipeCard(RecetaFeed receta) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            themeNotifier: widget.themeNotifier,
            user: widget.user,
            idReceta: receta.idReceta,
            protFeed: receta.proteinasTotales,
            carbFeed: receta.carbohidratosTotales,
            grasFeed: receta.grasasTotales,
            idAutor: receta.usuarioTarget,
          ),
        ),
      ),
      child: Container(
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(
                    builder: (context) {
                      final url = _primeraFoto(receta);
                      const fallback =
                          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=300&auto=format&fit=crop';
                      return Image.network(
                        url ?? fallback,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.network(
                          fallback,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppTheme.bgDark.withValues(alpha: 0.8), Colors.transparent],
                      ),
                    ),
                  ),
                  if (receta.etiquetas.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: _esBorrador(receta) ? null : 8,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            receta.etiquetas.first.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_esBorrador(receta))
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BORRADOR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receta.nombre,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: _buildMiniStat('CAL', '${receta.caloriasTotales.toInt()}')),
                      Container(height: 18, width: 1, color: borderColor),
                      Flexible(child: _buildMiniStat('PROT', '${receta.proteinasTotales.toInt()}g')),
                      Container(height: 18, width: 1, color: borderColor),
                      Flexible(child: _buildMiniRating('${receta.promedioCalificacion.toStringAsFixed(1)}')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 0.5),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textColor),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMiniRating(String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RATING',
          style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 0.5),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 2),
            const Icon(Icons.star, color: AppTheme.primary, size: 9),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(
      String label, {
        required bool selected,
        required bool enabled,
        VoidCallback? onTap,
      }) {
    final Color bg = selected ? AppTheme.primary.withValues(alpha: 0.15) : surfaceColor;
    final Color border = selected ? AppTheme.primary : borderColor;
    final Color fg = !enabled
        ? mutedColor.withValues(alpha: 0.4)
        : (selected ? AppTheme.primary : mutedColor);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}