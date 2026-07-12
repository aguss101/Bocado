import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/Usuario.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import 'Feed.dart';

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
      naciones.sort((a, b) => (a['nombre'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['nombre'] ?? '').toString().toLowerCase()));
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
          colorScheme: ColorScheme.light(primary: BocadoColors.of(context).primary),
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FeedScreen(themeNotifier: widget.themeNotifier, user: user),
          ),
          (route) => false,
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
    final c = BocadoColors.of(context);
    final isDark = c.isDark;
    final secondary = c.muted;

    return AuthScaffold(
      themeNotifier: widget.themeNotifier,
      child: Center(
        child: AuthCard(
          child: _cargandoOpciones
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: c.primary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Icon(Icons.verified_user_outlined,
                          color: c.primary, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Completá tu perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: c.text,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: c.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),

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

                    const AuthFieldLabel('Nación'),
                    const SizedBox(height: 8),
                    AuthDropdown(
                      value: _idNacion,
                      hint: 'Seleccionar nación',
                      icon: Icons.public,
                      items: _naciones,
                      onChanged: (v) => setState(() => _idNacion = v),
                    ),
                    const SizedBox(height: 20),

                    const AuthFieldLabel('Género'),
                    const SizedBox(height: 8),
                    AuthDropdown(
                      value: _idGenero,
                      hint: 'Seleccionar género',
                      icon: Icons.people_outline,
                      items: _generos,
                      onChanged: (v) => setState(() => _idGenero = v),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      AuthErrorBox(_errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    AuthPrimaryButton(
                      label: 'Crear cuenta',
                      onTap: _finalizar,
                      loading: _isLoading,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
