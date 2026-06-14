import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/Usuario.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import 'Feed.dart';
import 'LogIn.dart';
import 'OnboardingGoogle.dart';
import '../utils/validations.dart';

class RegisterScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const RegisterScreen({super.key, required this.themeNotifier});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fechaController = TextEditingController();
  List<dynamic> _naciones = [];
  List<dynamic> _generos = [];
  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _cargandoOpciones = true;
  String? _errorMessage;
  DateTime? _fechaNacimientoSeleccionada;
  int? _idNacionSeleccionada;
  int? _idGeneroSeleccionado;

  Future<void> _register() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final email = _emailController.text.trim();
    final usuario = _usuarioController.text.trim();
    final password = _passwordController.text;
    final nacion = _idNacionSeleccionada;
    final genero = _idGeneroSeleccionado;
    final fechaNacimiento = _fechaNacimientoSeleccionada;

    // Validación campo por campo: muestra el primer error específico.
    final error = Validaciones.nombre(nombre, campo: 'nombre')
        ?? Validaciones.nombre(apellido, campo: 'apellido')
        ?? Validaciones.correo(email)
        ?? (fechaNacimiento == null ? 'Elegí tu fecha de nacimiento.' : null)
        ?? (nacion == null ? 'Elegí tu nación.' : null)
        ?? (genero == null ? 'Elegí tu género.' : null)
        ?? Validaciones.usuario(usuario)
        ?? Validaciones.contrasena(password)
        ?? (!_acceptTerms
            ? 'Tenés que aceptar los Términos de Servicio para continuar.'
            : null);
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await UsuarioService.registrar(
        nacion: nacion!,
        genero: genero!,
        nombre: nombre,
        apellido: apellido,
        email: email,
        usuario: usuario,
        password: password,
        fechaNacimiento: fechaNacimiento!.toIso8601String(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FeedScreen(themeNotifier: widget.themeNotifier, user: user),
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() {
        switch (e.code) {
          case 'DUPLICADO':
            _errorMessage = e.message ?? 'Ese correo o usuario ya está registrado.';
            break;
          case 'NEGOCIO':
            _errorMessage = e.message ?? 'Revisá los datos ingresados.';
            break;
          case 'NETWORK_ERROR':
            _errorMessage = 'Sin conexión con el servidor. Revisá tu internet.';
            break;
          case 'ERROR_JSON':
            _errorMessage = 'Hubo un problema al preparar los datos. Intentá de nuevo.';
            break;
          case 'ERROR_API':
          case 'ERROR_REGISTRO':
            _errorMessage = e.message ?? 'El servidor rechazó el registro. Intentá de nuevo.';
            break;
          default:
            _errorMessage = e.message ?? 'No se pudo completar el registro (${e.code}).';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'No se pudo procesar la respuesta del servidor.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Alta/login con Google. No exige aceptar términos (decisión de producto).
  /// Usa el mismo método compartido que Login: el backend hace login-or-create.
  Future<void> _registrarConGoogle() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final outcome = await UsuarioService.signInWithGoogle();
      if (outcome.cancelado) return; // canceló — el finally limpia _isLoading

      if (outcome.existente != null) {
        // Ya tenía cuenta → entra directo.
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FeedScreen(themeNotifier: widget.themeNotifier, user: outcome.existente!),
            ),
          );
        }
      } else {
        // Usuario nuevo → completar nación/género/fecha.
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CompleteGoogleProfileScreen(
                themeNotifier: widget.themeNotifier,
                perfil: outcome.nuevo!,
              ),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      setState(() {
        switch (e.code) {
          case 'NETWORK_ERROR':
          case 'network_error':
            _errorMessage = 'Sin conexión. No se pudo contactar a Google.';
            break;
          case 'sign_in_failed':
            _errorMessage = 'No se pudo registrar con Google. Verificá la configuración de la cuenta.';
            break;
          case 'NEGOCIO':
            _errorMessage = e.message ?? 'Google no devolvió los datos necesarios.';
            break;
          default:
            _errorMessage = e.message ?? 'No se pudo continuar con Google (${e.code}).';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'No se pudo registrar con Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (seleccion != null && seleccion != _fechaNacimientoSeleccionada) {
      setState(() {
        _fechaNacimientoSeleccionada = seleccion;
        // Formateamos la fecha (Ej: 28/03/2000)
        _fechaController.text = "${seleccion.day}/${seleccion.month}/${seleccion.year}";
      });
    }
  }

  @override
  void initState(){
    super.initState();
    _traerDatosdelaBase();
  }
  Future<void> _traerDatosdelaBase() async {
    try {
      final naciones = await UsuarioService.getNaciones();
      final generos  = await UsuarioService.getGeneros();
      if (mounted) {
        setState(() {
          _naciones = naciones;
          _generos  = generos;
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

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    final outline = isDark ? AppTheme.outlineDark : AppTheme.outlineLight;

    return AuthScaffold(
      themeNotifier: widget.themeNotifier,
      headerTrailing: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(themeNotifier: widget.themeNotifier),
          ),
        ),
        child: RichText(
          text: TextSpan(
            text: '¿Ya tenés cuenta? ',
            style: TextStyle(fontSize: 12, color: secondary),
            children: const [
              TextSpan(
                text: 'Iniciá sesión',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Center(
        child: AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title ─────────────────────────────────────────
              Text(
                'Crea tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Uníte a la comunidad de chefs más exclusiva',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secondary),
              ),
              const SizedBox(height: 28),

              // ── Nombre / Apellido ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthFieldLabel('Nombre'),
                        const SizedBox(height: 8),
                        AuthTextField(
                          controller: _nombreController,
                          hint: 'Ej. Juan',
                          prefixIcon: Icons.person_outline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthFieldLabel('Apellido'),
                        const SizedBox(height: 8),
                        AuthTextField(
                          controller: _apellidoController,
                          hint: 'Ej. Pérez',
                          prefixIcon: Icons.person_outline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Email ─────────────────────────────────────────
              const AuthFieldLabel('Correo electrónico'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _emailController,
                hint: 'tu@email.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              // ── Fecha de Nacimiento ───────────────────────────
              const AuthFieldLabel('Fecha de nacimiento'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _seleccionarFecha(context),
                child: AbsorbPointer( // Esto evita que aparezca el teclado de texto
                  child: AuthTextField(
                    controller: _fechaController,
                    hint: 'DD/MM/AAAA',
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ── Nación / Género ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthFieldLabel('Nación'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _idNacionSeleccionada,
                          dropdownColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Seleccionar',
                            hintStyle: TextStyle(color: secondary, fontSize: 14),
                            prefixIcon: Icon(Icons.public, color: secondary, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                            ),
                          ),
                          items: _naciones.map<DropdownMenuItem<int>>((nacion) {
                            return DropdownMenuItem<int>(
                              value: nacion['id'],
                              child: Text(nacion['nombre']),
                            );
                          }).toList(),
                          onChanged: (int? nuevoInt) {
                            setState(() {
                              _idNacionSeleccionada = nuevoInt;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthFieldLabel('Género'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          initialValue: _idGeneroSeleccionado,
                          dropdownColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Seleccionar',
                            hintStyle: TextStyle(color: secondary, fontSize: 14),
                            prefixIcon: Icon(Icons.people_outline, color: secondary, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                            ),
                          ),
                          items: _generos.map<DropdownMenuItem<int>>((genero) {
                            return DropdownMenuItem<int>(
                              value: genero['id'],
                              child: Text(genero['nombre']),
                            );
                          }).toList(),
                          onChanged: (int? nuevoInt) {
                            setState(() {
                              _idGeneroSeleccionado = nuevoInt;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Usuario ───────────────────────────────────────
              const AuthFieldLabel('Nombre de usuario'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _usuarioController,
                hint: '@tu_usuario',
                prefixIcon: Icons.alternate_email,
              ),
              const SizedBox(height: 20),

              // ── Password ──────────────────────────────────────
              const AuthFieldLabel('Contraseña'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _passwordController,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: secondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 20),

              // ── Terms ─────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _acceptTerms,
                      onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                      activeColor: AppTheme.primary,
                      side: BorderSide(color: outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                      child: RichText(
                        text: TextSpan(
                          text: 'Acepto los ',
                          style: TextStyle(fontSize: 12, color: secondary),
                          children: const [
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // ── Submit ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                  ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                  ),
                ): const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Registrarse',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
              // ── Divider ───────────────────────────────────────
              const AuthDivider(label: 'O REGISTRATE CON'),
              const SizedBox(height: 20),

              // ── Google ────────────────────────────────────────
              GoogleButton(onTap: _registrarConGoogle),
              const SizedBox(height: 20),

              // ── Security badge ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: outline)),
                ),
                child: Center(
                  child: Text(
                    'Seguridad de nivel profesional con cifrado de extremo a extremo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: secondary,
                      fontWeight: FontWeight.w500,
                    ),
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