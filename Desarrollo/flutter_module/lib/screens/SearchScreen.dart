import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_module/services/Usuario.dart';
import '../models/UsuarioBusqueda.dart';
import '../route_observer.dart';
import '../theme/Notifier.dart';
import '../theme/App.dart';
import '../models/UsuarioLogged.dart';
import '../models/RecetaFeed.dart';
import '../widgets/Common.dart';
import '../services/Receta.dart';
import 'DetailRecipe.dart';
import 'Profile.dart';

class SearchScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final usuario_Logged user;

  const SearchScreen({
    super.key,
    required this.themeNotifier,
    required this.user,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _estaCargando = false;
  String _query = '';
  List<RecetaFeed> _resultadosRecetas = [];
  List<UsuarioBusqueda> _resultadosPerfiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() {
      _query = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _resultadosRecetas.clear();
        _resultadosPerfiles.clear();
        _estaCargando = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _realizarBusqueda(query);
    });
  }

  Future<void> _realizarBusqueda(String query) async {
    setState(() => _estaCargando = true);

    try {
      final resultados = await Future.wait([
        RecetaService.buscarRecetas(query),
        UsuarioService.buscarUsuarios(query),
      ]);

      if (!mounted) return;
      setState(() {
        _resultadosRecetas = resultados[0] as List<RecetaFeed>;
        _resultadosPerfiles = resultados[1] as List<UsuarioBusqueda>;
        _estaCargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _estaCargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al realizar la búsqueda: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: c.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Buscar',
            style: TextStyle(color: c.text, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(BocadoRadius.full),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: c.text),
                  decoration: InputDecoration(
                    hintText: 'Buscar recetas, ingredientes...',
                    hintStyle: TextStyle(color: c.muted),
                    prefixIcon: Icon(Icons.search, color: c.muted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: c.muted),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                ),
              ),
            ),
            TabBar(
              indicatorColor: c.primary,
              labelColor: c.primary,
              unselectedLabelColor: c.muted,
              tabs: const [
                Tab(text: 'Recetas'),
                Tab(text: 'Perfiles'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_buildContentRecetas(c), _buildContentPerfiles(c)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentRecetas(dynamic c) {
    if (_estaCargando) return const Center(child: CircularProgressIndicator());

    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 60, color: c.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Buscá recetas, etiquetas o ingredientes',
              style: TextStyle(color: c.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_resultadosRecetas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: c.muted),
            const SizedBox(height: 16),
            Text(
              'No encontramos recetas para "$_query"',
              style: TextStyle(color: c.text, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _resultadosRecetas.length,
      itemBuilder: (context, index) {
        final receta = _resultadosRecetas[index];
        return _ResultCard(
          receta: receta,
          c: c,
          themeNotifier: widget.themeNotifier,
          user: widget.user,
        );
      },
    );
  }

  Widget _buildContentPerfiles(dynamic c) {
    if (_estaCargando) return const Center(child: CircularProgressIndicator());

    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 60,
              color: c.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Buscá a otros cocineros de la comunidad',
              style: TextStyle(color: c.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_resultadosPerfiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 60, color: c.muted),
            const SizedBox(height: 16),
            Text(
              'No se encontraron usuarios',
              style: TextStyle(color: c.text, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _resultadosPerfiles.length,
      itemBuilder: (context, index) {
        final usuario = _resultadosPerfiles[index];
        final String fotoUrl = usuario.foto ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: c.primary.withValues(alpha: 0.2),
            backgroundImage: bocadoImageProvider(
              fotoUrl.isNotEmpty
                  ? fotoUrl
                  : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
            ),
          ),
          title: Text(
            usuario.usuario,
            style: TextStyle(color: c.text, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            pushOrReuse(
              context,
              'perfil/${usuario.id}',
              (context) => ProfileScreen(
                user: widget.user,
                themeNotifier: widget.themeNotifier,
                idUsuarioTarget: usuario.id,
              ),
            );
          },
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final RecetaFeed receta;
  final dynamic c;
  final ThemeNotifier themeNotifier;
  final usuario_Logged user;

  const _ResultCard({
    required this.receta,
    required this.c,
    required this.themeNotifier,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final String fotoUrl = receta.foto?.split('|')[0] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: fotoUrl.isNotEmpty
              ? Image.network(fotoUrl, width: 60, height: 60, fit: BoxFit.cover)
              : Container(width: 60, height: 60, color: Colors.grey[300]),
        ),
        title: Text(
          receta.nombre,
          style: TextStyle(color: c.text, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              if (receta.promedioCalificacion > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.rating.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        receta.promedioCalificacion.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  '${receta.caloriasTotales.toInt()} kcal • ${receta.proteinasTotales}g prot',
                  style: TextStyle(color: c.muted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          pushOrReuse(
            context,
            'receta/${receta.idReceta}',
            (context) => RecipeDetailScreen(
              themeNotifier: themeNotifier,
              user: user,
              idReceta: receta.idReceta,
              protFeed: receta.proteinasTotales,
              carbFeed: receta.carbohidratosTotales,
              grasFeed: receta.grasasTotales,
              idAutor: receta.usuarioTarget,
              isLikedInicial: receta.isLikedBy(user.id),
            ),
          );
        },
      ),
    );
  }
}
