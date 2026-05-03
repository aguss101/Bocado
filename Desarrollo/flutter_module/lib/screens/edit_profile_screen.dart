import 'package:flutter/material.dart';
import 'package:flutter_module/models/usuario_Logged.dart';
import '../theme/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'shared_drawer.dart';

class EditProfileScreen extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.themeNotifier,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usuarioCtrl;
  late TextEditingController _correoCtrl;
  String _genero = 'masculino';

  @override
  void initState() {
    super.initState();
    _usuarioCtrl = TextEditingController(text: widget.user.usuario);
    _correoCtrl  = TextEditingController();
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  void _guardarCambios() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados correctamente'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  void _mostrarProximamente(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — Próximamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? AppTheme.bgDark            : AppTheme.surfaceContainerLight;
    final surface  = isDark ? AppTheme.surfaceDark        : AppTheme.surfaceLight;
    final border   = isDark ? AppTheme.outlineDark        : AppTheme.outlineLight;
    final text     = isDark ? AppTheme.onSurfaceDark      : AppTheme.onSurfaceLight;
    final muted    = isDark ? AppTheme.secondaryDark      : AppTheme.secondaryLight;
    final inputBg  = isDark ? AppTheme.surfaceContainerDark : AppTheme.surfaceContainerLight;

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Información de cuenta',
          style: TextStyle(
              color: text, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          // Toggle de tema
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
          // Abrir drawer
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.primary),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ENCABEZADO ──
            Text(
              'Información de cuenta',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: text),
            ),
            const SizedBox(height: 4),
            Text(
              'Actualiza tus datos personales y gestioná cómo te ven otros chefs.',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 28),

            // ── CONTENIDO PRINCIPAL ──
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 640;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: _buildAvatarColumn(text, muted, surface, border),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: _buildFormColumn(
                          surface, border, text, muted, inputBg),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildAvatarColumn(text, muted, surface, border),
                    const SizedBox(height: 24),
                    _buildFormColumn(surface, border, text, muted, inputBg),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  // ── COLUMNA IZQUIERDA: AVATAR ─────────────────────────────────────────────
  Widget _buildAvatarColumn(
      Color text, Color muted, Color surface, Color border) {
    return Column(
      children: [
        // Avatar grande con botón cámara
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2), width: 3),
                color: AppTheme.primary.withValues(alpha: 0.1),
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
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary),
                      ),
                    ),
            ),
            // Botón cámara
            Positioned(
              bottom: -8,
              right: -8,
              child: GestureDetector(
                onTap: () => _mostrarProximamente('Cambiar foto'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.photo_camera,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Nombre
        Text(
          widget.user.usuario,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Chef Bocado',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppTheme.primary),
        ),
        const SizedBox(height: 14),
        // Chips stats
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _chipStat('12 Recetas', border, text),
            _chipStat('845 Seguidores', border, text),
          ],
        ),
      ],
    );
  }

  Widget _chipStat(String label, Color border, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: text)),
    );
  }

  // ── COLUMNA DERECHA: FORMULARIO ───────────────────────────────────────────
  Widget _buildFormColumn(Color surface, Color border, Color text,
      Color muted, Color inputBg) {
    return Column(
      children: [
        // Formulario
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nombre de usuario ──
                _fieldLabel('Nombre de usuario'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _usuarioCtrl,
                  style: TextStyle(color: text, fontSize: 14),
                  decoration: _inputDecoration(
                    hint: 'tu_usuario',
                    prefixIcon: Icons.alternate_email,
                    bg: inputBg,
                    border: border,
                    muted: muted,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 18),

                // ── Correo electrónico ──
                _fieldLabel('Correo electrónico'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _correoCtrl,
                  style: TextStyle(color: text, fontSize: 14),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: 'correo@bocado.app',
                    prefixIcon: Icons.mail_outline,
                    bg: inputBg,
                    border: border,
                    muted: muted,
                  ),
                ),
                const SizedBox(height: 18),

                // ── Género ──
                _fieldLabel('Género'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _genero,
                  dropdownColor: surface,
                  style: TextStyle(color: text, fontSize: 14),
                  decoration: _inputDecoration(
                    hint: 'Seleccioná',
                    prefixIcon: Icons.person_search_outlined,
                    bg: inputBg,
                    border: border,
                    muted: muted,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'masculino', child: Text('Masculino')),
                    DropdownMenuItem(
                        value: 'femenino', child: Text('Femenino')),
                    DropdownMenuItem(
                        value: 'no_binario', child: Text('No binario')),
                    DropdownMenuItem(
                        value: 'prefiero_no',
                        child: Text('Prefiero no decir')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _genero = v);
                  },
                ),

                const SizedBox(height: 28),
                Divider(color: border),
                const SizedBox(height: 20),

                // ── Botones ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: muted,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _guardarCambios,
                      child: const Text('Guardar cambios',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Cards de acción ──
        Row(
          children: [
            Expanded(
              child: _actionCard(
                icon: Icons.lock_outline,
                title: 'Seguridad',
                subtitle: 'Cambiá tu contraseña y activá 2FA',
                surface: surface,
                border: border,
                text: text,
                muted: muted,
                onTap: () => _mostrarProximamente('Seguridad'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                icon: Icons.verified_user_outlined,
                title: 'Privacidad',
                subtitle: 'Gestioná quién puede ver tu perfil',
                surface: surface,
                border: border,
                text: text,
                muted: muted,
                onTap: () => _mostrarProximamente('Privacidad'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
          letterSpacing: 1),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    required Color bg,
    required Color border,
    required Color muted,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: muted, fontSize: 13),
      filled: true,
      fillColor: bg,
      prefixIcon: Icon(prefixIcon, size: 18, color: muted),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color surface,
    required Color border,
    required Color text,
    required Color muted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 26),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: text)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: muted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
