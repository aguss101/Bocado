import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/Usuario.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import 'Feed.dart';
import 'LogIn.dart';
import 'OnboardingGoogle.dart';
import 'VerifyEmail.dart';
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

    setState(() => _errorMessage = null);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(
          themeNotifier: widget.themeNotifier,
          nacion: nacion!,
          genero: genero!,
          nombre: nombre,
          apellido: apellido,
          email: email,
          usuario: usuario,
          password: password,
          fechaNacimiento: fechaNacimiento!.toIso8601String(),
        ),
      ),
    );
  }
  Future<void> _registrarConGoogle() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final outcome = await UsuarioService.signInWithGoogle();
      if (outcome.cancelado) return;

      if (outcome.existente != null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => FeedScreen(themeNotifier: widget.themeNotifier, user: outcome.existente!),
            ),
            (route) => false,
          );
        }
      } else {
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
            colorScheme: ColorScheme.light(
              primary: BocadoColors.of(context).primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (seleccion != null && seleccion != _fechaNacimientoSeleccionada) {
      setState(() {
        _fechaNacimientoSeleccionada = seleccion;
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
      naciones.sort((a, b) => (a['nombre'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['nombre'] ?? '').toString().toLowerCase()));
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
    final c = BocadoColors.of(context);
    final isDark = c.isDark;
    final secondary = c.muted;
    final outline = c.border;

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
            children: [
              TextSpan(
                text: 'Iniciá sesión',
                style: TextStyle(
                  color: c.primary,
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
              const AuthBrandHeader(),
              Text(
                'Crea tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Uníte a la comunidad de chefs más popular',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secondary),
              ),
              const SizedBox(height: 28),
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
                          hint: 'Alfredo',
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
                          hint: 'Gusteau',
                          prefixIcon: Icons.person_outline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const AuthFieldLabel('Correo electrónico'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _emailController,
                hint: 'Chefsito@gmail.com',
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              const AuthFieldLabel('Fecha de nacimiento'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _seleccionarFecha(context),
                child: AbsorbPointer(
                  child: AuthTextField(
                    controller: _fechaController,
                    hint: 'DD/MM/AAAA',
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AuthFieldLabel('Nación'),
                        const SizedBox(height: 8),
                        AuthDropdown(
                          value: _idNacionSeleccionada,
                          hint: 'Elegir',
                          icon: Icons.public,
                          items: _naciones,
                          onChanged: (v) => setState(() => _idNacionSeleccionada = v),
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
                        AuthDropdown(
                          value: _idGeneroSeleccionado,
                          hint: 'Elegir',
                          icon: Icons.people_outline,
                          items: _generos,
                          onChanged: (v) => setState(() => _idGeneroSeleccionado = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const AuthFieldLabel('Nombre de usuario'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _usuarioController,
                hint: 'Remy',
                prefixIcon: Icons.alternate_email,
              ),
              const SizedBox(height: 20),

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

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _acceptTerms,
                      onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                      activeColor: c.primary,
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
                          children: [
                            TextSpan(
                              text: 'Términos de Servicio',
                              style: TextStyle(
                                color: c.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'Política de Privacidad',
                              style: TextStyle(
                                color: c.primary,
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
                AuthErrorBox(_errorMessage!),
                const SizedBox(height: 16),
              ],
              AuthPrimaryButton(
                label: 'Registrarse',
                onTap: _register,
                loading: _isLoading,
              ),
              const AuthDivider(label: 'O REGISTRATE CON'),
              const SizedBox(height: 20),

              GoogleButton(onTap: _registrarConGoogle),
              const SizedBox(height: 20),

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