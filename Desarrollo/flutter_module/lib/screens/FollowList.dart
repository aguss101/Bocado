import 'package:flutter/material.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:flutter_module/models/UserProfile.dart';
import '../services/Usuario.dart';
import '../services/Instructions.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/Common.dart';
import '../route_observer.dart';
import '../utils/PagedList.dart';
import 'Profile.dart';

Future<void> mostrarSeguidoresDialog(
  BuildContext context, {
  required usuario_Logged user,
  required ThemeNotifier themeNotifier,
  required int idPerfil,
  bool abrirEnSeguidores = true,
}) {
  return showDialog(
    context: context,
    builder: (_) => _FollowListDialog(
      user: user,
      themeNotifier: themeNotifier,
      idPerfil: idPerfil,
      abrirEnSeguidores: abrirEnSeguidores,
    ),
  );
}

class _FollowListDialog extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;
  final int idPerfil;
  final bool abrirEnSeguidores;

  const _FollowListDialog({
    required this.user,
    required this.themeNotifier,
    required this.idPerfil,
    this.abrirEnSeguidores = true,
  });

  @override
  State<_FollowListDialog> createState() => _FollowListDialogState();
}

class _FollowListDialogState extends State<_FollowListDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final _PagedFollowList _seguidores;
  late final _PagedFollowList _siguiendo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.abrirEnSeguidores ? 0 : 1,
    );
    _seguidores = _PagedFollowList(
      (offset, limit) => UsuarioService.getSeguidoresDe(widget.idPerfil, limit: limit, offset: offset),
      otroId: (p) => p.idSeguidor,
    );
    _siguiendo = _PagedFollowList(
      (offset, limit) => UsuarioService.getSeguidores(widget.idPerfil, limit: limit, offset: offset),
      otroId: (p) => p.idSeguido,
    );
    _cargar(_seguidores);
    _cargar(_siguiendo);
  }

  Future<void> _cargar(_PagedFollowList lista) async {
    await lista.cargarPrimera();
    if (!mounted) return;
    setState(() {});
    final ids = lista.items.map((p) => lista.otroId(p)).where((id) => id != widget.user.id).toList();
    final seguidos = await UsuarioService.estasSiguiendoVarios(widget.user.id, ids);
    if (!mounted) return;
    setState(() => lista.siguiendoActual.addAll(seguidos));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    return Dialog(
      backgroundColor: c.bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BocadoRadius.lg)),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seguidores',
                      style: TextStyle(color: c.text, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: c.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: c.muted,
              indicatorColor: AppTheme.primary,
              tabs: const [
                Tab(text: 'Seguidores'),
                Tab(text: 'Siguiendo'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FollowListTab(user: widget.user, themeNotifier: widget.themeNotifier, lista: _seguidores),
                  _FollowListTab(user: widget.user, themeNotifier: widget.themeNotifier, lista: _siguiendo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowListTab extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;
  final _PagedFollowList lista;

  const _FollowListTab({required this.user, required this.themeNotifier, required this.lista});

  @override
  State<_FollowListTab> createState() => _FollowListTabState();
}

class _FollowListTabState extends State<_FollowListTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      widget.lista.cargarMas().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = widget.lista;
    if (lista.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lista.items.isEmpty) {
      return const BocadoEmptyState(icon: Icons.people_outline, message: 'No hay nadie para mostrar todavía');
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: lista.items.length + (lista.cargandoMas ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= lista.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final perfil = lista.items[index];
        final otroId = lista.otroId(perfil);
        return _FollowTile(
          key: ValueKey(otroId),
          nombre: perfil.nombreUsuario,
          fotoUrl: perfil.fotoUrl,
          esUnoMismo: otroId == widget.user.id,
          siguiendoInicial: lista.siguiendoActual.contains(otroId),
          usuarioLogueadoId: widget.user.id,
          idOtro: otroId,
          onTap: () {
            Navigator.pop(context);
            pushOrReuse(
              context,
              'perfil/$otroId',
              (_) => ProfileScreen(
                user: widget.user,
                themeNotifier: widget.themeNotifier,
                idUsuarioTarget: otroId,
              ),
            );
          },
        );
      },
    );
  }
}

class _FollowTile extends StatefulWidget {
  final String nombre;
  final String? fotoUrl;
  final bool esUnoMismo;
  final bool siguiendoInicial;
  final int usuarioLogueadoId;
  final int idOtro;
  final VoidCallback onTap;

  const _FollowTile({
    super.key,
    required this.nombre,
    required this.fotoUrl,
    required this.esUnoMismo,
    required this.siguiendoInicial,
    required this.usuarioLogueadoId,
    required this.idOtro,
    required this.onTap,
  });

  @override
  State<_FollowTile> createState() => _FollowTileState();
}

class _FollowTileState extends State<_FollowTile> {
  late bool _siguiendo = widget.siguiendoInicial;
  bool _cargando = false;

  @override
  void didUpdateWidget(covariant _FollowTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siguiendoInicial != widget.siguiendoInicial) {
      _siguiendo = widget.siguiendoInicial;
    }
  }

  Future<void> _toggle() async {
    if (_cargando) return;
    final siguiendoActual = _siguiendo;
    setState(() => _cargando = true);
    try {
      await InteraccionesService.actualizarSeguido({
        'id_seguidor': widget.usuarioLogueadoId,
        'id_seguido': widget.idOtro,
        'siguiendo': siguiendoActual,
      });
      if (mounted) setState(() {
        _siguiendo = !siguiendoActual;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    final inicial = widget.nombre.isNotEmpty ? widget.nombre[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: c.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              backgroundImage: (widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty)
                  ? bocadoImageProvider(widget.fotoUrl!)
                  : null,
              child: (widget.fotoUrl == null || widget.fotoUrl!.isEmpty)
                  ? Text(inicial, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.nombre,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: c.text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.esUnoMismo)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _siguiendo ? Color.lerp(AppTheme.primary, Colors.black, 0.30) : AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _cargando ? null : _toggle,
                child: _cargando
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_siguiendo ? 'Siguiendo' : 'Seguir'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PagedFollowList {
  final PagedList<UserProfile> _paged;
  final int Function(UserProfile) otroId;
  final Set<int> siguiendoActual = {};

  _PagedFollowList(Future<List<UserProfile>> Function(int, int) fetch,
      {required this.otroId, int pageSize = 20})
      : _paged = PagedList(fetch, pageSize: pageSize);

  List<UserProfile> get items => _paged.items;
  bool get cargando => _paged.cargando;
  bool get cargandoMas => _paged.cargandoMas;
  bool get hayMas => _paged.hayMas;

  Future<void> cargarPrimera() => _paged.cargarPrimera();
  Future<void> cargarMas() => _paged.cargarMas();
}
