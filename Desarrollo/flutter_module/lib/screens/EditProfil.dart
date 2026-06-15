import 'package:flutter/material.dart';
import 'package:flutter_module/models/UsuarioLogged.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/Notifier.dart';
import '../theme/App.dart';
import '../services/UploadImg.dart';
import '../services/Usuario.dart';
import '../services/Session.dart';
import '../services/Receta.dart';
import '../utils/validations.dart';
import 'BarraNavegacion.dart';
import 'ForgotPass.dart';
import 'ConfirmEdit.dart';

class EditProfileScreen extends StatefulWidget {
  final usuario_Logged user;
  final ThemeNotifier themeNotifier;
  final void Function(usuario_Logged)? onSaved;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.themeNotifier,
    this.onSaved,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usuarioCtrl;
  late TextEditingController _correoCtrl;
  int? _generoId;
  List<dynamic> _generos = [];
  int _cantRecetas = 0;
  int _cantSeguidores = 0;
  String _correoOriginal = '';
  String _usuarioOriginal = '';
  bool _cargando = true;
  String? _fotoUrl;
  String? _bannerUrl;
  bool _uploading = false;
  bool _saving    = false;

  @override
  void initState() {
    super.initState();
    _usuarioCtrl = TextEditingController(text: widget.user.usuario);
    _correoCtrl  = TextEditingController();
    _cargarDatos();
  }

