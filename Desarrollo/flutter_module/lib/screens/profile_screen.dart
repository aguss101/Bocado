import 'package:flutter/material.dart';
import 'package:flutter_module/models/usuario_Logged.dart';
import '../theme/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'shared_drawer.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.themeNotifier,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
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
      body: NestedScrollView(
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
                tabs: const [
                  Tab(text: 'Recetas Publicadas'),
                  Tab(text: 'Guardados'),
                  Tab(text: 'Borradores'),
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
          children: [
            _buildRecetasTab(surface, border, text, muted),
            _buildPlaceholderTab('favorite_border', 'Sin guardados aún', muted),
            _buildPlaceholderTab('draft', 'Sin borradores', muted),
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
          widget.user.bannerReady != null
              ? Image.memory(widget.user.bannerReady!, fit: BoxFit.cover)
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
          // Botón editar portada
          Positioned(
            bottom: 12,
            right: 16,
            child: _glassButton(
              icon: Icons.photo_camera_outlined,
              label: 'Editar Portada',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente')),
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            user: widget.user,
                            themeNotifier: widget.themeNotifier,
                          ),
                        ),
                      ),
                      child: const Text('Editar Perfil',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
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
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(
                                const SnackBar(content: Text('Compartir'))),
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
                  widget.user.usuario,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: text),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${widget.user.usuario.toLowerCase().replaceAll(' ', '_')}',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                // Badges
                Row(
                  children: [
                    if (widget.user.id_Cuenta == 2)
                      _badge(
                          icon: Icons.verified_outlined,
                          label: 'PRO',
                          bg: AppTheme.primary.withValues(alpha: 0.12),
                          textColor: AppTheme.primary),
                    const SizedBox(width: 8),
                    _badge(
                        icon: Icons.location_on_outlined,
                        label: 'Bocado Chef',
                        bg: Colors.transparent,
                        textColor: muted),
                  ],
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
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 3),
        color: AppTheme.primary.withValues(alpha: 0.15),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.user.fotoReady != null
          ? Image.memory(widget.user.fotoReady!, fit: BoxFit.cover)
          : Center(
              child: Text(
                widget.user.usuario.isNotEmpty
                    ? widget.user.usuario[0].toUpperCase()
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
          _statItem('12', 'Recetas', text, muted),
          _dividerV(border),
          _statItem('845', 'Seguidores', text, muted),
          _dividerV(border),
          _statItem('150', 'Siguiendo', text, muted),
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

  // ── TAB: RECETAS ──────────────────────────────────────────────────────────
  Widget _buildRecetasTab(
      Color surface, Color border, Color text, Color muted) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        if (index == 4) {
          // Card "Crear nueva receta"
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: border, width: 2, style: BorderStyle.solid),
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
                  child: const Icon(Icons.add,
                      color: AppTheme.primary, size: 28),
                ),
                const SizedBox(height: 10),
                Text('Crear Receta',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: muted)),
              ],
            ),
          );
        }
        // Cards de receta de ejemplo
        return _recipeCard(
          surface: surface,
          border: border,
          text: text,
          muted: muted,
          title: ['Pan de masa madre', 'Hamburguesa Gourmet',
              'Croissant', 'Focaccia'][index],
          time: ['45 min', '20 min', '90 min', '60 min'][index],
          rating: ['4.9', '4.7', '4.8', '4.6'][index],
          level: ['Intermedio', 'Principiante', 'Avanzado', 'Intermedio'][index],
        );
      },
    );
  }

  Widget _recipeCard({
    required Color surface,
    required Color border,
    required Color text,
    required Color muted,
    required String title,
    required String time,
    required String rating,
    required String level,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen placeholder
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  child: Icon(Icons.restaurant,
                      size: 40,
                      color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
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
                    child: Text(time,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
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
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 12, color: AppTheme.primary),
                        const SizedBox(width: 2),
                        Text(rating,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: muted)),
                      ],
                    ),
                    Text(level,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: muted,
                            letterSpacing: 0.3)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB: SEGUIDOS ─────────────────────────────────────────────────────────
  Widget _buildSeguidosTab(
      Color surface, Color border, Color text, Color muted) {
    final seguidos = [
      {'nombre': 'Chef Ramírez', 'recetas': '42'},
      {'nombre': 'La Pastelera', 'recetas': '18'},
      {'nombre': 'Don Asado', 'recetas': '31'},
      {'nombre': 'Fit Kitchen', 'recetas': '25'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: seguidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = seguidos[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                child: Text(
                  s['nombre']![0],
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['nombre']!,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: text)),
                    Text('${s['recetas']} recetas',
                        style:
                            TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: border),
                  foregroundColor: muted,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {},
                child: const Text('Siguiendo'),
              ),
            ],
          ),
        );
      },
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

  Widget _badge(
      {required IconData icon,
      required String label,
      required Color bg,
      required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
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
