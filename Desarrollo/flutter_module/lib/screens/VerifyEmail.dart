import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/App.dart';
import '../theme/Notifier.dart';
import '../widgets/AuthDetails.dart';
import '../services/Usuario.dart';
import '../services/Navigation.dart';
import 'Feed.dart';

class VerifyEmailScreen extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final int nacion;
  final int genero;
  final String nombre;
  final String apellido;
  final String email;
  final String usuario;
  final String password;
  final String fechaNacimiento;

  const VerifyEmailScreen({
    super.key,
    required this.themeNotifier,
    required this.nacion,
    required this.genero,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.usuario,
    required this.password,
    required this.fechaNacimiento,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  bool _completando = false;
  StreamSubscription<DeepLinkTarget>? _linkSub;

  static const _resendCooldown = 600;
  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _enviar(isResend: false);
    _linkSub = NavigationService.deepLinks.listen(_onDeepLink);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _startCooldown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _enviar({required bool isResend}) async {
    setState(() => _sending = true);
    try {
      await UsuarioService.solicitarVerificacionCorreo(widget.email);
      if (!mounted) return;
      _startCooldown();
      _snack(isResend
          ? 'Te enviamos un nuevo código.'
          : 'Te enviamos un código y un enlace a tu correo.');
    } catch (_) {
      if (mounted) _snack('No se pudo enviar la verificación. Reintentá.', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onDeepLink(DeepLinkTarget target) {
    if (target.tipo == DeepLinkTipo.verificarCorreo && target.token != null) {
      _verificarPorLink(target.token!);
    }
  }

  Future<void> _verificarPorLink(String token) async {
    if (_completando) return;
    try {
      final ok = await UsuarioService.verificarLinkRegistro(token);
      if (ok) {
        await _completarRegistro();
      } else if (mounted) {
        _snack('El enlace no es válido o venció.', isError: true);
      }
    } catch (_) {
      if (mounted) _snack('No se pudo verificar el enlace.', isError: true);
    }
  }

  Future<void> _confirmarCodigo() async {
    final codigo = _codeController.text.trim();
    if (codigo.length < 6) {
      _snack('Ingresá el código de 6 dígitos.', isError: true);
      return;
    }
    setState(() => _verifying = true);
    try {
      final ok = await UsuarioService.verificarCodigoRegistro(widget.email, codigo);
      if (ok) {
        await _completarRegistro();
      } else if (mounted) {
        _snack('Código inválido o vencido. Probá de nuevo.', isError: true);
      }
    } catch (_) {
      if (mounted) _snack('No se pudo verificar el código.', isError: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _completarRegistro() async {
    if (_completando) return;
    setState(() => _completando = true);
    try {
      final user = await UsuarioService.registrar(
        nacion: widget.nacion,
        genero: widget.genero,
        nombre: widget.nombre,
        apellido: widget.apellido,
        email: widget.email,
        usuario: widget.usuario,
        password: widget.password,
        fechaNacimiento: widget.fechaNacimiento,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => FeedScreen(themeNotifier: widget.themeNotifier, user: user),
        ),
        (route) => false,
      );
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _completando = false);
        final msg = e.code == 'DUPLICADO'
            ? (e.message ?? 'Ese correo o usuario ya está registrado.')
            : 'No se pudo completar el registro. Intentá de nuevo.';
        _snack(msg, isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _completando = false);
        _snack('No se pudo completar el registro.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BocadoColors.of(context);
    final isDark = c.isDark;
    final secondary = c.muted;
    final outline = c.border;
    final ocupado = _verifying || _completando;

    return AuthScaffold(
      themeNotifier: widget.themeNotifier,
      child: Center(
        child: AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verificá tu correo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Te enviamos un código y un enlace a ${widget.email}. '
                'Ingresá el código o tocá el enlace del mail para crear tu cuenta.',
                style: TextStyle(fontSize: 13, color: secondary),
              ),
              const SizedBox(height: 28),

              const AuthFieldLabel('Código de verificación'),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _codeController,
                hint: '000000',
                prefixIcon: Icons.verified_user_outlined,
                maxLength: 6,
                keyboardType: TextInputType.number,
                inputStyle: TextStyle(
                  color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                  fontSize: 18,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _secondsLeft > 0
                    ? Text(
                        'Podés reenviar en ${_fmt(_secondsLeft)}',
                        style: TextStyle(fontSize: 11, color: secondary),
                      )
                    : GestureDetector(
                        onTap: _sending ? null : () => _enviar(isResend: true),
                        child: const Text(
                          'Reenviar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 28),

              AuthPrimaryButton(
                label: ocupado ? 'Verificando...' : 'Verificar y crear cuenta',
                onTap: _confirmarCodigo,
                enabled: !ocupado,
              ),
              const SizedBox(height: 20),

              Divider(color: outline),
              const SizedBox(height: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Volver',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secondary,
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