  /// Trae el catálogo de géneros y los datos editables del propio perfil
  /// (usuario, correo, id_genero) y precarga el formulario.
  Future<void> _cargarDatos() async {
    try {
      final generos = await UsuarioService.getGeneros();
      final perfil  = await UsuarioService.getPerfilEditable(widget.user.id);
      final cantRecetas = await RecetaService.contarRecetas(widget.user.id);
      final cantSeguidores = await UsuarioService.contarSeguidores(widget.user.id);
      if (!mounted) return;
      setState(() {
        _generos = generos;
        _usuarioCtrl.text = perfil['usuario'] ?? widget.user.usuario;
        _correoCtrl.text  = perfil['correo'] ?? '';
        _usuarioOriginal  = _usuarioCtrl.text;
        _correoOriginal   = _correoCtrl.text;
        _generoId = perfil['id_genero'] as int?;
        _cantRecetas = cantRecetas;
        _cantSeguidores = cantSeguidores;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron cargar tus datos: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final usuarioNuevo = _usuarioCtrl.text.trim();
    final correoNuevo  = _correoCtrl.text.trim();
    // ¿Cambió correo o usuario? → confirmación por OTP (pantalla estilo reset).
    final cambioSensible =
        correoNuevo != _correoOriginal || usuarioNuevo != _usuarioOriginal;

    if (!cambioSensible) {
      await _aplicarCambios(); // foto/género/etc. → directo, sin OTP
      return;
    }

    // Los cambios se aplican atómicamente (RPC) recién tras validar el OTP.
    final datos = <String, dynamic>{
      'usuario': usuarioNuevo,
      'correo': correoNuevo,
      if (_generoId != null) 'id_genero': _generoId,
      if (_fotoUrl != null) 'foto': _fotoUrl,
      if (_bannerUrl != null) 'banner': _bannerUrl,
    };
    final confirmado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmEditScreen(
          themeNotifier: widget.themeNotifier,
          idUsuario: widget.user.id,
          correo: _correoOriginal, // el código va al correo ACTUAL
          datos: datos,
        ),
      ),
    );
    if (confirmado == true) await _finalizarYsalir(); // ya quedó guardado en la BD
  }

  /// Guarda directo (sin OTP) — para cambios no sensibles (foto/banner/género).
  Future<void> _aplicarCambios() async {
    setState(() => _saving = true);
    try {
      await UsuarioService.actualizarPerfil(
        id:        widget.user.id,
        usuario:   _usuarioCtrl.text.trim(),
        correo:    _correoCtrl.text.trim().isEmpty ? null : _correoCtrl.text.trim(),
        idGenero:  _generoId,
        fotoUrl:   _fotoUrl,
        bannerUrl: _bannerUrl,
      );
      await _finalizarYsalir();
    } on Exception catch (e) {
      if (mounted) _snack('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Actualiza la sesión local y cierra la pantalla (los datos ya están en la BD).
  Future<void> _finalizarYsalir() async {
    final updatedUser = usuario_Logged(
      widget.user.id,
      widget.user.id_Cuenta,
      _usuarioCtrl.text.trim(),
      widget.user.fotoBase64,
      widget.user.bannerBase64,
      fotoUrl:   _fotoUrl   ?? widget.user.fotoUrl,
      bannerUrl: _bannerUrl ?? widget.user.bannerUrl,
    );
    await SessionService.saveSession(updatedUser);
    widget.onSaved?.call(updatedUser);
    if (!mounted) return;
    _snack('Cambios guardados correctamente');
    Navigator.pop(context);
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.primary,
      ),
    );
  }

  void _mostrarProximamente(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — Próximamente')),
    );
  }

  Future<void> _cambiarFoto() => _pickAndUpload(
        label: 'foto',
        upload: (src) => ImageUploadService.uploadFotoPerfil(widget.user.id, src),
        onDone: (url) => setState(() => _fotoUrl = _bustCache(url)),
      );

  Future<void> _cambiarBanner() => _pickAndUpload(
        label: 'banner',
        upload: (src) => ImageUploadService.uploadBanner(widget.user.id, src),
        onDone: (url) => setState(() => _bannerUrl = _bustCache(url)),
      );

  /// Storage sobrescribe la imagen en la MISMA URL (upsert), así que NetworkImage
  /// la mostraría cacheada. Le sumamos ?t=<timestamp> para forzar que la recargue.
  String _bustCache(String url) => '$url?t=${DateTime.now().millisecondsSinceEpoch}';

  Future<void> _pickAndUpload({
    required String label,
    required Future<String?> Function(ImageSource) upload,
    required void Function(String) onDone,
  }) async {
    final source = await _showSourceSheet();
    if (source == null) return;
    setState(() => _uploading = true);
    try {
      final url = await upload(source);
      if (url != null) onDone(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir $label: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<ImageSource?> _showSourceSheet() => showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppTheme.primary),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

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
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
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

    final String? urlImgMomentanea = _fotoUrl ?? widget.user.fotoUrl;
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
              ),
              clipBehavior: Clip.antiAlias,
              child: urlImgMomentanea != null
                  ? Image.network(urlImgMomentanea, fit: BoxFit.cover)
                  : widget.user.fotoReady != null
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
                onTap: _uploading ? null : _cambiarFoto,
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
            _chipStat('$_cantRecetas ${_cantRecetas == 1 ? 'Receta' : 'Recetas'}', border, text),
            _chipStat('$_cantSeguidores ${_cantSeguidores == 1 ? 'Seguidor' : 'Seguidores'}', border, text),
          ],
        ),
        const SizedBox(height: 16),
        // Banner upload
        GestureDetector(
          onTap: _uploading ? null : _cambiarBanner,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
              color: _bannerUrl != null ? null : AppTheme.primary.withValues(alpha: 0.06),
              image: _bannerUrl != null
                  ? DecorationImage(image: NetworkImage(_bannerUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: _bannerUrl == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.panorama_outlined, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Cambiar banner',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        if (_uploading) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(color: AppTheme.primary),
        ],
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
                  validator: (v) => Validaciones.usuario(v ?? ''),
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
                  // Obligatorio + formato válido (ej: nombre@dominio.com).
                  validator: (v) => Validaciones.correo(v ?? ''),
                ),
                const SizedBox(height: 18),

                // ── Género ──
                _fieldLabel('Género'),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: _generoId,
                  dropdownColor: surface,
                  style: TextStyle(color: text, fontSize: 14),
                  decoration: _inputDecoration(
                    hint: 'Seleccioná',
                    prefixIcon: Icons.person_search_outlined,
                    bg: inputBg,
                    border: border,
                    muted: muted,
                  ),
                  items: _generos
                      .map((g) => DropdownMenuItem<int>(
                            value: g['id'] as int,
                            child: Text(g['nombre'] as String),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _generoId = v),
                  validator: (v) => v == null ? 'Seleccioná un género' : null,
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
                      onPressed: _saving ? null : _guardarCambios,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar cambios',
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ForgotPasswordScreen(
                      themeNotifier: widget.themeNotifier,
                    ),
                  ),
                ),
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
