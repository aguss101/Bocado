import 'package:flutter/material.dart';
import 'package:flutter_module/models/UserProfile.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:flutter_module/services/Receta.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/IdCodec.dart';
import '../theme/Notifier.dart';
import '../theme/App.dart';
import '../theme/ColorblindNotifier.dart';
import '../widgets/Common.dart';
import 'BarraNavegacion.dart';
import 'EditProfile.dart';
import '../services/Usuario.dart';
import '../services/Instructions.dart';
import '../models/RecetaFeed.dart';
import '../utils/PagedList.dart';
import '../screens/EditRecipe.dart';
import '../screens/DetailRecipe.dart';
import '../route_observer.dart';
import 'FollowList.dart';

class ProfileScreen extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;
  final int? idUsuarioTarget;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.themeNotifier,
    this.idUsuarioTarget,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  BocadoColors get _c => BocadoColors.of(context);
  late TabController _tabController;
  late usuario_Logged _user;
  late bool _isMiPerfil;
  bool _estaCargandoPerfil = false;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  int _cantRecetas = 0;
  int _cantSeguidores = 0;
  int _cantSiguiendo = 0;
  bool _estaCargandoStats = true;

  static const int _pageGrid = 12;
  late PagedList<RecetaFeed> _plRecetas;
  PagedList<RecetaFeed>? _plGuardados;

  @override
  void initState() {
    super.initState();
    _isMiPerfil =
        widget.idUsuarioTarget == null ||
            widget.idUsuarioTarget == widget.user.id;

    _tabController = TabController(length: _isMiPerfil ? 2 : 1, vsync: this);

    final idTarget = widget.idUsuarioTarget ?? widget.user.id;
    _user = widget.user;
    if (_isMiPerfil) {
      _cargarPerfilPropio(widget.user.id);
    } else {
      _cargarPerfilTercero(widget.idUsuarioTarget!);
    }

    _plRecetas = PagedList(
      _isMiPerfil
          ? (off, lim) => RecetaService.getMisRecetas(idTarget)
          : (off, lim) => RecetaService.getRecetasUsuario(idTarget, limit: lim, offset: off),
      pageSize: _pageGrid,
    );
    _cargarPrimera(_plRecetas);

    if (_isMiPerfil) {
      _plGuardados = PagedList(
            (off, lim) => RecetaService.getGuardadosUsuario(widget.user.id, limit: lim, offset: off),
        pageSize: _pageGrid,
      );
      _cargarPrimera(_plGuardados!);
    }

    _cargarStats(idTarget);
    if (!_isMiPerfil) _cargarEstadoSeguimiento(widget.idUsuarioTarget!);
  }

  Future<void> _cargarPerfilTercero(int idTarget) async {
    setState(() => _estaCargandoPerfil = true);
    try {
      final usuarioTercero = await UsuarioService.getPerfilUsuario(idTarget);
      if (mounted) {
        setState(() {
          _user = usuarioTercero;

          if (usuarioTercero.id == widget.user.id && !_isMiPerfil) {
            _isMiPerfil = true;
            _tabController.dispose();
            _tabController = TabController(length: 2, vsync: this);
            _plGuardados = PagedList(
                  (off, lim) => RecetaService.getGuardadosUsuario(widget.user.id, limit: lim, offset: off),
              pageSize: _pageGrid,
            );
            _cargarPrimera(_plGuardados!);

            _plRecetas = PagedList(
                  (off, lim) => RecetaService.getMisRecetas(widget.user.id),
              pageSize: _pageGrid,
            );
            _cargarPrimera(_plRecetas);
          }
          _estaCargandoPerfil = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _estaCargandoPerfil = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar el perfil')),
        );
      }
    }
  }

  Future<void> _cargarPerfilPropio(int idUsuario) async {
    setState(() => _estaCargandoPerfil = true);
    try {
      final usuarioActualizado = await UsuarioService.getPerfilUsuario(idUsuario);
      if (mounted) {
        setState(() {
          _user = usuarioActualizado;
          _estaCargandoPerfil = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _estaCargandoPerfil = false);
    }
  }

  Future<void> _cargarStats(int idUsuario) async {
    try {
      final results = await Future.wait([
        RecetaService.contarRecetas(idUsuario),
        UsuarioService.contarSeguidores(idUsuario),
        UsuarioService.contarSiguiendo(idUsuario),
      ]);
      if (mounted) {
        setState(() {
          _cantRecetas = results[0];
          _cantSeguidores = results[1];
          _cantSiguiendo = results[2];
          _estaCargandoStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _estaCargandoStats = false);
    }
  }

  Future<void> _cargarEstadoSeguimiento(int idTarget) async {
    try {
      final siguiendo = await UsuarioService.estasSiguiendo(
        widget.user.id,
        idTarget,
      );
      if (mounted) setState(() => _isFollowing = siguiendo);
    } catch (_) {}
  }

  Future<void> _toggleSeguir() async {
    if (_isLoadingFollow) return;

    final siguiendoActual = _isFollowing;

    setState(() {
      _isLoadingFollow = true;
    });

    try {
      await InteraccionesService.actualizarSeguido({
        'id_seguidor': widget.user.id,
        'id_seguido': widget.idUsuarioTarget,
        'siguiendo': siguiendoActual,
      });
      if (mounted) {
        setState(() {
          _isFollowing = !siguiendoActual;
          _isLoadingFollow = false;
          _cantSeguidores += siguiendoActual ? -1 : 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFollow = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el estado. Revisa tu conexión.'),
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    _cargarStats(widget.idUsuarioTarget ?? widget.user.id);
    if (!_isMiPerfil) _cargarEstadoSeguimiento(widget.idUsuarioTarget!);
    if (_isMiPerfil) {
      _refrescarMisRecetas();
      _refrescarGuardados();
    }
  }

  Future<void> _refrescarMisRecetas() async {
    if (!_isMiPerfil) return;
    try {
      final lista = await RecetaService.getMisRecetas(widget.user.id);
      if (!mounted) return;
      setState(() {
        _plRecetas.items
          ..clear()
          ..addAll(lista);
        _plRecetas.hayMas = false;
        _plRecetas.cargando = false;
      });
    } catch (_) {}
  }

  Future<void> _refrescarGuardados() async {
    final pl = _plGuardados;
    if (pl == null) return;
    await pl.cargarPrimera();
    if (mounted) setState(() {});
  }

  void _onRecetaEliminada() {
    if (!mounted) return;
    if (_isMiPerfil) {
      _refrescarMisRecetas();
      _refrescarGuardados();
    } else {
      _cargarPrimera(_plRecetas);
    }
    _cargarStats(widget.idUsuarioTarget ?? widget.user.id);
  }

  Future<void> _cargarPrimera(PagedList pl) async {
    await pl.cargarPrimera();
    if (mounted) setState(() {});
  }

  Future<void> _cargarMas(PagedList pl) async {
    if (pl.cargando || pl.cargandoMas || !pl.hayMas) return;
    await pl.cargarMas();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _c.isDark;
    final bg = _c.bg;
    final surface = _c.surface;
    final border = _c.border;
    final text = _c.text;
    final muted = _c.muted;

    return Scaffold(
      backgroundColor: bg,
      endDrawer: SharedDrawer(
        user: widget.user,
        themeNotifier: widget.themeNotifier,
        rutaActual: 'perfil',
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Perfil',
          style: TextStyle(color: text, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          ThemeToggleButton(themeNotifier: widget.themeNotifier),
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, color: _c.primary),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _estaCargandoPerfil
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(isDark),
                _buildProfileInfo(surface, border, text, muted, context),
                _buildStats(surface, border, text, muted),
                _buildBioCard(surface, border, text, muted),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: _c.primary,
                indicatorWeight: 2,
                labelColor: _c.primary,
                unselectedLabelColor: muted,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                isScrollable: false,
                tabs: _isMiPerfil
                    ? const [
                  Tab(text: 'Recetas Publicadas'),
                  Tab(text: 'Guardados'),
                ]
                    : const [
                  Tab(text: 'Recetas Publicadas'),
                ],
              ),
              color: bg,
              border: border,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: _isMiPerfil
              ? [
            _buildRecetasTab(surface, border, text, muted),
            _buildGuardadosTab(surface, border, text, muted),
          ]
              : [
            _buildRecetasTab(surface, border, text, muted),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(bool isDark) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _user.bannerUrl != null
              ? BocadoNetworkImage(url: _user.bannerUrl!)
              : _user.bannerReady != null
              ? Image.memory(_user.bannerReady!, fit: BoxFit.cover)
              : Container(
            color: cvdNeutral(
              isDark ? const Color(0xFF1A1108) : const Color(0xFFF5E0C8),
              ColorblindScope.of(context).value,
            ),
            child: Center(
              child: Icon(
                Icons.restaurant_menu,
                size: 48,
                color: _c.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(
      Color surface,
      Color border,
      Color text,
      Color muted,
      BuildContext context,
      ) {
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -40),
                child: _buildAvatar(),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    _isMiPerfil
                        ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _c.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(
                              user: _user,
                              themeNotifier: widget.themeNotifier,
                              onSaved: (updated) {
                                setState(() => _user = updated);
                              },
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Editar Perfil',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    )
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Color.lerp(_c.primary, Colors.black, 0.30)
                            : _c.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoadingFollow ? null : _toggleSeguir,
                      child: _isLoadingFollow
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        _isFollowing ? 'Siguiendo' : 'Seguir',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.share_outlined, color: muted),
                        onPressed: () {
                          final username = _user.usuario;
                          final idPerfil = widget.idUsuarioTarget ?? widget.user.id;
                          final slug = IdCodec.encodePerfil(idPerfil);
                          SharePlus.instance.share(
                            ShareParams(
                              text: '¡Mirá el perfil de $username en Bocado! 👨‍🍳\n'
                                  'https://links.bocado.tech/perfil/$slug',
                            ),
                          );
                        },
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),


          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  _user.usuario,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_user.id_Cuenta == 2) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.star,
                  color: BocadoColors.of(context).premium,
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '@${_user.usuario.toLowerCase().replaceAll(' ', '_')}',
            style: TextStyle(color: muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return BocadoAvatar(
      fotoUrl: _user.fotoUrl,
      fotoBytes: _user.fotoReady,
      initial: _user.usuario.isNotEmpty ? _user.usuario[0].toUpperCase() : '?',
      size: 88,
      radius: 20,
      initialFontSize: 36,
    );
  }

  void _abrirSeguidoresOSiguiendo({required bool enSeguidores}) {
    final puedeVer = _isMiPerfil || _user.visibilidad || _isFollowing;
    if (!puedeVer) return;
    final idTarget = widget.idUsuarioTarget ?? widget.user.id;
    mostrarSeguidoresDialog(
      context,
      user: widget.user,
      themeNotifier: widget.themeNotifier,
      idPerfil: idTarget,
      abrirEnSeguidores: enSeguidores,
    );
  }

  Widget _buildStats(Color surface, Color border, Color text, Color muted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(
            _estaCargandoStats ? '—' : '$_cantRecetas',
            'Recetas',
            text,
            muted,
          ),
          _dividerV(border),
          GestureDetector(
            onTap: () => _abrirSeguidoresOSiguiendo(enSeguidores: true),
            child: _statItem(
              _estaCargandoStats ? '—' : '$_cantSeguidores',
              'Seguidores',
              text,
              muted,
            ),
          ),
          _dividerV(border),
          GestureDetector(
            onTap: () => _abrirSeguidoresOSiguiendo(enSeguidores: false),
            child: _statItem(
              _estaCargandoStats ? '—' : '$_cantSiguiendo',
              'Siguiendo',
              text,
              muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String count, String label, Color text, Color muted) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: muted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _dividerV(Color border) =>
      Container(height: 36, width: 1, color: border);

  Widget _buildBioCard(Color surface, Color border, Color text, Color muted) {
    final String bioText = (_user.bio == 'null') ? "Sin biografía" : _user.bio!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _c.primary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            bioText,
            style: TextStyle(fontSize: 13, color: muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRecetasTab(
      Color surface,
      Color border,
      Color text,
      Color muted,
      ) {
    final pl = _plRecetas;
    if (pl.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    print("valido que llego hasta aca!!");
    for (var receta in pl.items) {
      print('Receta: ${receta.nombre} | Activa: ${receta.activo} | Autor: ${receta.usuarioTarget}');
    }

    if (_isMiPerfil) {
      final publicadas = pl.items.where((r) => r.activo).toList();
      return _gridRecetasSimple(
        items: publicadas,
        conCrear: true,
        surface: surface,
        border: border,
        text: text,
        muted: muted,
      );
    }
    if (pl.items.isEmpty) {
      return _buildPlaceholderTab(
        'restaurant',
        'No hay recetas publicadas',
        muted,
      );
    }
    return _gridRecetasPaginado(
      pl: pl,
      conCrear: false,
      surface: surface,
      border: border,
      text: text,
      muted: muted,
    );
  }

  Widget _buildGuardadosTab(
      Color surface,
      Color border,
      Color text,
      Color muted,
      ) {
    final pl = _plGuardados;
    if (pl == null || pl.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (pl.items.isEmpty) {
      return _buildPlaceholderTab(
        'favorite_border',
        'No hay recetas guardadas',
        muted,
      );
    }
    return _gridRecetasPaginado(
      pl: pl,
      conCrear: false,
      surface: surface,
      border: border,
      text: text,
      muted: muted,
    );
  }

  Widget _gridRecetasPaginado({
    required PagedList<RecetaFeed> pl,
    required bool conCrear,
    required Color surface,
    required Color border,
    required Color text,
    required Color muted,
  }) {
    final extraInicio = conCrear ? 1 : 0;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) _cargarMas(pl);
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: extraInicio + pl.items.length + (pl.hayMas ? 1 : 0),
        itemBuilder: (context, index) {
          if (conCrear && index == 0) {
            return _tarjetaCrearReceta(context, border, muted);
          }
          final i = index - extraInicio;
          if (i >= pl.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return _recipeCard(
            surface: surface,
            border: border,
            text: text,
            muted: muted,
            receta: pl.items[i],
            context: context,
            themeNotifier: widget.themeNotifier,
            user: widget.user,
            onEliminada: _onRecetaEliminada,
          );
        },
      ),
    );
  }

  Widget _gridRecetasSimple({
    required List<RecetaFeed> items,
    required bool conCrear,
    required Color surface,
    required Color border,
    required Color text,
    required Color muted,
  }) {
    final extraInicio = conCrear ? 1 : 0;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: extraInicio + items.length,
      itemBuilder: (context, index) {
        if (conCrear && index == 0) {
          return _tarjetaCrearReceta(context, border, muted);
        }
        return _recipeCard(
          surface: surface,
          border: border,
          text: text,
          muted: muted,
          receta: items[index - extraInicio],
          context: context,
          themeNotifier: widget.themeNotifier,
          user: widget.user,
          onEliminada: _onRecetaEliminada,
        );
      },
    );
  }

  Widget _tarjetaCrearReceta(BuildContext context, Color border, Color muted) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeEditorScreen(
              themeNotifier: widget.themeNotifier,
              user: widget.user,
            ),
          ),
        );
        if (mounted) _refrescarMisRecetas();
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: border, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _c.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: _c.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              'Crear Receta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _recipeCard({
  required Color surface,
  required Color border,
  required Color text,
  required Color muted,
  required RecetaFeed receta,
  required BuildContext context,
  required ThemeNotifier themeNotifier,
  required usuario_Logged user,
  VoidCallback? onEliminada,
}) {
  final c = BocadoColors.of(context);
  final stringEtiqueta = receta.etiquetas.isNotEmpty
      ? receta.etiquetas.first
      : 'Receta';

  return GestureDetector(
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
    child: Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                (receta.foto != null && receta.foto!.isNotEmpty)
                    ? GestureDetector(
                  onLongPress: () => showFullscreenImage(
                    context,
                    url: receta.foto!.split('|')[0],
                  ),
                  child: BocadoNetworkImage(
                    url: receta.foto!.split('|')[0],
                    memCacheWidth: 600,
                  ),
                )
                    : Container(
                  color: c.primary.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.restaurant,
                    size: 40,
                    color: c.primary.withValues(alpha: 0.3),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${receta.caloriasTotales.toInt()} kcal',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (receta.usuarioTarget == user.id)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: bocadoDeleteBadge(
                      onTap: () async {
                        final ok = await mostrarDialogoEliminarReceta(
                          context,
                          idReceta: receta.idReceta,
                          idUsuario: user.id,
                        );
                        if (ok) onEliminada?.call();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receta.nombre,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: c.rating,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          receta.promedioCalificacion.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        stringEtiqueta,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: muted,
                          letterSpacing: 0.3,
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
    ),
  );
}

Widget _buildPlaceholderTab(String iconName, String msg, Color muted) {
  final icons = {
    'favorite_border': Icons.favorite_border,
    'draft': Icons.drafts_outlined,
  };
  return BocadoEmptyState(
    icon: icons[iconName] ?? Icons.inbox_outlined,
    message: msg,
  );
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  final Color border;

  const _StickyTabBarDelegate(
      this.tabBar, {
        required this.color,
        required this.border,
      });

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: color,
      child: Column(
        children: [
          tabBar,
          Divider(height: 1, thickness: 1, color: border),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar ||
          oldDelegate.color != color ||
          oldDelegate.border != border;
}

