import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:flutter_module/screens/Profile.dart';
import '../theme/Notifier.dart';
import '../theme/App.dart';
import '../widgets/Common.dart';
import '../models/RecetaFeed.dart';
import '../services/Receta.dart';
import '../services/Instructions.dart';
import '../services/Update.dart';
import '../widgets/UpdateDialog.dart';
import '../route_observer.dart';
import 'DetailRecipe.dart';
import 'BarraNavegacion.dart';
import 'package:share_plus/share_plus.dart';

import 'EditRecipe.dart';



class FeedScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final usuario_Logged user;

  const FeedScreen({
    super.key,
    required this.themeNotifier,
    required this.user,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<RecetaFeed> recipesFeed = [];
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 10;

  late final String _seed;
  int _offset = 0;
  bool _estaCargando = true;
  bool _cargandoMas = false;
  bool _hayMas = true;
  static const bool _isDebugMode = false;

  @override
  void initState() {
    super.initState();
    _seed = DateTime.now().millisecondsSinceEpoch.toString();
    _scrollController.addListener(_onScroll);
    _traerRecetas();
    WidgetsBinding.instance.addPostFrameCallback((_) => _chequearActualizacion());
  }

  Future<void> _chequearActualizacion() async {
    final info = await UpdateService.verificar();
    if (info == null || !info.disponible || !mounted) return;
    setState(() {});
    final yaVisto = await UpdateService.avisoYaVisto(info.versionName);
    if (yaVisto || !mounted) return;
    await UpdateService.marcarAvisoVisto(info.versionName);
    if (!mounted) return;
    await mostrarAvisoActualizacion(context, info.versionName);
  }

  void _volverAlInicio() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _traerMas();
    }
  }

  Future<void> _traerRecetas() async {
    try {
      final lista = await RecetaService.getRecetas(
        seed: _seed,
        limit: _pageSize,
        offset: 0,
        viewerId: widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        recipesFeed
          ..clear()
          ..addAll(lista);
        _offset = lista.length;
        _hayMas = lista.length == _pageSize;
        _estaCargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  Future<void> _traerMas() async {
    if (_cargandoMas || !_hayMas) return;
    setState(() => _cargandoMas = true);
    try {
      final lista = await RecetaService.getRecetas(
        seed: _seed,
        limit: _pageSize,
        offset: _offset,
        viewerId: widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        recipesFeed.addAll(lista);
        _offset += lista.length;
        _hayMas = lista.length == _pageSize;
        _cargandoMas = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      endDrawer: SharedDrawer(
        user: widget.user,
        themeNotifier: widget.themeNotifier,
        rutaActual: 'inicio',
      ),
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: GestureDetector(
          onTap: _volverAlInicio,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(BocadoRadius.sm),
                ),
                child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text('Bocado',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  )),
            ],
          ),
        ),
        actions: [
          if (_isDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.blue),
              onPressed: () async {
                try {
                  final recetaData = await RecetaService.getRecetaParaEditar(32);

                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeEditorScreen(
                          themeNotifier: widget.themeNotifier,
                          user: widget.user,
                          recetaExistente: recetaData,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ThemeToggleButton(themeNotifier: widget.themeNotifier),
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openEndDrawer(),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  backgroundImage: bocadoImageProvider(
                      widget.user.fotoUrl ?? 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'
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
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: recipesFeed.length + (_hayMas ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= recipesFeed.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final recetaActual = recipesFeed[index];

                return GestureDetector(
                  onTap: () {
                    pushOrReuse(
                      context,
                      'receta/${recetaActual.idReceta}',
                      (context) => RecipeDetailScreen(
                        themeNotifier: widget.themeNotifier,
                        user: widget.user,
                        idReceta: recetaActual.idReceta,
                        protFeed: recetaActual.proteinasTotales,
                        carbFeed: recetaActual.carbohidratosTotales,
                        grasFeed: recetaActual.grasasTotales,
                        idAutor: recetaActual.usuarioTarget,
                        isLikedInicial: recetaActual.isLikedBy(widget.user.id),
                      ),
                    );
                  },
                  child: _FeedArticleCard(
                  receta: recetaActual,
                  user: widget.user,
                  themeNotifier: widget.themeNotifier,
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

class _FeedArticleCard extends StatefulWidget {
  final RecetaFeed receta;
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;

  const _FeedArticleCard({
    required this.receta,
    required this.user,
    required this.themeNotifier,
  });

  @override
  State<_FeedArticleCard> createState() => _FeedArticleCardState();
}

class _FeedArticleCardState extends State<_FeedArticleCard> with RouteAware {
  late bool _isLiked;
  late bool _isSaved;
  late int _likesLocales;
  late int _comentariosLocales;
  bool _eliminada = false;

  @override
  void initState(){
    super.initState();
    _isLiked=widget.receta.isLikedBy(widget.user.id);
    _isSaved=widget.receta.isSavedBy(widget.user.id);
    _likesLocales = widget.receta.cantidadFavoritos;
    _comentariosLocales = widget.receta.cantidadComentarios;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _resincronizarInteracciones();
    _resincronizarComentarios();
  }

  Future<void> _resincronizarInteracciones() async {
    try {
      final tipos = await InteraccionesService.fetchMisInteracciones(
        widget.user.id,
        widget.receta.idReceta,
      );
      if (!mounted) return;
      final nuevoLike = tipos.contains('like');
      final nuevoSave = tipos.contains('save');
      if (nuevoLike == _isLiked && nuevoSave == _isSaved) return;
      setState(() {
        if (nuevoLike != _isLiked) {
          _likesLocales += nuevoLike ? 1 : -1;
          _isLiked = nuevoLike;
        }
        _isSaved = nuevoSave;
      });
    } catch (_) {
    }
  }

  Future<void> _resincronizarComentarios() async {
    try {
      final jsonString = await InteraccionesService.fetchComentarios(
        widget.receta.idReceta,
      );
      final List<dynamic> lista = jsonDecode(jsonString);
      if (!mounted || lista.length == _comentariosLocales) return;
      setState(() => _comentariosLocales = lista.length);
    } catch (_) {
    }
  }

  Future<void> _handleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _isLiked ? _likesLocales++ : _likesLocales--;
    });

    try{
      await InteraccionesService.toggleInteraction({
        'id_usuario': widget.user.id,
        'id_receta': widget.receta.idReceta,
        'tipo': 'like',
        'is_adding': _isLiked,
      });
    } catch(e){
      if(mounted){
        setState(() {
          _isLiked = !_isLiked;
          _isLiked ? _likesLocales++ : _likesLocales--;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar el Like. Revisa tu conexión.')));
      }
    }
  }
  Future<void> _handleSave() async{
    setState(()=> _isSaved = !_isSaved);

    try{
      await InteraccionesService.toggleInteraction({
        'id_usuario': widget.user.id,
        'id_receta': widget.receta.idReceta,
        'tipo': 'save',
        'is_adding': _isSaved,
      });
    } catch(e){
      if(mounted){
        setState(()=> _isSaved = !_isSaved);
        final esLimite = e is PlatformException && e.code == 'LIMITE_ALCANZADO';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(esLimite
              ? 'Llegaste al límite de 10 guardados. Hazte Premium para guardar sin límite.'
              : 'Error al guardar la receta. Revisa tu conexión.'),
        ));
      }
    }
  }
  void _handleShare() {
    final String textoCompartir =
        '¡Mirá esta receta de ${widget.receta.nombre} en Bocado! 👨‍🍳\n\n'
        'Rinde ${widget.receta.porciones} porciones y tiene ${widget.receta.caloriasTotales.toInt()} calorías.\n'
        '¡Descargá la app para ver los ingredientes y prepararla!';
    SharePlus.instance.share(ShareParams(text: textoCompartir));
  }

  @override
  Widget build(BuildContext context) {
    if (_eliminada) return const SizedBox.shrink();
    final c = BocadoColors.of(context);
    final String fotoRaw = widget.receta.foto ?? '';
    final String fotoUrl = fotoRaw.isNotEmpty ? fotoRaw.split('|')[0] : '';
    final Widget imageHeader = GestureDetector(
      onLongPress: fotoUrl.startsWith('http')
          ? () => showFullscreenImage(context, url: fotoUrl)
          : null,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: BocadoNetworkImage(
          url: fotoUrl.startsWith('http')
              ? fotoUrl
              : 'https://images.unsplash.com/photo-1485921325833-c519f76c4927?q=80&w=600&auto=format&fit=crop',
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(BocadoRadius.lg),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              imageHeader,
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(BocadoRadius.sm),
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
                          borderRadius: BorderRadius.circular(BocadoRadius.sm),
                        ),
                        child: Text(
                            widget.receta.etiquetas.first,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      ),
                  ],
                ),
              ),

              if (widget.receta.usuarioTarget == widget.user.id)
                Positioned(
                  top: 12,
                  right: 12,
                  child: bocadoDeleteBadge(
                    onTap: () async {
                      final ok = await mostrarDialogoEliminarReceta(
                        context,
                        idReceta: widget.receta.idReceta,
                        idUsuario: widget.user.id,
                      );
                      if (ok && mounted) setState(() => _eliminada = true);
                    },
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pushOrReuse(context, 'perfil/${widget.receta.usuarioTarget}', (_) => ProfileScreen(user: widget.user, themeNotifier: widget.themeNotifier, idUsuarioTarget: widget.receta.usuarioTarget));
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: bocadoImageProvider(
                            widget.receta.fotoUsuario ?? 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(BocadoRadius.md),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNutriCol('CALORÍAS', '${widget.receta.caloriasTotales.toInt()}', c.muted),
                      _buildDivider(c.border),
                      _buildNutriCol('PROTEÍNAS', '${widget.receta.proteinasTotales}g', c.muted, valueColor: AppTheme.primary),
                      _buildDivider(c.border),
                      _buildNutriCol('CARBOS', '${widget.receta.carbohidratosTotales}g', c.muted),
                      _buildDivider(c.border),
                      _buildNutriCol('GRASAS', '${widget.receta.grasasTotales}g', c.muted),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildActionButton(
                          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                          label: '$_likesLocales',
                          color: _isLiked ? AppTheme.primary : c.muted,
                          onTap: _handleLike,
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: '$_comentariosLocales',
                          color: c.muted,
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Compartir',
                          color: c.muted,
                          onTap: _handleShare,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _handleSave,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isSaved ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(BocadoRadius.sm),
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