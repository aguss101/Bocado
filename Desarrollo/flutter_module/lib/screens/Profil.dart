import 'package:flutter/material.dart';
import 'package:flutter_module/models/UserProfile.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:flutter_module/services/Receta.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/Notifier.dart';
import '../theme/App.dart';
import 'BarraNavegacion.dart';
import 'EditProfil.dart';
import '../services/Usuario.dart';
import '../services/Instructions.dart';
import '../models/RecetaFeed.dart';
import '../screens/EditRecipe.dart';
import '../screens/DetailRecipe.dart';
import '../route_observer.dart';

class ProfileScreen extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;
  final int? idUsuarioTarget;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.themeNotifier,
    this.idUsuarioTarget
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin, RouteAware {
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

  Future<List<RecetaFeed>>? _futureRecetas;
  Future<List<RecetaFeed>>? _futureGuardados;
  Future<List<UserProfile>>? _futureSeguidos;

  @override
  void initState() {
    super.initState();
    _isMiPerfil = widget.idUsuarioTarget == null || widget.idUsuarioTarget == widget.user.id;
    _tabController = TabController(length: _isMiPerfil ? 4 : 2, vsync: this);
    final idTarget = widget.idUsuarioTarget ?? widget.user.id;
    if (_isMiPerfil) {
      _user = widget.user;
    } else {
      _user = widget.user;
      _cargarPerfilTercero(widget.idUsuarioTarget!);
    }
    _futureRecetas  = RecetaService.getRecetasUsuario(idTarget);
    _futureSeguidos = UsuarioService.getSeguidores(idTarget);
    if (_isMiPerfil) {
      _futureGuardados = RecetaService.getGuardadosUsuario(widget.user.id);
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
          // Red de seguridad: si el "tercero" es en realidad el usuario logueado,
          // tratarlo como perfil propio (oculta Seguir, restaura los 4 tabs).
          if (usuarioTercero.id == widget.user.id && !_isMiPerfil) {
            _isMiPerfil = true;
            _tabController.dispose();
            _tabController = TabController(length: 4, vsync: this);
            _futureGuardados = RecetaService.getGuardadosUsuario(widget.user.id);
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

  Future<void> _cargarStats(int idUsuario) async {
    try {
      final results = await Future.wait([
        RecetaService.contarRecetas(idUsuario),
        UsuarioService.contarSeguidores(idUsuario),
        UsuarioService.contarSiguiendo(idUsuario),
      ]);
      if (mounted) {
        setState(() {
          _cantRecetas   = results[0];
          _cantSeguidores = results[1];
          _cantSiguiendo  = results[2];
          _estaCargandoStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _estaCargandoStats = false);
    }
  }

  Future<void> _cargarEstadoSeguimiento(int idTarget) async {
    try {
      final siguiendo = await UsuarioService.estasSiguiendo(widget.user.id, idTarget);
      if (mounted) setState(() => _isFollowing = siguiendo);
    } catch (_) {}
  }

  Future <void> _toggleSeguir() async{
    if(_isLoadingFollow) return;

    final siguiendoActual = _isFollowing;

    setState(() {
      _isLoadingFollow = true;
    });

    try{
      await InteraccionesService.actualizarSeguido({
        'id_seguidor': widget.user.id,
        'id_seguido': widget.idUsuarioTarget,
        'siguiendo': siguiendoActual
      });
      if(mounted) {
        setState(() {
          _isFollowing = !siguiendoActual;
          _isLoadingFollow = false;
          _cantSeguidores += siguiendoActual ? -1 : 1;
        });
      }
    } catch (e){
      if(mounted){
        setState(() {
          _isLoadingFollow = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el estado. Revisa tu conexión.')),
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

  /// Se dispara al volver a esta pantalla desde otra (pop). Refresca contadores
  /// para reflejar follows/unfollows hechos en otras pantallas.
  @override
  void didPopNext() {
    _cargarStats(widget.idUsuarioTarget ?? widget.user.id);
    if (!_isMiPerfil) _cargarEstadoSeguimiento(widget.idUsuarioTarget!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppTheme.bgDark            : AppTheme.surfaceContainerLight;
    final surface = isDark ? AppTheme.surfaceDark        : AppTheme.surfaceLight;
    final border  = isDark ? AppTheme.outlineDark        : AppTheme.outlineLight;
    final text    = isDark ? AppTheme.onSurfaceDark      : AppTheme.onSurfaceLight;
    final muted   = isDark ? AppTheme.secondaryDark      : AppTheme.secondaryLight;

    return Scaffold(
      backgroundColor: bg,
      endDrawer: SharedDrawer(
        user: _user,
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
          // ── Toggle de tema ──
          ValueListenableBuilder<ThemeMode>(
            valueListenable: widget.themeNotifier,
            builder: (_, mode, __) => IconButton(
              icon: Icon(
                mode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: AppTheme.primary,
              ),
              onPressed: widget.themeNotifier.toggle,
            ),
          ),
          // ── Abrir drawer ──
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.primary),
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
                // ── PORTADA ──
                _buildCover(isDark),

                // ── DATOS DEL USUARIO ──
                _buildProfileInfo(surface, border, text, muted, context),

                // ── STATS ──
                _buildStats(surface, border, text, muted),

                // ── BIO + ESPECIALIDADES ──
                _buildBioCard(surface, border, text, muted),

                const SizedBox(height: 8),
              ],
            ),
          ),
      // ── TAB BAR ──
      SliverPersistentHeader(
        pinned: true,
        delegate: _StickyTabBarDelegate(
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 2,
            labelColor: AppTheme.primary,
            unselectedLabelColor: muted,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _isMiPerfil
                ? const [
                  Tab(text: 'Recetas Publicadas'),
              Tab(text: 'Guardados'),
              Tab(text: 'Borradores'),
              Tab(text: 'Seguidos'),
            ] : const[
              Tab(text: 'Recetas Publicadas'),
              Tab(text: 'Seguidos'),
            ],
          ),
          color: bg,
          border: border,
        ),
      ),
    ],
    body: TabBarView(
    controller: _tabController,
    children: _isMiPerfil? [
    _buildRecetasTab(surface, border, text, muted),
    _buildGuardadosTab(surface, border, text, muted),
    _buildPlaceholderTab('draft', 'Sin borradores', muted),
    _buildSeguidosTab(surface, border, text, muted),
    ]
      : [
        _buildRecetasTab(surface, border, text, muted),
        _buildSeguidosTab(surface, border, text, muted),
      ],
    ),
    ),
    );
  }

  // ── PORTADA ──────────────────────────────────────────────────────────────
  Widget _buildCover(bool isDark) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de banner o color sólido
          _user.bannerUrl != null
              ? Image.network(_user.bannerUrl!, fit: BoxFit.cover)
              : _user.bannerReady != null
                  ? Image.memory(_user.bannerReady!, fit: BoxFit.cover)
                  : Container(
                  color: isDark
                      ? const Color(0xFF1A1108)
                      : const Color(0xFFF5E0C8),
                  child: Center(
                    child: Icon(Icons.restaurant_menu,
                        size: 48,
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                ),
          // Gradiente sutil encima
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

  // ── DATOS DE PERFIL ───────────────────────────────────────────────────────
  Widget _buildProfileInfo(Color surface, Color border, Color text,
      Color muted, BuildContext context) {
    return Container(
      color: surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + botones en fila
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar — sobresale 40px sobre la portada
              Transform.translate(
                offset: const Offset(0, -40),
                child: _buildAvatar(),
              ),
              const Spacer(),
              // Botones alineados al centro del avatar visible
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Editar perfil
                    _isMiPerfil
                        ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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
                      child: const Text('Editar Perfil',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ) : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Color.lerp(AppTheme.primary, Colors.black, 0.30)
                            : AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isLoadingFollow ? null : _toggleSeguir,
                      child: _isLoadingFollow
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isFollowing ? 'Siguiendo' : 'Seguir',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    // Compartir
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
                          SharePlus.instance.share(ShareParams(
                            text: '¡Mirá el perfil de $username en Bocado! 👨‍🍳\n'
                                  'https://links.bocado.tech/perfil/$idPerfil'
                          ));
                        },
                        constraints: const BoxConstraints(
                            minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Nombre y handle (compensar el transform del avatar)
          Transform.translate(
            offset: const Offset(0, -32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user.usuario,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: text),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${_user.usuario.toLowerCase().replaceAll(' ', '_')}',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                // Badge PRO
                if (_user.id_Cuenta == 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined, size: 12, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        const Text('PRO',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.primary.withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: _user.fotoUrl != null
          ? Image.network(_user.fotoUrl!, fit: BoxFit.cover)
          : _user.fotoReady != null
              ? Image.memory(_user.fotoReady!, fit: BoxFit.cover)
              : Center(
                  child: Text(
                    _user.usuario.isNotEmpty
                        ? _user.usuario[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary),
                  ),
                ),
    );
  }

  // ── STATS ─────────────────────────────────────────────────────────────────
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
          _statItem(_estaCargandoStats ? '—' : '$_cantRecetas', 'Recetas', text, muted),
          _dividerV(border),
          _statItem(_estaCargandoStats ? '—' : '$_cantSeguidores', 'Seguidores', text, muted),
          _dividerV(border),
          _statItem(_estaCargandoStats ? '—' : '$_cantSiguiendo', 'Siguiendo', text, muted),
        ],
      ),
    );
  }

  Widget _statItem(String count, String label, Color text, Color muted) {
    return Column(
      children: [
        Text(count,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: text)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: muted,
                letterSpacing: 0.5)),
      ],
    );
  }

  Widget _dividerV(Color border) =>
      Container(height: 36, width: 1, color: border);

  // ── BIO + ESPECIALIDADES ──────────────────────────────────────────────────
  Widget _buildBioCard(Color surface, Color border, Color text, Color muted) {
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
          // Bio
          Text('Bio',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            'Cocinero apasionado por la ciencia detrás de la fermentación. '
            'Compartiendo recetas y técnicas artesanales.',
            style: TextStyle(fontSize: 13, color: muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Divider(color: border),
          const SizedBox(height: 12),
          // Especialidades
          Text('Especialidades',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Panadería', 'Fermentación', 'Gluten Free']
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: border),
                      ),
                      child: Text(tag,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: muted,
                              letterSpacing: 0.5)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
  // ── TAB: GUARDADOS  ──────────────────────────────────────────────────────────
  Widget _buildGuardadosTab(Color surface, Color border, Color text, Color muted){
    return FutureBuilder<List<RecetaFeed>>(
        future: _futureGuardados,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(
                'Error al cargar las recetas', style: TextStyle(color: text)));
          }

          final recetas = snapshot.data ?? [];
          if (recetas.isEmpty) {
            return _buildPlaceholderTab(
                'favorite_border', 'No hay recetas guardadas', muted);
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: recetas.length,
            itemBuilder: (context, index) {

              final receta = recetas[index];

              return _recipeCard(
                surface: surface,
                border: border,
                text: text,
                muted: muted,
                receta: receta,
                context: context,
                themeNotifier: widget.themeNotifier,
                user: widget.user,
              );
            },
          );
        }
    );
  }

  // ── TAB: SEGUIDOS ─────────────────────────────────────────────────────────
  Widget _buildSeguidosTab(
      Color surface, Color border, Color text, Color muted) {

    return FutureBuilder<List<UserProfile>>(
      future: _futureSeguidos,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error al cargar la lista', style: TextStyle(color: text))
          );
        }

        final seguidos = snapshot.data ?? [];
        if (seguidos.isEmpty) {
          return _buildPlaceholderTab('people', 'Aún no sigue a nadie', muted);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: seguidos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _SeguidoCard(
            perfil: seguidos[i],
            usuarioLogueadoId: widget.user.id,
            isMiPerfil: _isMiPerfil,
            surface: surface,
            border: border,
            text: text,
            muted: muted,
          ),
        );
      },
    );
  }

  // ── TAB: RECETAS ──────────────────────────────────────────────────────────
  Widget _buildRecetasTab(
      Color surface, Color border, Color text, Color muted) {
    return FutureBuilder<List<RecetaFeed>>(
      future: _futureRecetas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(
                'Error al cargar las recetas', style: TextStyle(color: text)));
          }

          final recetas = snapshot.data ?? [];
          final itemCount = _isMiPerfil ? recetas.length + 1 : recetas.length;
          if (recetas.isEmpty) {
            return _buildPlaceholderTab(
                'restaurant', 'No hay recetas publicadas', muted);
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (_isMiPerfil && index == recetas.length) {
                return _tarjetaCrearReceta(context, border, muted);
              }

              final receta = recetas[index];

              return _recipeCard(
                surface: surface,
                border: border,
                text: text,
                muted: muted,
                receta: receta,
                context: context,
                themeNotifier: widget.themeNotifier,
                user: widget.user,
              );
            },
          );
        }
          );
        }

  Widget _tarjetaCrearReceta(BuildContext context, Color border, Color muted) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeEditorScreen(
              themeNotifier: widget.themeNotifier,
              user: widget.user,
            ),
          ),
        );
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
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text('Crear Receta',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: muted)),
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
}) {
  final stringEtiqueta = receta.etiquetas.isNotEmpty ? receta.etiquetas.first : 'Receta';

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              themeNotifier: themeNotifier,
              user: user,
              idReceta: receta.idReceta,
              protFeed: receta.proteinasTotales,
              carbFeed: receta.carbohidratosTotales,
              grasFeed: receta.grasasTotales,
            )
        )
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
        // ── IMAGEN DE LA RECETA ──
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── AQUÍ EL CAMBIO ──
              (receta.foto != null && receta.foto!.isNotEmpty)
                  ? Image.network(
                  receta.foto!.split('|')[0],
                  fit: BoxFit.cover
              )
                  : Container(
                color: AppTheme.primary.withValues(alpha: 0.08),
                child: Icon(
                    Icons.restaurant,
                    size: 40,
                    color: AppTheme.primary.withValues(alpha: 0.3)
                ),
              ),

              // ── BADGE SUPERIOR DERECHO (Calorías) ──
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${receta.caloriasTotales.toInt()} kcal',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),

        // ── INFO DE LA RECETA ──
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receta.nombre,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Calificación
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 12, color: AppTheme.primary),
                      const SizedBox(width: 2),
                      Text(receta.promedioCalificacion.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: muted)),
                    ],
                  ),


                  // Etiqueta
                  Expanded(
                    child: Text(stringEtiqueta,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: muted,
                            letterSpacing: 0.3)),
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



  // ── PLACEHOLDER GENÉRICO ──────────────────────────────────────────────────
  Widget _buildPlaceholderTab(String iconName, String msg, Color muted) {
    final icons = {
      'favorite_border': Icons.favorite_border,
      'draft': Icons.drafts_outlined,
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icons[iconName] ?? Icons.inbox_outlined,
              size: 48, color: muted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(msg,
              style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _glassButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

// ── CARD DE SEGUIDO CON BOTÓN SEGUIR/SIGUIENDO ───────────────────────────────
class _SeguidoCard extends StatefulWidget {
  final UserProfile perfil;
  final int usuarioLogueadoId;
  final bool isMiPerfil;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;

  const _SeguidoCard({
    required this.perfil,
    required this.usuarioLogueadoId,
    required this.isMiPerfil,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
  });

  @override
  State<_SeguidoCard> createState() => _SeguidoCardState();
}

class _SeguidoCardState extends State<_SeguidoCard> {
  bool _siguiendo = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isMiPerfil) {
      // Están en mi lista de seguidos → ya los sigo por definición
      _siguiendo = true;
    } else {
      _loading = true;
      _checkSiguiendo();
    }
  }

  Future<void> _checkSiguiendo() async {
    try {
      final result = await UsuarioService.estasSiguiendo(
          widget.usuarioLogueadoId, widget.perfil.idSeguido);
      if (mounted) setState(() { _siguiendo = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    if (_loading) return;
    final siguiendoActual = _siguiendo;
    setState(() => _loading = true);
    try {
      await InteraccionesService.actualizarSeguido({
        'id_seguidor': widget.usuarioLogueadoId,
        'id_seguido': widget.perfil.idSeguido,
        'siguiendo': siguiendoActual,
      });
      if (mounted) setState(() { _siguiendo = !siguiendoActual; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;
    final nombre = perfil.nombreUsuario;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
            backgroundImage: (perfil.fotoUrl != null && perfil.fotoUrl!.isNotEmpty)
                ? NetworkImage(perfil.fotoUrl!)
                : null,
            child: (perfil.fotoUrl == null || perfil.fotoUrl!.isEmpty)
                ? Text(inicial,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: widget.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${perfil.totalRecetas} recetas',
                    style: TextStyle(fontSize: 12, color: widget.muted)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _siguiendo
                  ? Color.lerp(AppTheme.primary, Colors.black, 0.30)
                  : AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: _loading ? null : _toggle,
            child: _loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_siguiendo ? 'Siguiendo' : 'Seguir'),
          ),
        ],
      ),
    );
  }
}

// ── DELEGATE PARA TAB BAR STICKY ─────────────────────────────────────────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  final Color border;

  const _StickyTabBarDelegate(this.tabBar,
      {required this.color, required this.border});

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
