import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/Usuario.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import 'Feed.dart';

/// Paso 2 del alta con Google: completa los datos que Google no provee
/// (nación, género, fecha de nacimiento) y recién ahí crea el usuario.
class CompleteGoogleProfileScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final GooglePerfil perfil;

  const CompleteGoogleProfileScreen({
    super.key,
    required this.themeNotifier,
    required this.perfil,
  });

  @override
  State<CompleteGoogleProfileScreen> createState() =>
      _CompleteGoogleProfileScreenState();
}

class _CompleteGoogleProfileScreenState
    extends State<CompleteGoogleProfileScreen> {
  final _fechaController = TextEditingController();
  List<dynamic> _naciones = [];
  List<dynamic> _generos = [];
  bool _cargandoOpciones = true;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _fechaNacimiento;
  int? _idNacion;
  int? _idGenero;

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    try {
      final naciones = await UsuarioService.getNaciones();
      final generos = await UsuarioService.getGeneros();
      if (mounted) {
        setState(() {
          _naciones = naciones;
          _generos = generos;
          _cargandoOpciones = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudieron cargar las opciones: $e';
          _cargandoOpciones = false;
        });
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (seleccion != null) {
      setState(() {
        _fechaNacimiento = seleccion;
        _fechaController.text =
            '${seleccion.day}/${seleccion.month}/${seleccion.year}';
      });
    }
  }

  Future<void> _finalizar() async {
    if (_isLoading) return;
    final error =
        (_fechaNacimiento == null ? 'Elegí tu fecha de nacimiento.' : null) ??
            (_idNacion == null ? 'Elegí tu nación.' : null) ??
            (_idGenero == null ? 'Elegí tu género.' : null);
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await UsuarioService.registrarUsuarioGoogle(
        perfil: widget.perfil,
        nacion: _idNacion!,
        genero: _idGenero!,
        fechaNacimiento: _fechaNacimiento!.toIso8601String(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FeedScreen(themeNotifier: widget.themeNotifier, user: user),
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() {
        switch (e.code) {
          case 'DUPLICADO':
            _errorMessage = e.message ?? 'Ese correo ya está registrado.';
            break;
          case 'NETWORK_ERROR':
            _errorMessage = 'Sin conexión con el servidor. Revisá tu internet.';
            break;
          case 'NEGOCIO':
            _errorMessage = e.message ?? 'Revisá los datos ingresados.';
            break;
          case 'ERROR_JSON':
            _errorMessage = 'Hubo un problema al preparar los datos. Intentá de nuevo.';
            break;
          case 'ERROR_API':
          case 'ERROR_REGISTRO':
            _errorMessage = e.message ?? 'El servidor rechazó la creación. Intentá de nuevo.';
            break;
          default:
            _errorMessage = e.message ?? 'No se pudo crear la cuenta (${e.code}).';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error procesando la respuesta.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return AuthScaffold(
      themeNotifier: widget.themeNotifier,
      child: Center(
        child: AuthCard(
          child: _cargandoOpciones
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Icon(Icons.verified_user_outlined,
                          color: AppTheme.primary, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Completá tu perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppTheme.onSurfaceDark
                            : AppTheme.onSurfaceLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Faltan unos datos que Google no nos da'
                      '${widget.perfil.nombre.isNotEmpty ? ', ${widget.perfil.nombre}' : ''}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.perfil.correo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Fecha de nacimiento ──────────────────────────
                    const AuthFieldLabel('Fecha de nacimiento'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _seleccionarFecha,
                      child: AbsorbPointer(
                        child: AuthTextField(
                          controller: _fechaController,
                          hint: 'DD/MM/AAAA',
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Nación ───────────────────────────────────────
                    const AuthFieldLabel('Nación'),
                    const SizedBox(height: 8),
                    _OnboardingDropdown(
                      value: _idNacion,
                      hint: 'Seleccionar nación',
                      icon: Icons.public,
                      items: _naciones,
                      isDark: isDark,
                      secondary: secondary,
                      outline: outline,
                      onChanged: (v) => setState(() => _idNacion = v),
                    ),
                    const SizedBox(height: 20),

                    // ── Género ───────────────────────────────────────
                    const AuthFieldLabel('Género'),
                    const SizedBox(height: 8),
                    _OnboardingDropdown(
                      value: _idGenero,
                      hint: 'Seleccionar género',
                      icon: Icons.people_outline,
                      items: _generos,
                      isDark: isDark,
                      secondary: secondary,
                      outline: outline,
                      onChanged: (v) => setState(() => _idGenero = v),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _finalizar,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Crear cuenta',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Dropdown de catálogo (nación/género) con el estilo de las pantallas de auth.
class _OnboardingDropdown extends StatelessWidget {
  final int? value;
  final String hint;
  final IconData icon;
  final List<dynamic> items;
  final bool isDark;
  final Color secondary;
  final Color outline;
  final ValueChanged<int?> onChanged;

  const _OnboardingDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.isDark,
    required this.secondary,
    required this.outline,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: value,
      dropdownColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondary, fontSize: 14),
        prefixIcon: Icon(icon, color: secondary, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      items: items.map<DropdownMenuItem<int>>((it) {
        return DropdownMenuItem<int>(
          value: it['id'],
          child: Text(it['nombre']),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
